<?php

namespace App\Http\Controllers;

use App\Models\ClothingItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class ClothingItemPenaltyController extends Controller
{
    /**
     * Applies penalty when a clothing item is picked and then liked.
     * Logic: (Initial +50 for picked) + (-10 for liked) = Net +40.
     *
     * @param int $clothingItemId The ID of the clothing item.
     * @return \Illuminate\Http\JsonResponse
     */
    public function applyPickedAndLikedPenalty($clothingItemId)
    {
        if (!Auth::check()) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        $clothingItem = ClothingItem::find($clothingItemId);

        if (!$clothingItem) {
            return response()->json(['message' => 'Clothing item not found.'], 404);
        }

        $currentPenalty = $clothingItem->penalty ?? 50; // Default to 50 if null
        // Apply +50 for being picked, then -10 for being liked
        $newPenalty = $this->adjustPenalty($currentPenalty, 50 - 10); // Net change: +40

        return $this->savePenalty($clothingItem, $newPenalty, 'picked and liked');
    }

    /**
     * Applies penalty when a clothing item is picked and then disliked.
     * Logic: (Initial +50 for picked) + (+50 for disliked) = Net +100.
     *
     * @param int $clothingItemId The ID of the clothing item.
     * @return \Illuminate\Http\JsonResponse
     */
    public function applyPickedAndDislikedPenalty($clothingItemId)
    {
        if (!Auth::check()) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        $clothingItem = ClothingItem::find($clothingItemId);

        if (!$clothingItem) {
            return response()->json(['message' => 'Clothing item not found.'], 404);
        }

        $currentPenalty = $clothingItem->penalty ?? 50; // Default to 50 if null
        // Apply +50 for being picked, then +50 for being disliked
        $newPenalty = $this->adjustPenalty($currentPenalty, 50 + 50); // Net change: +100

        return $this->savePenalty($clothingItem, $newPenalty, 'picked and disliked');
    }

    /**
     * Applies penalty when a clothing item is skipped.
     * Logic: -2.
     *
     * @param int $clothingItemId The ID of the clothing item.
     * @return \Illuminate\Http\JsonResponse
     */
    public function applySkippedPenalty($clothingItemId)
    {
        if (!Auth::check()) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        $clothingItem = ClothingItem::find($clothingItemId);

        if (!$clothingItem) {
            return response()->json(['message' => 'Clothing item not found.'], 404);
        }

        $currentPenalty = $clothingItem->penalty ?? 50; // Default to 50 if null
        $newPenalty = $this->adjustPenalty($currentPenalty, -2);   // Net change: -2

        return $this->savePenalty($clothingItem, $newPenalty, 'skipped');
    }

    /**
     * Helper method to save the new penalty to the database within a transaction.
     *
     * @param ClothingItem $clothingItem The clothing item instance.
     * @param int $newPenalty The calculated new penalty value.
     * @param string $interactionType The type of interaction for the message.
     * @return \Illuminate\Http\JsonResponse
     */
    protected function savePenalty(ClothingItem $clothingItem, int $newPenalty, string $interactionType)
    {
        DB::beginTransaction();
        try {
            $clothingItem->penalty = $newPenalty;
            $clothingItem->save();
            DB::commit();

            return response()->json([
                'message' => "Penalty updated successfully for {$interactionType} interaction.",
                'clothing_item' => $clothingItem->fresh() // Get the updated item
            ]);
        } catch (\Exception $e) {
            DB::rollBack();

            // Log server-side only. The exception message can carry table and column names
            // (and sometimes connection details), so it must never reach the client.
            Log::error('Failed to update clothing item penalty.', [
                'clothing_item_id' => $clothingItem->id,
                'interaction_type' => $interactionType,
                'exception' => $e->getMessage(),
            ]);

            return response()->json(['message' => 'Failed to update penalty.'], 500);
        }
    }

    /**
     * Helper method to adjust the penalty and keep it within 0-100.
     *
     * @param int $currentPenalty
     * @param int $change
     * @return int
     */
    protected function adjustPenalty(int $currentPenalty, int $change): int
    {
        $newPenalty = $currentPenalty + $change;

        // Ensure penalty stays within 0 and 100
        if ($newPenalty < 0) {
            return 0;
        }
        if ($newPenalty > 100) {
            return 100;
        }
        return $newPenalty;
    }
}
