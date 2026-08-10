<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ClothingItem extends Model
{
    // protected $table = 'products';
    protected $fillable = [
        'user_id',
        'image_url',
        'category_group',
        'category',
        'color_group',
        'description',
        'sleeve',
        'neckline',
        'fit',
        'length',
        'closure',
        'pattern',
        'material',
        'style',
        'insulation',
        'type',
        'height',
        'toe',
        'coverage',
        'penalty',
        'static_value',
    ];


    protected $casts = [
        'user_id' => 'integer',
        'image_url' => 'string',
        'category_group' => 'string',
        'category' => 'string',
        'color_group' => 'string',
        'sleeve' => 'string',
        'neckline' => 'string',
        'fit' => 'string',
        'length' => 'string',
        'closure' => 'string',
        'pattern' => 'string',
        'material' => 'string',
        'style' => 'string',
        'insulation' => 'string',
        'type' => 'string',
        'height' => 'string',
        'toe' => 'string',
        'penalty' => 'int',
        'static_value' => 'int',
    ];








    public function outfititems()
    {
        return $this->hasMany(OutfitItem::class);
    }


    public function users()
    {
        return $this->belongsTo(User::class);
    }


}
