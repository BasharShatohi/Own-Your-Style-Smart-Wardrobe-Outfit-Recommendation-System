<?php

namespace App\Http\Controllers;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

/**
 * Server-side proxy for OpenWeatherMap current-weather lookups.
 *
 * Exists so the API key never ships inside the Flutter client, where it would be
 * extractable from the APK. Callers authenticate with their existing Bearer token.
 */
class WeatherController extends Controller
{
    private const CACHE_TTL_MINUTES = 10;

    private const TIMEOUT_SECONDS = 10;

    private const CONNECT_TIMEOUT_SECONDS = 5;

    private const MSG_UNAVAILABLE = 'Weather service unavailable';

    private const MSG_NOT_FOUND = 'City not found';

    /**
     * GET /api/weather?city=Damascus&country=SY
     * GET /api/weather?lat=33.51&lon=36.29
     *
     * Success (200) returns exactly these seven keys:
     *
     *   city                 string  may be ''
     *   country              string  ISO-2, may be ''
     *   temperature_celsius  float   1dp, defaults to 0
     *   condition            string  may be '' - see the note below
     *   humidity             int     defaults to 0
     *   wind_speed_mps       float   1dp, defaults to 0
     *   icon_code            string  defaults to '01d'
     *
     * NOTE ON `condition`: it is '' when the upstream payload carries no weather block.
     * '' means UNKNOWN, not "clear". Clients pattern-match this string to pick a weather
     * category and must treat '' as unknown rather than letting it fall through to a
     * default category, otherwise a sparse upstream response silently feeds wrong data
     * downstream. This is part of the contract and is pinned by a test.
     */
    public function show(Request $request): JsonResponse
    {
        $validator = Validator::make($request->query(), [
            'city' => ['required_without_all:lat,lon', 'string', 'max:100'],
            'country' => ['nullable', 'string', 'size:2', 'alpha'],
            'lat' => ['required_without:city', 'required_with:lon', 'numeric', 'between:-90,90'],
            'lon' => ['required_without:city', 'required_with:lat', 'numeric', 'between:-180,180'],
        ], [
            'lat.required_with' => 'The lat field is required when lon is present.',
            'lon.required_with' => 'The lon field is required when lat is present.',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $apiKey = config('services.openweather.key');

        if (blank($apiKey)) {
            // Misconfiguration is ours, not the caller's. Never echo the key or its name.
            Log::error('OpenWeather is not configured: services.openweather.key is empty.');

            return response()->json(['message' => self::MSG_UNAVAILABLE], 503);
        }

        [$cacheKey, $location] = $this->resolveLocation($validator->validated());

        // Cache::remember only writes what the closure RETURNS. fetchWeather() throws on the
        // 404/502 paths, so failures escape before put() runs and are never cached - one
        // upstream blip must not pin "unavailable" for the next ten minutes.
        $payload = Cache::remember(
            $cacheKey,
            now()->addMinutes(self::CACHE_TTL_MINUTES),
            fn (): array => $this->fetchWeather($location, $apiKey)
        );

        return response()->json($payload, 200);
    }

    /**
     * Build the normalised cache key and the upstream query for the requested location.
     * Coordinates win when both forms are supplied.
     *
     * @param  array<string, mixed>  $input
     * @return array{0: string, 1: array<string, string>}
     */
    private function resolveLocation(array $input): array
    {
        if (isset($input['lat'], $input['lon'])) {
            $lat = $this->normaliseCoordinate((float) $input['lat']);
            $lon = $this->normaliseCoordinate((float) $input['lon']);

            return ["weather:geo:{$lat},{$lon}", ['lat' => $lat, 'lon' => $lon]];
        }

        $city = trim((string) $input['city']);
        $country = strtoupper(trim((string) ($input['country'] ?? '')));

        // "Damascus" and "Damascus,SY" are different upstream queries, so they get
        // deliberately distinct cache keys.
        $query = $country === '' ? $city : "{$city},{$country}";
        $cacheKey = 'weather:city:'.Str::lower($city).','.Str::lower($country);

        return [$cacheKey, ['q' => $query]];
    }

    /**
     * Round to 2 decimals and render deterministically ("-0.00" collapses to "0.00").
     */
    private function normaliseCoordinate(float $value): string
    {
        $rounded = round($value, 2);

        return sprintf('%.2f', $rounded == 0.0 ? 0.0 : $rounded);
    }

    /**
     * @param  array<string, string>  $location
     * @return array<string, mixed>
     *
     * @throws HttpResponseException
     */
    private function fetchWeather(array $location, string $apiKey): array
    {
        try {
            $response = Http::acceptJson()
                ->connectTimeout(self::CONNECT_TIMEOUT_SECONDS)
                ->timeout(self::TIMEOUT_SECONDS)
                ->get(config('services.openweather.url'), $location + [
                    'units' => 'metric',
                    'appid' => $apiKey,
                ]);
        } catch (ConnectionException $e) {
            // NEVER log $e->getMessage(): OpenWeather 2.5 authenticates via the `appid` query
            // parameter, and Guzzle embeds the full request URL in cURL error messages.
            Log::warning('OpenWeather request failed to connect.', ['exception' => $e::class]);

            $this->failWith(502, self::MSG_UNAVAILABLE);
        }

        if ($response->status() === 404) {
            $this->failWith(404, self::MSG_NOT_FOUND);
        }

        if (! $response->successful()) {
            // Status only. Upstream bodies (e.g. 401 "Invalid API key") are never logged
            // or returned, for the same reason $response->throw() is avoided here.
            Log::warning('OpenWeather returned an error response.', ['status' => $response->status()]);

            $this->failWith(502, self::MSG_UNAVAILABLE);
        }

        return $this->transform($response->json() ?? []);
    }

    /**
     * Abort out of the Cache::remember closure with an exact JSON response.
     *
     * The framework handler returns HttpResponseException::getResponse() verbatim and does
     * not report it, so the status and body are guaranteed regardless of the caller's
     * Accept header - unlike abort(), which can render HTML.
     */
    private function failWith(int $status, string $message): never
    {
        throw new HttpResponseException(
            response()->json(['message' => $message], $status)
        );
    }

    /**
     * Map an OpenWeather 2.5 current-weather payload onto the flat client contract,
     * with safe defaults for every field.
     *
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    private function transform(array $data): array
    {
        $conditions = $data['weather'][0] ?? [];
        $conditions = is_array($conditions) ? $conditions : [];

        $icon = (string) ($conditions['icon'] ?? '');

        return [
            'city' => (string) ($data['name'] ?? ''),
            'country' => (string) ($data['sys']['country'] ?? ''),
            'temperature_celsius' => round((float) ($data['main']['temp'] ?? 0), 1),
            // '' means unknown - deliberately not defaulted to a real condition.
            'condition' => (string) ($conditions['main'] ?? ''),
            'humidity' => (int) ($data['main']['humidity'] ?? 0),
            'wind_speed_mps' => round((float) ($data['wind']['speed'] ?? 0), 1),
            'icon_code' => $icon !== '' ? $icon : '01d',
        ];
    }
}
