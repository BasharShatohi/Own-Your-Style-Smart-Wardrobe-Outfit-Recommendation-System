<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        $COLOR_GROUPS = [
            "neutrals", "pastels", "brights", "darks", "metallics",
        ];

        $PATTERNS = [
            "solid", "striped", "checked", "plaid", "floral", "polka dots",
            "geometric", "paisley", "animal print", "tie-dye", "camouflage", "ombre",
            "color-block", "jacquard", "houndstooth", "batik", "graphic", "textured",
            "cable knit",
        ];
        
        // Combined users table definition with fields from both migrations
        Schema::create('users', function (Blueprint $table) use ($COLOR_GROUPS, $PATTERNS) {
            $table->id();
            $table->string('first_name');
            $table->string('last_name');
            $table->string('email')->unique();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->rememberToken();
            $table->date('birthday');
            $table->enum('gender', ['male', 'female', 'other']);
            $table->string('avatar_url')->nullable();
            $table->enum('favorite_color_group', $COLOR_GROUPS)->nullable();
            $table->enum('favorite_pattern', $PATTERNS)->nullable();
            $table->timestamps();
        });

        // password_reset_tokens table from the standard migration
        Schema::create('password_reset_tokens', function (Blueprint $table) {
            $table->string('email')->primary();
            $table->string('token');
            $table->timestamp('created_at')->nullable();
        });

        // sessions table from the standard migration
        Schema::create('sessions', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->foreignId('user_id')->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->longText('payload');
            $table->integer('last_activity')->index();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('users');
        Schema::dropIfExists('password_reset_tokens');
        Schema::dropIfExists('sessions');
    }
};