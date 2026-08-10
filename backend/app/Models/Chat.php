<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Chat extends Model
{
    protected $fillable = [
        'user_id',
        'prompt',
        'response',

    ];

    public function users()
    {
        return $this->belongsTo(User::class);
    }
}
