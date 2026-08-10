<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Review extends Model
{
    protected $fillable = [
        'outfit_id',
        'user_id',
        'rating',
        'comment',

    ];

    public function outfits()
    {
        return $this->belongsTo(Outfit::class);
    }



    public function users()
    {
        return $this->belongsTo(User::class);
    }



}
