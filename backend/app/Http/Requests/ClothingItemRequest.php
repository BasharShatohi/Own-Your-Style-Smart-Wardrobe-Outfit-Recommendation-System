<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ClothingItemRequest extends FormRequest
{
    private $COLOR_GROUPS = [
        "neutrals", "pastels", "brights", "darks", "metallics",
    ];

    private $CLIP_PATTERN = [
        "solid", "striped", "checked", "plaid", "floral", "polka dots",
        "geometric", "paisley", "animal print", "tie-dye", "camouflage", "ombre",
        "color-block", "jacquard", "houndstooth", "batik", "graphic", "textured",
        "cable knit",
    ];

    private $CLIP_MATERIAL = [
        "cotton", "linen", "silk", "wool", "leather", "denim", "polyester",
        "nylon", "spandex", "knit", "velvet", "patent leather", "suede",
        "chiffon", "mesh", "canvas", "faux leather", "faux fur", "fleece",
        "quilted", "blend", "cashmere", "rubber", "synthetic", 'water proof'
    ];

    private $FULL_MATERIAL = [
        "cotton", "linen", "silk", "wool", "leather", "denim", "polyester",
        "nylon", "spandex", "knit", "velvet", "patent leather", "suede",
        "chiffon", "mesh", "canvas", "faux leather", "faux fur", "fleece",
        "quilted", "blend", "cashmere", "rubber", 'nylon', "plastic",  "gold", "silver",
        "metal", 'fabric',

    ];

    private $ATTRIBUTES = [
        "Tops" => [
            "sleeve" => ["sleeveless", "short", "long"],
            "neckline" => ["crew", "v-neck", "scoop", "boat", "collared", "turtleneck", "hooded"],
            "fit" => ["slim", "regular", "relaxed", "oversized"],
            "length" => ["crop", "standard", "tunic"],
            "closure" => ["pullover", "zipper", "button", "tie"],
            "pattern" => [],
            "material" => [],
            "color_group" => []
        ],
        "Outerwear" => [
            "sleeve" => ["sleeveless", "short", "long"],
            "style" => ["blazer", "bomber", "parka", "trench", "puffer", "windbreaker"],
            "closure" => ["button", "zipper", "belt", "snap", "toggle"],
            "length" => ["hip", "thigh", "knee", "calf"],
            "insulation" => ["unlined", "light", "medium", "heavy"],
            "pattern" => [],
            "material" => [],
            "color_group" => []
        ],
        "Bottoms" => [
            "fit" => ["skinny", "slim", "regular", "relaxed", "baggy"],
            "type" => ["jeans", "chinos", "slacks", "cargos", "leggings"],
            "closure" => ["button", "zipper", "drawstring", "elastic"],
            "length" => ["short", "capri", "ankle", "full"],
            "pattern" => [],
            "material" => [],
            "color_group" => []
        ],
        "Skirts" => [
            "fit" => ["fitted", "regular", "flowy"],
            "length" => ["mini", "knee", "midi", "maxi"],
            "closure" => ["pullover", "zipper", "button", "tie"],
            "pattern" => [],
            "material" => [],
            "color_group" => []
        ],
        "Dresses & Rompers" => [
            "sleeve" => ["sleeveless", "short", "long"],
            "type" => ["shift", "bodycon", "a-line", "wrap", "shirt"],
            "length" => ["mini", "knee-length", "midi", "maxi"],
            "closure" => ["pullover", "zipper", "button", "tie"],
            "pattern" => [],
            "material" => [],
            "color_group" => []
        ],
        "Footwear" => [
            "type" => ["sneakers", "boots", "sandals", "loafers", "pumps", "flats", "running shoes", "heels", "wedges", "ankle boots", "dress shoes", "rain boots", "oxfords", "moccasins", "flip-flops", "slippers"],
            "closure" => ["lace-up", "slip-on", "buckle", "zipper", "hook-loop"],
            "height" => ["low-top", "mid-top", "high-top"],
            "toe" => ["round toe", "pointed toe", "square toe", "open toe"],
            "pattern" => [],
            "material" => [],
            "color_group" => []
        ],
        "Headwear" => [
            "closure" => ["none", "adjustable strap", "tie"],
            "pattern" => [],
            "material" => ["cotton", "wool", "knit", "denim", "leather", "polyester", "blend", "silk", "plastic"],
            "color_group" => []
        ],
        "Bags" => [
            "closure" => ["zipper", "snap", "magnetic", "drawstring", "buckle", "none"],
            "pattern" => [],
            "material" => ["leather", "canvas", "denim", "polyester", "faux leather", "silk", "plastic", "wool", "knit", "cotton", "linen", "blend", 'nylon'],
            "color_group" => []
        ],
        "Neckwear" => [
            "closure" => ["none", "tie", "clasp"],
            "pattern" => [],
            "material" => ["silk", "cotton", "wool", "polyester", "blend", "gold", "silver", "plastic"],
            "color_group" => []
        ],
        "Earwear" => [
            "closure" => ["piercing", "clip-on", "none"],
            "pattern" => [],
            "material" => ["gold", "silver", "plastic", "metal"],
            "color_group" => []
        ],
        "Wristwear" => [
            "closure" => ["clasp", "buckle", "none"],
            "pattern" => [],
            "material" => ["leather", "metal", "plastic", "fabric", "gold"],
            "color_group" => []
        ],
        "Handwear" => [
            "pattern" => [],
            "material" => ["leather", "wool", "knit", "cotton", "polyester", "blend"],
            "color_group" => []
        ],
        "Eyewear" => [
            "closure" => ["none"],
            "pattern" => [],
            "material" => ["plastic", "metal", "gold"],
            "color_group" => []
        ],
        "Socks & Hosiery" => [
            "closure" => ["none"],
            "pattern" => [],
            "material" => ["cotton", "wool", "nylon", "spandex", "blend"],
            "color_group" => []
        ],
        "Other Accessories" => [
            "closure" => ["buckle", "none"],
            "pattern" => [],
            "material" => ["leather", "metal", "fabric", "plastic"],
            "color_group" => []
        ],
        "Underwear & Swimwear" => [
            "type" => [ "top", "bottom", "fullwear"],
            "fit" => [ "supportive", "padded", "unlined", "brief", "thong"],
            "coverage" => [ "full coverage", "medium coverage", "minimal coverage"],
            "closure" => [ "hook-and-eye", "clasp", "tie", "pull-on"],
            "pattern" => [],
            "material" => ["lace", "satin", "cotton", "nylon", "spandex", "mesh", "blend"],
            "color_group" => []
        ]
    ];

    private $CATEGORY_MAP = [
        "Tops" => [
            "T-shirt", "Polo shirt", "Jersey", "Button-down shirt", "Henley shirt",
            "Tank top", "Knit sweater", "Blouse", "Tunic", "Crop top",
            "Sleeveless top", "Pullover hoodie", "Turtleneck", "Button-up shirt",
            "Dashiki tunic", "Ao dai tunic", "Huipil blouse", "Kente cloth top",
        ],
        "Outerwear" => [
            "Denim jacket", "Leather jacket", "Puffer jacket", "Trench coat",
            "Peacoat", "Blazer", "Windbreaker jacket", "Cardigan sweater",
            "Vest", "Raincoat", "Parka", "Zippered hoodie", "Tracksuit jacket",
            "Coat", "Jacket", "Leather bomber jacket", "Leather coat", "Faux Fur Coat",
            "Kimono robe", "Sherwani coat",
        ],
        "Bottoms" => [
            "Straight-leg jeans", "Skinny jeans", "Bootcut jeans", "Cargo pants",
            "Chino pants", "Dress pants", "Shorts", "Capri pants", "Leggings",
            "Joggers", "Denim shorts", "Sweatpants", "Trousers",
            "Lederhosen pants",
        ],
        "Skirts" => [
            "A-line skirt", "Pencil skirt", "Maxi skirt", "Mini skirt",
            "Pleated skirt", "Wrap skirt", "Denim skirt",
            "Kilt skirt", "Sarong wrap",
        ],
        "Dresses & Rompers" => [
            "Dress", "Strap dress", "Wrap dress", "T-shirt dress", "Maxi dress",
            "Midi dress", "Mini dress", "Cocktail dress", "Evening gown",
            "Sundress", "Shirt dress", "Sweater dress", "Overalls",
            "Jumpsuit", "Romper", "Denim dress",
            "Sari garment", "Hanbok dress", "Dirndl dress", "Cheongsam dress",
            "Boubou robe", "Caftan robe", "Abaya robe",
        ],
        "Footwear" => [
            "Sneakers", "Oxford dress shoes", "Ankle boots", "Knee-high boots",
            "Heel pumps", "Sandals", "Rain boots", "Loafers", "Ballet flats",
            "Wedges", "Espadrilles", "Slippers", "Suede dress shoes", "Dress shoe",
        ],
        "Headwear" => [
            "Baseball cap", "Beanie hat", "Bucket hat", "Sun hat", "Headband",
            "Headscarf", "Hijab head covering", "Beret", "Fedora", "Fez hat",
            "Turban", "Sombrero",
        ],
        "Bags" => [
            "Handbag", "Backpack", "Tote bag", "Clutch bag", "Shoulder bag",
            "Crossbody bag", "Wallet",
        ],
        "Neckwear" => [
            "Neck tie", "Bow tie", "Scarf", "Shawl", "Bandana", "Necklace",
        ],
        "Earwear" => [
            "Earrings", "Over-ear headphones", "Earbuds",
        ],
        "Wristwear" => [
            "Wrist watch", "Bracelet",
        ],
        "Handwear" => [
            "Gloves", "Mittens",
        ],
        "Eyewear" => [
            "Sunglasses", "Eyeglasses",
        ],
        "Socks & Hosiery" => [
            "Knee-high socks", "Ankle socks", "Crew socks", "No-show socks",
            "Dress socks", "Stockings", "Tights",
        ],
        "Other Accessories" => [
            "Belt", "Ring", "Brooch", "Pocket square", "Umbrella",
        ],
        "Underwear & Swimwear" => [
            "Bra", "Panty", "One-piece swimsuit", "Boxers",
        ],
    ];

    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        foreach ($this->ATTRIBUTES as &$attributes) {
            if (empty($attributes['pattern'])) {
                $attributes['pattern'] = $this->CLIP_PATTERN;
            }
            if (empty($attributes['material'])) {
                $attributes['material'] = $this->CLIP_MATERIAL;
            }
            if (empty($attributes['color_group'])) {
                $attributes['color_group'] = $this->COLOR_GROUPS;
            }
        }
        unset($attributes);
        $rules = [
            'category_group' => [
                'required',
                'string',
                Rule::in(array_keys($this->CATEGORY_MAP)),
            ],
            'category' => 'required|string',
            'description' => 'required|string',
            'color_group' => 'required|string',
            'material' => 'nullable|string',
            'pattern' => 'nullable|string',
            'style' => 'nullable|string',
            'fit' => 'nullable|string',
            'length' => 'nullable|string',
            'closure' => 'nullable|string',
            'sleeve' => 'nullable|string',
            'neckline' => 'nullable|string',
            'insulation' => 'nullable|string',
            'type' => 'nullable|string',
            'height' => 'nullable|string',
            'toe' => 'nullable|string',
            'coverage'=> 'nullable|string',
        ];

        if ($this->isMethod('post')) {
            $rules['image'] = 'required|image|mimes:jpg,jpeg,png,webp,gif|max:2048';
        }

        $categoryGroup = $this->input('category_group');

        if (array_key_exists($categoryGroup, $this->CATEGORY_MAP)) {
            $rules['category'] = [
                'required',
                'string',
                Rule::in($this->CATEGORY_MAP[$categoryGroup]),
            ];
        }

        if (array_key_exists($categoryGroup, $this->ATTRIBUTES)) {
            foreach ($this->ATTRIBUTES[$categoryGroup] as $attribute => $values) {
                $rules[$attribute] = ['nullable', Rule::in($values)];
            }
        }

        return $rules;
    }
}