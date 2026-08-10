<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Suggestion extends Model
{
    protected $fillable = [
        'user_id',
        'request',
        'suggested_outfit_id',

    ];


    public function users()
    {
        return $this->belongsTo(User::class);
    }

    public function outfits()
    {
        return $this->belongsTo(Outfit::class);
    }




}
