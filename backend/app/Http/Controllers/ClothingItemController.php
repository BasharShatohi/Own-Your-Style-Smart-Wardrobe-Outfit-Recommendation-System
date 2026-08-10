<?php

namespace App\Http\Controllers;

use App\Models\ClothingItem;
use App\Http\Requests\ClothingItemRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class ClothingItemController extends Controller
{
    public function addClothingItem(ClothingItemRequest $request)
    {

        $validatedData = $request->validated();
        
        $userId = Auth::id();
        if (!$userId) {
            return response()->json([
                'error' => 'Authentication required to view clothing items.'
            ], 401);
        }
        
        $imagePath = $request->file('image')->store("clothing_images/{$userId}", 'private');
        $validatedData['user_id'] = $userId;
        $validatedData['image_url'] = $imagePath;
        $clothingItem = ClothingItem::create($validatedData);

        $attributes = $this->getAttributesForCategoryGroup($clothingItem->category_group);

        $responseData = [
            'id'=>$clothingItem->id,
            'user_id'=>$userId,
            'image_url' => route('clothing-images.show', ['clothingItemId' => $clothingItem->id]),
            'category_group' => $clothingItem->category_group,
            'category' => $clothingItem->category,
            'color_group' => $clothingItem->color_group,
        ];

        foreach ($attributes as $attribute) {
            $responseData[$attribute] = $clothingItem->$attribute;
        }

        return response()->json([
            'message' => 'Clothing item created successfully.',
            'data' => $responseData
        ], 201);
    }

    public function showImage($clothingItemId)
    {
        $clothingItem = ClothingItem::findOrFail($clothingItemId);
        
        if (Auth::id() != $clothingItem->user_id) {
            return response()->json(['error' => 'Unauthorized access'], 403);
        }
        
        $filePath = $clothingItem->image_url;

        if (!Storage::disk('private')->exists($filePath)) {
            return response()->json(['error' => 'Image not found'], 404);
        }

        return Storage::disk('private')->response($filePath);
    }

    public function getMyClothingItems(Request $request)
    {
        $userId = Auth::id();
        
        if (!$userId) {
            return response()->json([
                'error' => 'Authentication required to view clothing items.'
            ], 401);
        }
        
        $clothingItems = ClothingItem::where('user_id', $userId)->get();

        
        $clothingItemsWithDetails = $clothingItems->map(function ($item) {
            $categoryGroup = $item->category_group; 
            $attributes = $this->getAttributesForCategoryGroup($categoryGroup);

            $userId = Auth::id();
            $responseData = [
                'id' => $item->id,
                'user_id'=>$userId,
                'image_url' => route('clothing-images.show', ['clothingItemId' => $item->id]),
                'category_group' => $item->category_group,
                'category' => $item->category,
                'color_group' => $item->color_group,
                'description' => $item->description,
                'penalty' => $item->penalty,
                'static_value' => $item->static_value,
            ];

            
            foreach ($attributes as $attribute) {
                $responseData[$attribute] = $item->$attribute;
            }

            
            return $responseData;
        });

        return response()->json([
            'data' => $clothingItemsWithDetails
        ], 200);
    }

    public function getClothingItemById($itemId)
    {
        $userId = Auth::id();

        $clothingItem = ClothingItem::where('id', $itemId)
                                    ->where('user_id', $userId)
                                    ->first();

        if (!$clothingItem) {
            return response()->json([
                'message' => 'Clothing item not found or does not belong to the authenticated user.'
            ], 404);
        }

        $attributes = $this->getAttributesForCategoryGroup($clothingItem->category_group);

        $responseData = [
            'user_id'=>$userId,
            'image_url' => route('clothing-images.show', ['clothingItemId' => $clothingItem->id]),
            'category_group' => $clothingItem->category_group,
            'category' => $clothingItem->category,
            'color_group' => $clothingItem->color_group,
            'penalty' => $clothingItem->penalty,
            'static_value' => $clothingItem->static_value,
        ];

        foreach ($attributes as $attribute) {
            $responseData[$attribute] = $clothingItem->$attribute;
        }

        return response()->json([
            'data' => $responseData
        ], 200);
    }

    public function deleteClothingItem($itemId)
    {
        $userId = Auth::id();
        if (!$userId) {
            return response()->json([
                'error' => 'Authentication required to view clothing items.'
            ], 401);
        }
        $clothingItem = ClothingItem::where('id', $itemId)
                                    ->first();

        if (!$clothingItem) {
            return response()->json([
                'message' => 'Clothing item not found'
            ], 404);
        }

        $clothingItem = ClothingItem::where('id', $itemId)
                                    ->where('user_id', $userId)
                                    ->first();

        if (!$clothingItem) {
            return response()->json([
                'message' => 'Not Authorized'
            ], 401);
        }
        if ($clothingItem->image_url) {
            Storage::disk('private')->delete($clothingItem->image_url);
        }

        $clothingItem->delete();

        return response()->json([
            'message' => 'Clothing item deleted successfully.'
        ], 200);
    }

    public function updateClothingItem(ClothingItemRequest $request, $itemId)
    {
        $userId = Auth::id();
        if (!$userId) {
            return response()->json([
                'error' => 'Authentication required to view clothing items.'
            ], 401);
        }
        $clothingItem = ClothingItem::where('id', $itemId)
                                    ->first();

        if (!$clothingItem) {
            return response()->json([
                'message' => 'Clothing item not found'
            ], 404);
        }

        $clothingItem = ClothingItem::where('id', $itemId)
                                    ->where('user_id', $userId)
                                    ->first();

        if (!$clothingItem) {
            return response()->json([
                'message' => 'Not Authorized'
            ], 401);
        }

        $validatedData = $request->validated();
        $clothingItem->update($validatedData);

        $attributes = $this->getAttributesForCategoryGroup($clothingItem->category_group);
        
        $responseData = [
            'user_id'=> $clothingItem->user_id,
            'image_url' => route('clothing-images.show', ['clothingItemId' => $clothingItem->id]),
            'category_group' => $clothingItem->category_group,
            'category' => $clothingItem->category,
            'color_group' => $clothingItem->color_group,
            'penalty' => $clothingItem->penalty,
            'static_value' => $clothingItem->static_value,
        ];
        foreach ($attributes as $attribute) {
            $responseData[$attribute] = $clothingItem->$attribute;
        }

        return response()->json([
            'message' => 'Clothing item updated successfully.',
            'data' => $responseData
        ], 203);
    }

    protected function getAttributesForCategoryGroup(string $categoryGroup): array
    {
        $attributesMapping = [
            "Tops" => [
                "sleeve", "neckline", "fit", "length", "closure", "pattern", "material", "color_group"
            ],
            "Outerwear" => [
                "sleeve", "style", "closure", "length", "insulation", "pattern", "material", "color_group"
            ],
            "Bottoms" => [
                "fit", "style", "closure", "length", "pattern", "material", "color_group"
            ],
            "Skirts" => [
                "fit", "length", "closure", "pattern", "material", "color_group"
            ],
            "Dresses & Rompers" => [
                "sleeve", "type", "length", "closure", "pattern", "material", "color_group"
            ],
            "Footwear" => [
                "type", "closure", "height", "toe", "pattern", "material", "color_group"
            ],
            "Headwear" => [
                "closure", "pattern", "material", "color_group"
            ],
            "Bags" => [
                "closure", "pattern", "material", "color_group"
            ],
            "Neckwear" => [
                "closure", "pattern", "material", "color_group"
            ],
            "Earwear" => [
                "closure", "pattern", "material", "color_group"
            ],
            "Wristwear" => [
                "closure", "pattern", "material", "color_group"
            ],
            "Handwear" => [
                "pattern", "material", "color_group"
            ],
            "Eyewear" => [
                "closure", "pattern", "material", "color_group"
            ],
            "Socks & Hosiery" => [
                "closure", "pattern", "material", "color_group"
            ],
            "Other Accessories" => [
                "closure", "pattern", "material", "color_group"
            ]
        ];

        return $attributesMapping[$categoryGroup] ?? [];
    }
}