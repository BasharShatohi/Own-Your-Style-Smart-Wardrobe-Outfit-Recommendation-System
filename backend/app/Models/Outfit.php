<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Outfit extends Model
{
    protected $fillable = [
        'user_id',
        'weather',
        'temperature',
        'occasion',
        'gender',
        'age',
        'items',
        'interaction'
    ];


    protected $casts = [
        'items' => 'array',
        'interaction' => 'string'
    ];

    public function reviews()
    {
        return $this->hasMany(Review::class);
    }

    public function posts()
    {
        return $this->hasMany(Post::class);
    }


    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function clothingItems()
    {
        return $this->belongsToMany(ClothingItem::class, 'outfit_items')
                    ->using(OutfitItem::class)
                    ->withPivot('x', 'y', 'layer')
                    ->withTimestamps();
    }


}
