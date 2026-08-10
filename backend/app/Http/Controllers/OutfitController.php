<?php
namespace App\Http\Controllers;

use App\Models\Outfit;
use App\Models\ClothingItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;


class OutfitController extends Controller
{

    private function hydrateOutfitItems(Outfit $outfit): Outfit
    {
        $itemIds = collect($outfit->items)->pluck('id')->all();
        $clothingItems = ClothingItem::whereIn('id', $itemIds)->get()->keyBy('id');

        $hydratedItems = collect($outfit->items)->map(function ($item) use ($clothingItems) {
            $clothingItemDetails = $clothingItems->get($item['id']);
            if ($clothingItemDetails) {
                return array_merge($clothingItemDetails->toArray(), [
                    'x' => $item['x'] ?? null,
                    'y' => $item['y'] ?? null,
                    'scale' => $item['scale'] ?? null,
                    'rotation' => $item['rotation'] ?? null,
                    'layer' => $item['layer'] ?? null,
                ]);
            }
            return $item;
        })->values();

        $outfit->items = $hydratedItems;

        $outfit->layers = collect($outfit->items)->keyBy('id')->map(function ($item) {
            return $item['layer'];
        });

        return $outfit;
    }

   
    public function index()
    {
        $userId = Auth::id();
        $outfits = Outfit::where('user_id', $userId)->get();

        $hydratedOutfits = $outfits->map(function ($outfit) {
            return $this->hydrateOutfitItems($outfit);
        });
        return response()->json($hydratedOutfits, 200);
    }

    
    public function store(Request $request)
    {

        $userId = Auth::id();
        $validator = Validator::make($request->all(), [
            'weather' => 'nullable|string',
            'temperature' => 'nullable|integer',
            'occasion' => 'nullable|string',
            'gender' => 'nullable|string',
            'age' => 'nullable|integer',
            'items' => 'required|array',
            'items.*.id' => 'required|exists:clothing_items,id',
            'items.*.x' => 'required|numeric',
            'items.*.y' => 'required|numeric',
            'items.*.scale' => 'nullable|numeric',
            'items.*.rotation' => 'nullable|numeric',
            'items.*.layer' => 'nullable|string',
            'interaction' => ['nullable', Rule::in(['liked', 'disliked', 'none'])],
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $outfit = Outfit::create([
            'user_id' => $userId,
            'weather' => $request->weather,
            'temperature' => $request->temperature,
            'occasion' => $request->occasion,
            'gender' => $request->gender,
            'age' => $request->age,
            'items' => $request->items,
            'interaction' => $request->interaction ?? 'none',
        ]);
        $hydratedOutfit = $this->hydrateOutfitItems($outfit);

        return response()->json($hydratedOutfit, 201);

    }

    
    public function show(int $id)
    {
        $userId = Auth::id();

        $outfit = Outfit::where('id', $id)
                                    ->where('user_id', $userId)
                                    ->first();

        if (!$outfit) {
            return response()->json([
                'message' => 'Outfit item not found or does not belong to the authenticated user.'
            ], 404);
        }

        $hydratedOutfit = $this->hydrateOutfitItems($outfit);
        return response()->json($hydratedOutfit, 200);
    }

    
    public function update(Request $request, int $id)
    {
        
        $userId = Auth::id();
        if (!$userId) {
            return response()->json([
                'error' => 'Authentication required to view Outfit.'
            ], 401);
        }
        $outfit = Outfit::where('id', $id)
                                    ->first();

        if (!$outfit) {
            return response()->json([
                'message' => 'Outfit not found'
            ], 404);
        }

        $outfit = Outfit::where('id', $id)
                                    ->where('user_id', $userId)
                                    ->first();

        if (!$outfit) {
            return response()->json([
                'message' => 'Not Authorized'
            ], 401);
        }
        $validator = Validator::make($request->all(), [
            'weather' => 'nullable|string',
            'temperature' => 'nullable|integer',
            'occasion' => 'nullable|string',
            'gender' => 'nullable|string',
            'age' => 'nullable|integer',
            'items' => 'sometimes|array',
            'items.*.id' => 'sometimes|exists:clothing_items,id',
            'items.*.x' => 'sometimes|numeric',
            'items.*.y' => 'sometimes|numeric',
            'items.*.scale' => 'nullable|numeric',
            'items.*.rotation' => 'nullable|numeric',
            'items.*.layer' => 'nullable|string',
            'interaction' => ['nullable', Rule::in(['liked', 'disliked', 'none'])],
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $outfit->update([
            'weather' => $request->input('weather', $outfit->weather),
            'temperature' => $request->input('temperature', $outfit->temperature),
            'occasion' => $request->input('occasion', $outfit->occasion),
            'gender' => $request->input('gender', $outfit->gender),
            'age' => $request->input('age', $outfit->age),
            'items' => $request->input('items', $outfit->items),
            'interaction' => $request->input('interaction', $outfit->interaction),
        ]);
        
        $hydratedOutfit = $this->hydrateOutfitItems($outfit);
        return response()->json($hydratedOutfit, 200);
    }

    
    public function destroy(int $id)
    {
        $userId = Auth::id();
        if (!$userId) {
            return response()->json([
                'error' => 'Authentication required to view Outfit.'
            ], 401);
        }
        $outfit = Outfit::where('id', $id)
                                    ->first();

        if (!$outfit) {
            return response()->json([
                'message' => 'Outfit not found'
            ], 404);
        }

        $outfit = Outfit::where('id', $id)
                                    ->where('user_id', $userId)
                                    ->first();

        if (!$outfit) {
            return response()->json([
                'message' => 'Not Authorized'
            ], 401);
        }
        $outfit->delete();
        
        return response()->json([
            'message' => 'Outfit Deleted successfully.',
        ], 200);
    }

    public function liked()
    {
        $userId = Auth::id();
        $outfits = Outfit::where('user_id', $userId)->where('interaction', 'liked')->get();
        if (!$outfits) {
            return response()->json([
                'message' => 'Outfits not found'
            ], 404);
        }
        $hydratedOutfits = $outfits->map(function ($outfit) {
            return $this->hydrateOutfitItems($outfit);
        });

        return response()->json($hydratedOutfits, 200);
    }

    public function disliked()
    {
        $userId = Auth::id();
        $outfits = Outfit::where('user_id', $userId)->where('interaction', 'disliked')->get();
        if (!$outfits) {
            return response()->json([
                'message' => 'Outfits not found'
            ], 404);
        }
        $hydratedOutfits = $outfits->map(function ($outfit) {
            return $this->hydrateOutfitItems($outfit);
        });

        return response()->json($hydratedOutfits, 200);
    }
}
