<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Post extends Model
{
    protected $fillable = [
        'user_id',
        'image_url',
        'outfit_id',
        'caption',

    ];



    public function postcomments()
    {
        return $this->hasMany(PostComment::class);
    }


    public function users()
    {
        return $this->belongsTo(User::class);
    }




    public function outfits()
    {
        return $this->belongsTo(Outfit::class);
    }




}
