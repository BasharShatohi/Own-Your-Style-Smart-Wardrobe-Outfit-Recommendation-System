<?php

use App\Http\Controllers\OutfitController;
use App\Http\Controllers\PostController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\UserController;
use App\Http\Controllers\ClothingItemController;
use App\Http\Controllers\WeatherController;
use App\Http\Controllers\Auth\EmailVerificationController;


Route::post('/register', [UserController::class, 'registerUser']);
Route::post('/login', [UserController::class, 'loginUser']);
Route::get('/outfits', [OutfitController::class, 'allOutfits']);
Route::middleware('auth:sanctum')->post('/password/change', [UserController::class, 'changePassword']);

Route::get('/hello', function () {
    return response()->json(['message' => 'Hello World']);
});

Route::get('/email/verify/{id}/{hash}', [EmailVerificationController::class, 'verify'])
    ->middleware(['signed','throttle:6,1'])
    ->name('verification.verify');

Route::post('/email/verification-notification', [EmailVerificationController::class, 'resend'])
    ->middleware(['auth:sanctum','throttle:6,1'])
    ->name('verification.send');


Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [UserController::class, 'logoutUser']);
    Route::get('/users', [UserController::class, 'getUserAttributes']);
    Route::patch('/users', [UserController::class, 'updateUserAttributes']);

    Route::get('/weather', [WeatherController::class, 'show'])->middleware('throttle:30,1');

    Route::get('/clothing-images/{clothingItemId}', [ClothingItemController::class, 'showImage'])->name('clothing-images.show');    
    Route::post('/clothingitems', [ClothingItemController::class, 'addClothingItem']);
    Route::get('/my-clothingitems', [ClothingItemController::class, 'getMyClothingItems']);
    Route::get('/clothingitems/{itemId}', [ClothingItemController::class, 'getClothingItemById']);
    Route::delete('/clothingitems/{itemId}', [ClothingItemController::class, 'deleteClothingItem']);
    Route::patch('/clothingitems/{itemId}', [ClothingItemController::class, 'updateClothingItem']);

    Route::post('/createpost', [PostController::class, 'createpost']);
    Route::get('/showmyPosts', [PostController::class, 'showmyPosts']);

    Route::get('/outfits/liked', [OutfitController::class, 'liked']);
    Route::get('/outfits/disliked', [OutfitController::class, 'disliked']);

});

Route::apiResource('/outfits', OutfitController::class)->middleware('auth:sanctum');
