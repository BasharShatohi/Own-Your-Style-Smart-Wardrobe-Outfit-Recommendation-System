<?php

namespace App\Http\Controllers;

use App\Models\Outfit;
use App\Models\Post;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;

class PostController extends Controller
{

    public function createpost(Request $request)
    {
        $request->validate([
            'image' => 'required|image|mimes:jpg,jpeg,png,webp,gif|max:2048',
            'outfit_id' => 'required|exists:outfits,id',
            'caption' => 'nullable|string|max:1000',
        ]);

        // استخراج user id من التوكن
        $userId = Auth::id();

        // تحقق أن الـ outfit تابع لنفس المستخدم
        $ownsOutfit = Outfit::where('id', $request->outfit_id)
            ->where('user_id', $userId)
            ->exists();

        if (! $ownsOutfit) {
            return response()->json([
                'message' => 'you cannot take this outfit',
            ], 403); // Forbidden
        }



        $imagePath = $request->file('image')->store('posts', 'public');

        $post = Post::create([
            'user_id' => $userId,
            'image_url' => Storage::url($imagePath),
            'outfit_id' => $request->outfit_id,
            'caption' => $request->caption,
        ]);

        return response()->json([
            'message' => 'created successfully',
            'post' => $post,
        ], 201);
    }


    public function showmyPosts()
    {
        $userId = Auth::id();

        $posts = Post::where('user_id', $userId)
            ->with('outfits')
            ->latest()
            ->get();

        return response()->json([
            'message' => 'my posts is ',
            'posts' => $posts,
        ]);
    }





}


