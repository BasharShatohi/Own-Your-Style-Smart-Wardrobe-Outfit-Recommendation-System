<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class WeatherEndpointTest extends TestCase
{
    use RefreshDatabase;

    private const API_KEY = 'test-openweather-key-abc123';

    protected function setUp(): void
    {
        parent::setUp();

        config(['services.openweather.key' => self::API_KEY]);

        // Any request not matched by a fake would be a real network call: fail loudly.
        Http::preventStrayRequests();
    }

    private function actingAsUser(): User
    {
        return Sanctum::actingAs(User::factory()->create(), ['*']);
    }

    /**
     * @param  array<string, mixed>  $overrides
     * @return array<string, mixed>
     */
    private function owmPayload(array $overrides = []): array
    {
        return array_replace_recursive([
            'coord' => ['lon' => 36.2765, 'lat' => 33.5102],
            'weather' => [['id' => 804, 'main' => 'Clouds', 'description' => 'overcast clouds', 'icon' => '04d']],
            'main' => ['temp' => 22.54, 'feels_like' => 22.1, 'humidity' => 60, 'pressure' => 1012],
            'wind' => ['speed' => 3.44, 'deg' => 210],
            'sys' => ['country' => 'SY'],
            'name' => 'Damascus',
            'cod' => 200,
        ], $overrides);
    }

    public function test_it_returns_mapped_weather_for_a_city(): void
    {
        Http::fake(['api.openweathermap.org/*' => Http::response($this->owmPayload(), 200)]);
        $this->actingAsUser();

        $response = $this->getJson('/api/weather?city=Damascus&country=SY');

        $response->assertOk()->assertExactJson([
            'city' => 'Damascus',
            'country' => 'SY',
            'temperature_celsius' => 22.5,
            'condition' => 'Clouds',
            'humidity' => 60,
            'wind_speed_mps' => 3.4,
            'icon_code' => '04d',
        ]);

        Http::assertSent(function ($request) {
            parse_str((string) parse_url($request->url(), PHP_URL_QUERY), $query);

            return str_starts_with($request->url(), 'https://api.openweathermap.org/data/2.5/weather')
                && ($query['q'] ?? null) === 'Damascus,SY'
                && ($query['units'] ?? null) === 'metric'
                && ($query['appid'] ?? null) === self::API_KEY;
        });

        $this->assertStringNotContainsString(self::API_KEY, $response->getContent());
    }

    public function test_it_returns_mapped_weather_for_coordinates(): void
    {
        Http::fake(['api.openweathermap.org/*' => Http::response($this->owmPayload(), 200)]);
        $this->actingAsUser();

        $response = $this->getJson('/api/weather?lat=33.5102&lon=36.2765');

        $response->assertOk()->assertJsonPath('city', 'Damascus');

        Http::assertSent(function ($request) {
            parse_str((string) parse_url($request->url(), PHP_URL_QUERY), $query);

            // Coordinates are rounded to 2dp before they are sent and before they are cached.
            return ($query['lat'] ?? null) === '33.51'
                && ($query['lon'] ?? null) === '36.28'
                && ! isset($query['q']);
        });

        $this->assertTrue(Cache::has('weather:geo:33.51,36.28'));
    }

    /**
     * The `condition` contract: '' means UNKNOWN. Clients must not treat it as a real
     * weather category. Locking this in so the default is never "helpfully" changed.
     */
    public function test_it_applies_safe_defaults_for_a_sparse_upstream_payload(): void
    {
        Http::fake(['api.openweathermap.org/*' => Http::response(['name' => 'Nowhere'], 200)]);
        $this->actingAsUser();

        $this->getJson('/api/weather?city=Nowhere')
            ->assertOk()
            ->assertExactJson([
                'city' => 'Nowhere',
                'country' => '',
                'temperature_celsius' => 0.0,
                'condition' => '',
                'humidity' => 0,
                'wind_speed_mps' => 0.0,
                'icon_code' => '01d',
            ]);
    }

    public function test_it_serves_a_second_identical_request_from_cache(): void
    {
        Http::fake(['api.openweathermap.org/*' => Http::response($this->owmPayload(), 200)]);
        $this->actingAsUser();

        $this->getJson('/api/weather?city=Damascus&country=SY')->assertOk();
        // Different casing must normalise onto the same cache key.
        $this->getJson('/api/weather?city=damascus&country=sy')->assertOk();

        Http::assertSentCount(1);
        $this->assertTrue(Cache::has('weather:city:damascus,sy'));
    }

    public function test_it_rejects_a_request_with_neither_city_nor_coordinates(): void
    {
        Http::fake();
        $this->actingAsUser();

        $this->getJson('/api/weather')
            ->assertStatus(422)
            ->assertJsonStructure(['errors' => ['city']]);

        Http::assertNothingSent();
    }

    public function test_it_rejects_lat_without_lon(): void
    {
        Http::fake();
        $this->actingAsUser();

        $this->getJson('/api/weather?lat=33.51')
            ->assertStatus(422)
            ->assertJsonStructure(['errors' => ['lon']]);

        Http::assertNothingSent();
    }

    public function test_it_rejects_out_of_range_coordinates(): void
    {
        Http::fake();
        $this->actingAsUser();

        $this->getJson('/api/weather?lat=120&lon=36.28')
            ->assertStatus(422)
            ->assertJsonStructure(['errors' => ['lat']]);

        Http::assertNothingSent();
    }

    public function test_it_requires_authentication(): void
    {
        Http::fake();

        // No Sanctum::actingAs. auth:sanctum has higher middleware priority than throttle,
        // so an unauthenticated request is 401 and never 429.
        $this->getJson('/api/weather?city=Damascus')->assertUnauthorized();

        Http::assertNothingSent();
    }

    public function test_it_returns_404_when_the_city_is_unknown_and_does_not_cache_it(): void
    {
        Http::fake([
            'api.openweathermap.org/*' => Http::response(['cod' => '404', 'message' => 'city not found'], 404),
        ]);
        $this->actingAsUser();

        $response = $this->getJson('/api/weather?city=Atlantis');

        $response->assertStatus(404)->assertExactJson(['message' => 'City not found']);
        $this->assertFalse(Cache::has('weather:city:atlantis,'));

        // A failure must never be served from cache: the next call hits upstream again.
        $this->getJson('/api/weather?city=Atlantis')->assertStatus(404);
        Http::assertSentCount(2);
    }

    public function test_it_returns_502_when_upstream_errors_and_does_not_cache_it(): void
    {
        Http::fake([
            'api.openweathermap.org/*' => Http::response(['cod' => 401, 'message' => 'Invalid API key'], 401),
        ]);
        $this->actingAsUser();

        $response = $this->getJson('/api/weather?city=Damascus');

        $response->assertStatus(502)->assertExactJson(['message' => 'Weather service unavailable']);
        $this->assertStringNotContainsString('Invalid API key', $response->getContent());
        $this->assertFalse(Cache::has('weather:city:damascus,'));

        $this->getJson('/api/weather?city=Damascus')->assertStatus(502);
        Http::assertSentCount(2);
    }

    public function test_it_returns_502_on_a_connection_timeout_without_leaking_the_key(): void
    {
        // Guzzle puts the full URL (?appid=<key>) inside cURL error messages.
        Http::fake(fn () => throw new ConnectionException(
            'cURL error 28: Operation timed out for https://api.openweathermap.org/data/2.5/weather?q=Damascus&appid='.self::API_KEY
        ));
        $this->actingAsUser();

        $response = $this->getJson('/api/weather?city=Damascus');

        $response->assertStatus(502)->assertExactJson(['message' => 'Weather service unavailable']);
        $this->assertStringNotContainsString(self::API_KEY, $response->getContent());
    }

    public function test_it_returns_503_when_the_api_key_is_not_configured(): void
    {
        config(['services.openweather.key' => null]);
        Http::fake();
        $this->actingAsUser();

        $this->getJson('/api/weather?city=Damascus')
            ->assertStatus(503)
            ->assertExactJson(['message' => 'Weather service unavailable']);

        Http::assertNothingSent();
    }
}
