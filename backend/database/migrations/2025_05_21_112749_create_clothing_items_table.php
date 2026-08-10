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
        Schema::create('clothing_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete()
                ->cascadeOnUpdate();
            $table->string('image_url');            
            $table->string('category_group');
            $table->string('category');
            
            $table->string('color_group');
            $table->text('description');
            $table->string('sleeve')->nullable();
            $table->string('neckline')->nullable();
            $table->string('fit')->nullable();
            $table->string('length')->nullable();
            $table->string('closure')->nullable();
            $table->string('pattern')->nullable();
            $table->string('material')->nullable();
            $table->string('style')->nullable();
            $table->string('insulation')->nullable();
            $table->string('type')->nullable();
            $table->string('height')->nullable();
            $table->string('toe')->nullable();
            $table->string('coverage')->nullable();
            
            $table->integer('static_value')->default(100);
            $table->integer('penalty')->default(0);

            $table->index('user_id');
            $table->index('category_group');
            $table->index('category');
            $table->index('color_group');

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Corrected to drop the 'clothings' table.
        Schema::dropIfExists('clothing_items');
    }
};
