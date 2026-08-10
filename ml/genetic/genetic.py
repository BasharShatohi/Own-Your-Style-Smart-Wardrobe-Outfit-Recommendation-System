import json
import os
import random
import copy
import requests
from datetime import date, datetime
from base_outfits.patched import get_outfits_from_internet
#from show_outfit import download_and_plot_images
import collections
import itertools

OUTFITS_FROM_INTERNET = get_outfits_from_internet()

CATEGORY_LIST_BY_GROUP = {
    "Tops": [
        "T-shirt", "Polo shirt", "Jersey", "Button-down shirt", "Henley shirt",
        "Tank top", "Knit sweater", "Blouse", "Tunic", "Crop top",
        "Sleeveless top", "Pullover hoodie", "Turtleneck",
        "Dashiki tunic", "Ao dai tunic", "Huipil blouse", "Kente cloth top"
    ],
    "Outerwear": [
        "Denim jacket", "Leather jacket", "Puffer jacket", "Trench coat",
        "Peacoat", "Blazer", "Windbreaker jacket", "Cardigan sweater",
        "Vest", "Raincoat", "Parka", "Zippered hoodie", "Tracksuit jacket",
        "Coat", "Jacket", "Leather bomber jacket", "Leather coat", "Faux Fur Coat",
        "Kimono robe", "Sherwani coat"
    ],
    "Bottoms": [
        "Straight-leg jeans", "Skinny jeans", "Bootcut jeans", "Cargo pants",
        "Chino pants", "Dress pants", "Shorts", "Capri pants", "Leggings",
        "Joggers", "Denim shorts", "Sweatpants", "Trousers",
        "Lederhosen pants"
    ],
    "Skirts": [
        "A-line skirt", "Pencil skirt", "Maxi skirt", "Mini skirt",
        "Pleated skirt", "Wrap skirt", "Denim skirt",
        "Kilt skirt", "Sarong wrap"
    ],
    "Dresses & Rompers": [
        "Strap dress", "Wrap dress", "T-shirt dress", "Maxi dress",
        "Midi dress", "Mini dress", "Cocktail dress", "Evening gown",
        "Sundress", "Shirt dress", "Sweater dress", "Overalls",
        "Jumpsuit", "Romper", "Denim dress",
        "Sari garment", "Hanbok dress", "Dirndl dress", "Cheongsam dress",
        "Boubou robe", "Caftan robe", "Abaya robe"
    ],
    "Footwear": [
        "Sneakers", "Oxford dress shoes", "Ankle boots", "Knee-high boots",
        "Heel pumps", "Sandals", "Rain boots", "Loafers", "Ballet flats",
        "Wedges", "Espadrilles", "Slippers", "Suede dress shoes", "Dress shoe" , "Flip-flops"
    ],
    "Headwear": [
        "Baseball cap", "Beanie hat", "Bucket hat", "Sun hat", "Headband",
        "Headscarf", "Hijab head covering", "Beret", "Fedora", "Fez hat",
        "Turban", "Sombrero"
    ],
    "Bags": [
        "Handbag", "Backpack", "Tote bag", "Clutch bag", "Shoulder bag",
        "Crossbody bag", "Wallet"
    ],
    "Neckwear": [
        "Neck tie", "Bow tie", "Scarf", "Shawl", "Bandana", "Necklace"
    ],
    "Earwear": [
        "Earrings", "Over-ear headphones", "Earbuds"
    ],
    "Wristwear": [
        "Wrist watch", "Bracelet"
    ],
    "Handwear": [
        "Gloves", "Mittens"
    ],
    "Eyewear": [
        "Sunglasses", "Eyeglasses"
    ],
    "Socks & Hosiery": [
        "Knee-high socks", "Ankle socks", "Crew socks", "No-show socks",
        "Dress socks", "Stockings", "Tights"
    ],
    "Other Accessories": [
        "Belt", "Ring", "Brooch", "Pocket square", "Umbrella"
    ],
    "Underwear & Swimwear": [
        "Bra", "Panty", "One-piece swimsuit", "Boxers"
    ]
}

CLIP_PATTERN_DESCRIPTIONS = [
    "solid", "striped", "checked", "plaid", "floral", "polka dots",
    "geometric", "paisley", "animal print", "tie-dye", "camouflage", "ombre",
    "color-block", "jacquard", "houndstooth", "batik", "graphic", "textured",
    "cable knit",
]

CLIP_MATERIAL_DESCRIPTIONS = [
    "cotton", "linen", "silk", "wool", "leather", "denim", "polyester",
    "nylon", "spandex", "knit", "velvet", "patent leather", "suede",
    "chiffon", "mesh", "canvas", "faux leather", "faux fur", "fleece",
    "quilted", "blend", "cashmere", "rubber"
]

COLOR_GROUPS = ["neutrals", "pastels", "brights", "darks", "metallics"]

COLOR_GROUPS_MAP = {
    "neutrals": [
        "black", "white", "grey", "gray", "navy", "beige", "taupe", "tan", "brown", "ivory",
        "cream", "off-white", "charcoal", "stone", "khaki"
    ],
    "pastels": [
        "light", "pale", "pastel", "soft", "powder", "mint", "baby", "blush",
        "pastel pink", "pastel blue", "pastel green", "lavender", "peach", "sky blue", "mint green", "lemon", "lilac"
    ],
    "brights": [
        "bright", "yellow", "red", "blue", "green", "orange", "purple", "pink",
        "vibrant", "neon", "electric", "bold", "hot", "true",
        "turquoise", "fuchsia", "lime", "cyan", "magenta"
    ],
    "darks": [
        "dark", "deep", "midnight", "burgundy", "forest", "charcoal", "oxblood", "espresso",
        "dark blue", "dark green", "dark red", "maroon", "olive", "aubergine"
    ],
    "metallics": ["gold", "silver", "bronze", "copper", "metallic", "rose gold"]
}

ATTRIBUTES = {
    "Tops": {
        "sleeve": ["sleeveless", "short", "long"],
        "neckline": ["crew", "v-neck", "scoop", "boat", "collared", "turtleneck"],
        "fit": ["slim", "regular", "relaxed", "oversized"],
        "length": ["crop", "standard", "tunic"],
        "closure": ["pullover", "zipper", "button", "tie"],
        "pattern": CLIP_PATTERN_DESCRIPTIONS,
        "material": CLIP_MATERIAL_DESCRIPTIONS
    },
    "Outerwear": {
        "sleeve": ["sleeveless", "short", "long"],
        "style": ["blazer", "bomber", "parka", "trench", "puffer", "windbreaker"],
        "closure": ["button", "zipper", "belt", "snap", "toggle"],
        "length": ["hip", "thigh", "knee", "calf"],
        "insulation": ["unlined", "light", "medium", "heavy"],
        "pattern": CLIP_PATTERN_DESCRIPTIONS,
        "material": CLIP_MATERIAL_DESCRIPTIONS
    },
    "Bottoms": {
        "fit": ["skinny", "slim", "regular", "relaxed", "baggy", "fitted"],
        "style": ["jeans", "chinos", "slacks", "cargos", "leggings"],
        "closure": ["button", "zipper", "drawstring", "elastic"],
        "length": ["short", "capri", "ankle", "full"],
        "pattern": CLIP_PATTERN_DESCRIPTIONS,
        "material": CLIP_MATERIAL_DESCRIPTIONS
    },
    "Skirts": {
        "fit": ["fitted", "regular", "flowy"],
        "length": ["mini", "knee", "midi", "maxi"],
        "closure": ["pullover", "zipper", "button", "tie"],
        "pattern": CLIP_PATTERN_DESCRIPTIONS,
        "material": CLIP_MATERIAL_DESCRIPTIONS
    },
    "Dresses & Rompers": {
        "sleeve": ["sleeveless", "short", "long"],
        "type": ["shift", "bodycon", "a-line", "wrap", "shirt"],
        "length": ["mini", "knee-length", "midi", "maxi"],
        "closure": ["pullover", "zipper", "button", "tie"],
        "pattern": CLIP_PATTERN_DESCRIPTIONS,
        "material": CLIP_MATERIAL_DESCRIPTIONS
    },
    "Footwear": {
        "style": ["sneakers", "boots", "sandals", "loafers", "pumps", "flats"],
        "closure": ["lace-up", "slip-on", "buckle", "zipper", "hook-loop"],
        "height": ["low-top", "mid-top", "high-top"],
        "toe": ["round toe", "pointed toe", "square toe", "open toe"],
        "pattern": CLIP_PATTERN_DESCRIPTIONS,
        "material": ["leather", "suede", "canvas", "knit", "polyester", "plastic", "blend", "faux leather"]
    },
    "Headwear": {
        "pattern": CLIP_PATTERN_DESCRIPTIONS,
        "material": ["cotton", "wool", "knit", "denim", "leather", "polyester", "blend", "silk", "plastic"]
    },
    "Bags": {
        "closure": ["zipper", "snap", "magnetic", "drawstring", "buckle"],
        "pattern": CLIP_PATTERN_DESCRIPTIONS,
        "material": ["leather", "canvas", "denim", "polyester", "faux leather", "silk", "plastic"]
    },
    "Neckwear": {
        "closure": ["none", "tie", "clasp"],
        "pattern": CLIP_PATTERN_DESCRIPTIONS,
        "material": ["silk", "wool", "knit", "cotton", "linen", "blend", "gold", "silver", "plastic"]
    },
    "Earwear": {
        "closure": ["none", "piercing"],
        "pattern": CLIP_PATTERN_DESCRIPTIONS,
        "material": ["gold", "silver", "plastic", "blend"]
    },
    "Wristwear": {
        "closure": ["clasp", "buckle", "none"],
        "pattern": CLIP_PATTERN_DESCRIPTIONS,
        "material": ["gold", "silver", "leather", "plastic", "knit", "blend"]
    },
    "Handwear": {
        "closure": ["none", "strap", "button", "zipper"],
        "pattern": CLIP_PATTERN_DESCRIPTIONS,
        "material": ["wool", "knit", "leather", "faux leather", "polyester", "spandex", "blend"]
    },
    "Eyewear": {
        "closure": ["none"],
        "pattern": CLIP_PATTERN_DESCRIPTIONS,
        "material": ["plastic", "gold", "silver"]
    },
    "Socks & Hosiery": {
        "closure": ["none"],
        "pattern": CLIP_PATTERN_DESCRIPTIONS,
        "material": ["cotton", "polyester", "spandex", "knit", "blend", "wool"]
    },
    "Other Accessories": {
        "closure": ["buckle", "clasp", "none"],
        "pattern": CLIP_PATTERN_DESCRIPTIONS,
        "material": ["leather", "denim", "gold", "silver", "plastic", "silk", "wool", "cotton", "blend"]
    },
    "Underwear & Swimwear": {
        "type": ["top", "bottom", "fullwear"],
        "fit": ["supportive", "padded", "unlined", "brief", "thong"],
        "coverage": ["full coverage", "medium coverage", "minimal coverage"],
        "closure": ["hook-and-eye", "clasp", "tie", "pull-on"],
        "pattern": CLIP_PATTERN_DESCRIPTIONS,
        "material": ["lace", "satin", "cotton", "nylon", "spandex", "mesh", "blend"],
        "color_group": COLOR_GROUPS
    }
}

# كل مجموعة لازم تسمح بـ color_group، وإلا ClothingItem.__init__ بيرمي اللون
# ونخسر: تفضيل ألوان الحرارة + عقوبة تنافر الألوان + مقارنة اللون بالتشابه.
for _group_attrs in ATTRIBUTES.values():
    _group_attrs.setdefault("color_group", COLOR_GROUPS)

KEYWORD_MAPPING = {
    "T-shirt": {"sleeve": ["short"], "neckline": ["crew", "v-neck"], "fit": ["regular", "relaxed"]},
    "Knit sweater": {"sleeve": ["long"], "material": ["wool", "cotton", "knit", "blend"], "insulation": ["medium", "heavy"]},
    "Rain boots": {"material": ["rubber", "plastic"], "height": ["mid-top", "high-top"], "closure": ["slip-on"], "toe": ["round toe", "square toe"]},
    "Sweatpants": {"fit": ["relaxed", "oversized"], "material": ["cotton", "fleece", "blend"], "closure": ["drawstring", "elastic"]},
    "Slippers": {"material": ["suede", "cotton", "faux fur", "knit"], "closure": ["slip-on"], "height": ["low-top"], "toe": ["round toe", "open toe"]},
    "Button-down shirt": {"closure": ["button"], "neckline": ["collared"]},
    "Jeans": {"material": ["denim"], "closure": ["button", "zipper"]},
    "Leggings": {"fit": ["slim", "fitted"], "material": ["spandex", "blend", "cotton", "nylon", "polyester"], "closure": ["elastic"]},
    "Chino pants": {"material": ["cotton", "blend"], "fit": ["regular", "relaxed"]},
    "Kimono robe": {"material": ["silk", "cotton", "blend"], "style": ["none"], "insulation": ["light", "none"]},
    "Beret": {"closure": ["none"], "material": ["wool", "knit"]},
    "Denim skirt": {"material": ["denim"], "closure": ["button", "zipper"]},
    "Oxford dress shoes": {"closure": ["lace-up"], "height": ["low-top"], "toe": ["round toe", "pointed toe"]},
    "Heel pumps": {"height": ["low-top"], "toe": ["pointed toe", "round toe", "square toe"], "closure": ["slip-on"]},
    "Tunic": {"length": ["tunic"]},
    "Shorts": {"length": ["short"]},
    "Maxi skirt": {"length": ["maxi"]},
    "Maxi dress": {"length": ["maxi"]},
    "Midi dress": {"length": ["midi"]},
    "Mini dress": {"length": ["mini"]},
    "Cocktail dress": {"length": ["mini", "knee"]},
    "Evening gown": {"length": ["maxi"]},
    "Jumpsuit": {"length": ["full"]},
    "Romper": {"length": ["short"]},
    "Sundress": {"sleeve": ["sleeveless", "short"], "material": ["cotton", "linen", "chiffon"]},
    "Leather jacket": {"material": ["leather", "faux leather"], "style": ["bomber", "blazer", "trench"]},
    "Scarf": {"material": ["silk", "wool", "cotton", "polyester", "blend"]},
    "Straight-leg jeans": {"material": ["denim"], "closure": ["button", "zipper"], "fit": ["regular"]},
    "Skinny jeans": {"material": ["denim"], "closure": ["button", "zipper"], "fit": ["skinny", "slim"]},
    "Bootcut jeans": {"material": ["denim"], "closure": ["button", "zipper"], "fit": ["regular", "relaxed"]},
    "Dress shirt": {"closure": ["button"], "neckline": ["collared"]}
}

OUTFIT_STRUCTURE_RULES = [
    {"Tops", "Bottoms", "Footwear"},
    {"Tops", "Skirts", "Footwear"},
    {"Dresses & Rompers", "Footwear"},
]

AGE_GROUP = [
    "children",
    "teenage",
    "young-adult",
    "adult",
    "middle-aged-adult",
    "senior"
]

TEMP_RANGES = {
    "extreme_cold": (-40, -10),
    "cold": (-9, 0),
    "cool": (1, 10),
    "mild": (11, 20),
    "warm": (21, 30),
    "hot": (31, 40),
    "extreme_hot": (41, 70)
}

weathers = ["clear", "snowy", "cloudy", "rainy"]
occasions = ["casual", "formal", "sport", "party", "wedding", "beachwear", "lounge-homewear"]

BASE_OUTFITS = []

Top_Layer = {
    "T-shirt": ["Pullover hoodie", "Knit sweater", "Button-down shirt", "Jersey"],
    "Polo shirt": ["Knit sweater", "Pullover hoodie", "Button-down shirt"],
    "Jersey": ["Pullover hoodie", "Button-down shirt"],
    "Button-down shirt": ["Knit sweater", "Pullover hoodie"],
    "Henley shirt": ["Pullover hoodie", "Knit sweater"],
    "Tank top": ["T-shirt", "Polo shirt", "Jersey", "Button-down shirt", "Henley shirt", "Pullover hoodie", "Knit sweater", "Blouse", "Tunic", "Sleeveless top", "Turtleneck", "Dashiki tunic", "Ao dai tunic", "Huipil blouse", "Kente cloth top"],
    "Knit sweater": ["Pullover hoodie"],
    "Blouse": ["Knit sweater"],
    "Tunic": [],
    "Crop top": ["Pullover hoodie", "Knit sweater", "Button-down shirt", "Blouse"],
    "Sleeveless top": ["T-shirt", "Button-down shirt", "Pullover hoodie", "Knit sweater"],
    "Pullover hoodie": [],
    "Turtleneck": ["Knit sweater"],
    "Dashiki tunic": [],
    "Ao dai tunic": [],
    "Huipil blouse": [],
    "Kente cloth top": ["Pullover hoodie", "Knit sweater"],
}

Outer_Layer = {
    "Denim jacket": ["Puffer jacket", "Parka", "Coat", "Jacket", "Faux Fur Coat"],
    "Leather jacket": ["Puffer jacket", "Parka", "Coat", "Jacket", "Faux Fur Coat"],
    "Puffer jacket": ["Parka"],
    "Trench coat": ["Puffer jacket", "Parka", "Coat"],
    "Peacoat": ["Parka", "Puffer jacket", "Coat"],
    "Blazer": ["Denim jacket", "Leather jacket", "Puffer jacket", "Trench coat", "Peacoat", "Windbreaker jacket", "Raincoat", "Parka", "Coat"],
    "Windbreaker jacket": ["Puffer jacket", "Parka", "Coat"],
    "Cardigan sweater": ["Denim jacket", "Leather jacket", "Blazer", "Puffer jacket", "Trench coat", "Peacoat", "Windbreaker jacket", "Raincoat", "Parka", "Zippered hoodie", "Tracksuit jacket", "Coat", "Jacket", "Leather bomber jacket", "Leather coat", "Faux Fur Coat", "Kimono robe", "Sherwani coat"],
    "Vest": ["Denim jacket", "Leather jacket", "Blazer", "Puffer jacket", "Trench coat", "Peacoat", "Windbreaker jacket", "Raincoat", "Parka", "Zippered hoodie", "Tracksuit jacket", "Coat", "Jacket", "Leather bomber jacket", "Leather coat", "Faux Fur Coat"],
    "Raincoat": ["Puffer jacket", "Parka", "Coat"],
    "Parka": [],
    "Zippered hoodie": ["Denim jacket", "Leather jacket", "Puffer jacket", "Trench coat", "Peacoat", "Windbreaker jacket", "Raincoat", "Parka", "Coat"],
    "Tracksuit jacket": ["Puffer jacket", "Parka", "Raincoat", "Coat"],
    "Coat": ["Parka", "Puffer jacket"],
    "Jacket": ["Puffer jacket", "Parka", "Coat"],
    "Leather bomber jacket": ["Puffer jacket", "Parka", "Coat"],
    "Leather coat": ["Puffer jacket", "Parka", "Coat"],
    "Faux Fur Coat": ["Parka"],
    "Kimono robe": ["Puffer jacket", "Parka", "Coat"],
    "Sherwani coat": ["Puffer jacket", "Parka", "Coat"],
}

# =========================
# Utilities
# =========================
def get_age_group(age):
    if age is None:
        return "unknown"
    if age >= 65: return "senior"
    if age >= 50: return "middle-aged-adult"
    if age >= 25: return "adult"
    if age >= 18: return "young-adult"
    if age >= 13: return "teenage"
    if age >= 0: return "children"
    return "unknown"

def get_temperature_range_label(temp):
    if temp >= 41: return "extreme_hot"
    if temp >= 31: return "hot"
    if temp >= 21: return "warm"
    if temp >= 11: return "mild"
    if temp >= 1: return "cool"
    if temp >= -9: return "cold"
    if temp >= -40: return "extreme_cold"
    return "unknown"

class ClothingItem:
    def __init__(self, id=None, user_id=None, image_url=None, category_group=None,
                 category=None, color_group=None, sleeve=None, neckline=None,
                 fit=None, length=None, closure=None, pattern=None,
                 material=None, style=None, insulation=None, category_type=None,
                 height=None, toe=None, penalty=0, static_value=100):
        self.id = id
        self.user_id = user_id
        self.image_url = image_url
        self.category_group = category_group
        self.category = category
        self.wardrobe_static_value = static_value
        self.wardrobe_penalty = penalty
        self.current_wardrobe_value = static_value - penalty
        self.environmental_scores = {}
        self.attributes = {}
        potential_attributes = {
            "color_group": color_group,
            "sleeve": sleeve,
            "neckline": neckline,
            "fit": fit,
            "length": length,
            "closure": closure,
            "pattern": pattern,
            "material": material,
            "style": style,
            "insulation": insulation,
            "type": category_type,
            "height": height,
            "toe": toe,
        }
        if self.category_group in ATTRIBUTES:
            allowed_attrs_for_group = ATTRIBUTES[self.category_group].keys()
            for attr_name, attr_value in potential_attributes.items():
                if attr_value is not None and attr_name in allowed_attrs_for_group:
                    self.attributes[attr_name] = attr_value

        if self.category in KEYWORD_MAPPING:
            for attr, values in KEYWORD_MAPPING[self.category].items():
                if self.category_group in ATTRIBUTES and attr in ATTRIBUTES[self.category_group]:
                    if attr not in self.attributes or self.attributes[attr] not in values:
                        self.attributes[attr] = random.choice(values)

    def __repr__(self):
        return str(self.id)

    def to_string(self):
        parts = []
        if self.id is not None:
            parts.append(f"Item ID: {self.id}")
        if self.user_id is not None:
            parts.append(f"User ID: {self.user_id}")
        if self.category_group is not None:
            parts.append(f"Category Group: {self.category_group}")
        if self.category is not None:
            parts.append(f"Category: {self.category}")
        if self.image_url is not None:
            parts.append(f"Image URL: {self.image_url}")

        ordered_attrs = [
            "color_group", "sleeve", "neckline", "fit", "length", "closure",
            "pattern", "material", "style", "insulation", "type", "height", "toe"
        ]
        for attr_name in ordered_attrs:
            attr_value = self.get_attribute(attr_name)
            if attr_value is not None:
                display_name = "Item Type Attribute" if attr_name == "type" else attr_name.replace('_', ' ').title()
                parts.append(f"{display_name}: {attr_value}")

        return ", ".join(parts)

    def get_attribute(self, attr_name):
        return self.attributes.get(attr_name)

    def get(self, name):
        if hasattr(self, name):
            return getattr(self, name)
        return self.attributes.get(name)

class Outfit:
    def __init__(self, items=None, layers=None, score_value=None):
        self.items = items if items is not None else []
        self.fitness = 0
        self.layers = layers if layers is not None else {}
        self.score_value = score_value

    def __repr__(self):
        item_strings = []
        for item in self.items:
            if item.id in self.layers and self.layers[item.id] is not None:
                item_strings.append(f"{item.to_string()} ({self.layers[item.id]})")
            else:
                item_strings.append(item.to_string())
        return f"Outfit Fitness: {self.fitness:.2f}\n" + "\n".join(item_strings)

    def add_item(self, item, layer=None):
        self.items.append(item)
        self.layers[item.id] = layer

    def get_categories_group(self, category_group):
        return [item for item in self.items if item.category_group == category_group]

    def get_categories(self):
        return {item.category_group for item in self.items}

    def get_category_categories(self):
        return {item.category for item in self.items}

    def get_items_by_category_group(self, category_group):
        return [item for item in self.items if item.category_group == category_group]

    def get_items_by_category(self, category):
        return [item for item in self.items if item.category == category]

    def remove_item(self, item):
        self.items.remove(item)
        if item.id in self.layers:
            del self.layers[item.id]

    def validate_undergarments(self):
        undergarment_items = self.get_items_by_category_group("Underwear & Swimwear")
        categories = {item.category for item in undergarment_items}

        if len(categories) > 2:
            return False
        if "One-piece swimsuit" in categories and ({"Bra", "Panty"}.issubset(categories) or "Boxers" in categories):
            return False
        if "Boxers" in categories and ({"Bra", "Panty"}.issubset(categories) or "One-piece swimsuit" in categories):
            return False

        return True

import copy
import random

def sanitize_outfit(outfit, user_inputs):
    """
    Ensure the outfit is logically consistent and apply guardrails:
    - remove duplicate categories (keep first)
    - footwear: one item only
    - dress exclusivity: if dress present -> remove bottoms/skirts and non-outer tops
    - avoid mixing skirts + bottoms (prefer skirts when both present)
    - allow up to two tops (inner + outer)
    - outerwear: one only
    - accessories: one per accessory group; other-accessories max 2 (no duplicate category)
    - validate underwear/swimwear rules
    - ties only with formal shirt
    - formal/wedding guardrails (no shorts/jeans, enforce formal footwear)
    """
    def group(it): return getattr(it, "category_group", None)
    def cat(it):   return getattr(it, "category", None)

    # --- remove duplicates by category (keep first) ---
    seen_cats = set()
    unique_items = []
    for it in outfit.items:
        c = cat(it)
        if c and c not in seen_cats:
            unique_items.append(it)
            seen_cats.add(c)
    outfit.items = unique_items

    # helper: get layer flag from outfit.layers (handles int or str keys)
    def layer_flag_for(item):
        if item is None:
            return None
        lid = getattr(item, "id", None)
        if lid is None:
            return None
        # try int key first, then string key
        if lid in outfit.layers:
            return outfit.layers.get(lid)
        s = str(lid)
        return outfit.layers.get(s)

    def items_in_group(g):
        return [it for it in outfit.items if (group(it) or "").strip().lower() == g.strip().lower()]

    # Footwear: keep only the first one
    shoes = items_in_group("Footwear")
    for it in list(shoes[1:]):
        outfit.remove_item(it)

    # Collect category-group lists
    dresses = items_in_group("Dresses & Rompers")
    bottoms = items_in_group("Bottoms")
    skirts  = items_in_group("Skirts")
    tops    = items_in_group("Tops")

    # If there is at least one dress -> remove bottoms & skirts
    if dresses:
        # ملاحظة: ما منشيل الـ tops هون. كانوا ينحذفوا مرتين فيرمي ValueError،
        # وكمان كان يمنع لبس بلايزر/كارديغان فوق الفستان.
        for it in list(bottoms) + list(skirts):
            outfit.remove_item(it)

        # Remove Tops (e.g., blouse, button-down, crop top) unless the top is intentionally used as 'outer'
        for it in list(tops):
            lf = layer_flag_for(it)
            # keep top only if specifically set to outer (acts as jacket/overshirt)
            if lf == "outer":
                continue
            outfit.remove_item(it)
        # after this, tops list will be empty or contain only outer top(s)
    else:
        # No dress: avoid mixing skirts+bottoms. Prefer skirts (keep skirts, remove bottoms).
        if skirts and bottoms:
            for it in list(bottoms):
                outfit.remove_item(it)

        # Ensure at most one Bottoms and at most one Skirt
        skirts = items_in_group("Skirts")
        if len(skirts) > 1:
            for it in skirts[1:]:
                outfit.remove_item(it)
        bottoms = items_in_group("Bottoms")
        if len(bottoms) > 1:
            for it in bottoms[1:]:
                outfit.remove_item(it)

    # TOPS: allow up to 2 tops (inner + outer). Keep earliest items as inner then outer
    tops = items_in_group("Tops")
    if tops:
        # keep first as inner by default
        keep = tops[0]
        outfit.layers[keep.id] = outfit.layers.get(keep.id, "inner")
        # if there's a second top, mark it outer
        if len(tops) > 1:
            second = tops[1]
            outfit.layers[second.id] = outfit.layers.get(second.id, "outer")
            # remove any additional tops beyond 2
            for it in tops[2:]:
                outfit.remove_item(it)

    # Outerwear: one only
    outers = items_in_group("Outerwear")
    if len(outers) > 1:
        for it in outers[1:]:
            outfit.remove_item(it)
    for it in items_in_group("Outerwear"):
        outfit.layers[it.id] = "outer"

    # Accessories: one per accessory group
    ONE_EACH = ["Headwear","Bags","Neckwear","Earwear","Wristwear","Handwear","Eyewear"]
    for g in ONE_EACH:
        arr = items_in_group(g)
        if len(arr) > 1:
            for it in arr[1:]:
                outfit.remove_item(it)

    # Other Accessories: at most 2 and no duplicate categories
    others = items_in_group("Other Accessories")
    if others:
        seen = set()
        cleaned = []
        for it in others:
            name = (cat(it) or "").strip().lower()
            if name and name not in seen:
                cleaned.append(it)
                seen.add(name)
        if len(cleaned) > 2:
            cleaned = cleaned[:2]
        for it in list(others):
            outfit.remove_item(it)
        for it in cleaned:
            outfit.add_item(it, layer="accessory")

    # Underwear & Swimwear validation
    if not outfit.validate_undergarments():
        under = items_in_group("Underwear & Swimwear")
        cats = {cat(it) for it in under}
        if "One-piece swimsuit" in cats:
            for it in list(under):
                if cat(it) in {"Bra","Panty","Boxers"}:
                    outfit.remove_item(it)
        elif {"Bra","Panty"} & cats and "Boxers" in cats:
            for it in list(under):
                if cat(it) == "Boxers":
                    outfit.remove_item(it)

    # Rebuild accessory layers
    for it in list(outfit.items):
        if (group(it) or "").strip().lower() in {"eyewear","other accessories","neckwear","handwear","wristwear","headwear","bags"}:
            outfit.layers[it.id] = "accessory"

    # Ties only with formal shirt
    def is_formal_shirt_name(n):
        return (n or "").strip().lower() in {"button-down shirt","dress shirt"}
    has_formal_shirt = any((group(x) or "").strip().lower()=="tops" and is_formal_shirt_name(cat(x)) for x in outfit.items)
    if not has_formal_shirt:
        for it in list(outfit.items):
            if (group(it) or "").strip().lower() == "neckwear" and (cat(it) in {"Neck tie","Bow tie"}):
                outfit.remove_item(it)

    # Clean up layers for removed items (normalize keys to the type used elsewhere)
    existing_ids = {it.id for it in outfit.items}
    for k in list(outfit.layers.keys()):
        # compare both string and int forms
        if (k not in existing_ids) and (str(k) not in {str(x) for x in existing_ids}):
            outfit.layers.pop(k, None)

    # ===== Occasion guardrails =====
    occ = (user_inputs.get('occasion') or '').strip().lower()
    gen = (user_inputs.get('gender') or '').strip().lower()

    if occ in ('formal','wedding'):
        # remove shorts/jeans/denim
        for it in list(outfit.items):
            n = (it.category or '').lower()
            if n in {'shorts','denim shorts','jeans','straight-leg jeans','skinny jeans','bootcut jeans'}:
                outfit.remove_item(it)

        # keep only formal footwear; otherwise remove
        for it in list(outfit.items):
            if (it.category_group or '').lower() == 'footwear':
                n = (it.category or '').lower()
                if gen == 'female':
                    ok = (n == 'heel pumps')
                else:
                    ok = (n in {'oxford dress shoes','dress shoe'})
                if not ok:
                    outfit.remove_item(it)

    return outfit

def _get_color_group(color):
    for group, colors in COLOR_GROUPS_MAP.items():
        if color in colors:
            return group
    return None

def _dict_to_outfit(outfit_dict):
    clothing_items = []
    counter = 1
    layers = {}
    for item_dict in outfit_dict['items']:
        item = ClothingItem(
            id=counter,
            category_group=item_dict.get("category_group"),
            category=item_dict.get("category"),
            color_group=_get_color_group(item_dict.get("color")),
            sleeve=item_dict.get("sleeve"),
            neckline=item_dict.get("neckline"),
            fit=item_dict.get("fit"),
            length=item_dict.get("length"),
            closure=item_dict.get("closure"),
            pattern=item_dict.get("pattern"),
            material=item_dict.get("material"),
            style=item_dict.get("style"),
            insulation=item_dict.get("insulation"),
            category_type=item_dict.get("type"),
            height=item_dict.get("height"),
            toe=item_dict.get("toe"),
        )
        layer = item_dict.get('layer')
        layers[item.id] = layer
        counter += 1
        clothing_items.append(item)
    return Outfit(clothing_items, layers, outfit_dict['score_value'])

def _calculate_similarity(outfit1, outfit2, base_score):
    similarity_score = 0

    items1 = outfit1.items
    items2 = outfit2.items
    category_groups1 = {item.category_group for item in items1}
    category_groups2 = {item.category_group for item in items2}

    common_category_groups = category_groups1.intersection(category_groups2)
    num_common_category_groups = len(common_category_groups)

    if len(items2) > 0:
        similarity_score += (num_common_category_groups / len(items2)) * 75

    common_items_count = 0
    common_color_groups_count = 0
    common_materials_count = 0
    common_patterns_count = 0
    other_attributes_score = 0
    layer_score = 0
    for item1 in items1:
        for item2 in items2:
            if item1.category_group == item2.category_group:
                if item1.category == item2.category:
                    common_items_count += 1
                    if item1.id in outfit1.layers and item2.id in outfit2.layers and \
                          outfit1.layers[item1.id] == outfit2.layers[item2.id]:
                        layer_score += 1

                if item1.get_attribute('color_group') == item2.get_attribute('color_group'):
                    common_color_groups_count += 1
                if item1.get_attribute("material") == item2.get_attribute("material"):
                    common_materials_count += 1
                if item1.get_attribute("pattern") == item2.get_attribute("pattern"):
                    common_patterns_count += 1

                other_attributes_count = 0
                attributes1 = set(item1.attributes) - {"category_group", "category", "color", "color_group",  "material", "pattern"}
                attributes2 = set(item2.attributes) - {"category_group", "category", "color", "color_group", "material", "pattern"}

                for attr in attributes1:
                    if attr in attributes2 and item1.get_attribute(attr) == item2.get_attribute(attr):
                        other_attributes_count += 1

                if len(attributes1.union(attributes2)) > 0:
                    other_attributes_score += other_attributes_count / len(attributes1.union(attributes2))

    if len(items2) > 0:
        similarity_score += (common_items_count / len(items2)) * 125
        similarity_score += (common_color_groups_count / len(items2)) * 60
        similarity_score += (common_materials_count / len(items2)) * 20
        similarity_score += (common_patterns_count / len(items2)) * 30
        similarity_score += (other_attributes_score / len(items2)) * 40
        similarity_score += (layer_score) * 10

    final_score = (similarity_score * base_score) / 100
    return final_score

def _find_similar_outfit(matching_outfits, occasion, weather, temperature, age_group, gender, current_outfit):
    if not matching_outfits:
        return None, 0
    best_match = None
    max_score = -1

    for outfit in matching_outfits:
        score = _calculate_similarity(current_outfit, outfit, outfit.score_value)
        if score > max_score:
            max_score = score
            best_match = outfit

    return best_match, max_score

def _calculate_outfit_weight(outfit):
    MAIN_CATEGORIES = {"Tops": 1, "Outerwear": 2, "Bottoms": 1, "Skirts": 1, "Dresses & Rompers": 1, "Footwear": 1}
    score = 0
    has_top = False
    has_dress = False
    for item in outfit.items:
        if item.category_group == 'Tops':
            has_top = True
        if item.category_group == 'Dresses & Rompers':
            has_dress = True
        if item.category_group in MAIN_CATEGORIES.keys():
            score += MAIN_CATEGORIES[item.category_group]
    if has_dress and has_top:
        score += 10

    return score

def rate_outfit_items(outfit_items, weather, occasion, temperature, age_group, gender):
    """
    Scorer مع تعزيز قوي للمناسبة (occasion) + تضخيم للأحكام الرسمية.
    """
    def norm(v):
        return (str(v) if v is not None else "").strip().lower()

    def to_temp_band(t):
        if isinstance(t, (int, float)):
            if t <= -5:   return "extreme_cold"
            if t <= 8:    return "cold"
            if t <= 15:   return "cool"
            if t <= 22:   return "mild"
            if t <= 28:   return "warm"
            if t <= 35:   return "hot"
            return "extreme_hot"
        return norm(t)

    def has_attr(item, key, values):
        v = norm(item.get(key))
        return v in [norm(x) for x in values]

    def name_is(item, values):
        return norm(item.get("category")) in [norm(x) for x in values]

    def group_is(item, values):
        return norm(item.get("category_group")) in [norm(x) for x in values]

    OCCASION_CORE = {
        "casual": {
            "groups": ["Tops","Bottoms","Footwear","Outerwear","Headwear","Bags","Eyewear"],
            "categories": ["T-shirt","Jeans","Sneakers","Pullover hoodie","Windbreaker jacket","Baseball cap"],
        },
        "formal": {
            "groups": ["Tops","Bottoms","Outerwear","Footwear","Neckwear","Skirts","Dresses & Rompers","Bags","Eyewear"],
            "categories": ["Button-down shirt","Dress shirt","Blazer","Dress pants","Oxford dress shoes","Neck tie","Bow tie","Evening gown","Cocktail dress","Pencil skirt","Trench coat","Heel pumps"],
        },
        "wedding": {
            "groups": ["Tops","Bottoms","Outerwear","Footwear","Neckwear","Dresses & Rompers","Skirts","Bags","Eyewear"],
            "categories": ["Evening gown","Cocktail dress","Heel pumps","Button-down shirt","Blazer","Dress pants","Oxford dress shoes","Pencil skirt","Trench coat"],
        },
        "sport": {
            "groups": ["Tops","Bottoms","Footwear","Headwear","Bags"],
            "categories": ["Jersey","T-shirt","Shorts","Joggers","Sneakers","Headband","Backpack","Crew socks"],
        },
        "party": {
            "groups": ["Tops","Skirts","Dresses & Rompers","Footwear","Other Accessories","Bags","Eyewear"],
            "categories": ["Blouse","Crop top","Mini skirt","Cocktail dress","Evening gown","Heel pumps","Clutch bag","Sunglasses"],
        },
        "beachwear": {
            "groups": ["Underwear & Swimwear","Tops","Bottoms","Footwear","Headwear","Eyewear","Bags"],
            "categories": ["One-piece swimsuit","Shorts","Tank top","Sandals","Flip-flops","Sun hat","Sunglasses","Tote bag"],
        },
        "lounge-homewear": {
            "groups": ["Tops","Bottoms","Footwear","Wristwear"],
            "categories": ["Pullover hoodie","Sweatpants","Joggers","Slippers","T-shirt"],
        },
        "smart_casual": {
            "groups": ["Tops","Bottoms","Footwear","Outerwear","Bags","Eyewear"],
            "categories": ["Button-down shirt","Dress shirt","Blazer","Chino pants","Loafers","Sneakers"]
        },
    }

    TEMP_MATERIALS = {
        "extreme_cold": ["wool","fleece","cashmere","down","leather","quilted","suede"],
        "cold":         ["wool","fleece","cashmere","leather","denim"],
        "cool":         ["denim","cotton","knit","polyester"],
        "mild":         ["cotton","linen","polyester","blend"],
        "warm":         ["linen","cotton","chiffon","mesh"],
        "hot":          ["linen","cotton","mesh","chiffon"],
        "extreme_hot":  ["linen","cotton","mesh","chiffon"],
    }
    TEMP_COVERAGE = {
        "extreme_cold": {"sleeve":["long"],"insulation":["heavy"],"length":["knee","calf","thigh"]},
        "cold":         {"sleeve":["long"],"insulation":["medium","heavy"],"length":["hip","thigh"]},
        "cool":         {"sleeve":["long","short"],"insulation":["light"],"length":["hip","thigh"]},
        "mild":         {"sleeve":["short","sleeveless"],"insulation":["unlined","light"],"length":["hip","standard"]},
        "warm":         {"sleeve":["short","sleeveless"],"insulation":["unlined"],"length":["short","standard"]},
        "hot":          {"sleeve":["sleeveless"],"insulation":["unlined"],"length":["short","crop","standard"]},
        "extreme_hot":  {"sleeve":["sleeveless"],"insulation":["unlined"],"length":["short","crop"]},
    }

    WEATHER_RULES = {
        "rainy": {"categories":["Raincoat","Rain boots","Umbrella","Trench coat","Windbreaker jacket"], "materials":["nylon","polyester","rubber","faux leather"], "groups":["Outerwear","Footwear","Other Accessories"]},
        "snowy": {"categories":["Parka","Puffer jacket","Beanie hat","Gloves","Knee-high boots","Ankle boots"], "materials":["wool","fleece","down","leather","suede","quilted"], "groups":["Outerwear","Headwear","Handwear","Footwear"]},
        "clear": {"categories":["Sun hat","Sunglasses"], "materials":[], "groups":["Headwear","Eyewear"]},
        "cloudy":{"categories":["Windbreaker jacket","Cardigan sweater","Denim jacket"], "materials":["denim","knit","polyester"], "groups":["Outerwear"]},
    }

    COLOR_PREFS = {
        "extreme_cold": ["darks","neutrals"], "cold":["darks","neutrals"], "cool":["neutrals"],
        "mild":["neutrals","pastels"], "warm":["pastels","brights"], "hot":["pastels","brights","neutrals"], "extreme_hot":["pastels","brights"],
    }

    AGE_HINTS = {
        "children":{"closure":["elastic","drawstring"],"fit":["relaxed","regular"]},
        "teenage":{"categories":["Sneakers","Pullover hoodie","Zippered hoodie"]},
        "young-adult": {}, "adult": {}, "middle-aged-adult": {},
        "senior":{"closure":["slip-on","zipper"],"type":["loafers","slippers"]},
    }
    GENDER_HINTS = {
        "male":{"formal_categories":["Neck tie","Bow tie","Oxford dress shoes","Blazer"]},
        "female":{"formal_groups":["Dresses & Rompers","Skirts"],"formal_categories":["Evening gown","Cocktail dress","Heel pumps"]},
    }

    # أوزان أقوى للمناسبة
    W = {
        "occasion_group": 22.0,
        "occasion_category": 30.0,
        "temp_material":  5.0,
        "temp_sleeve":    3.0,
        "temp_insul":     4.0,
        "temp_length":    3.0,
        "weather_group":  5.0,
        "weather_category": 8.0,
        "weather_mat":    4.0,
        "color":          2.0,
        "age_closure":    2.0,
        "age_fit":        2.0,
        "age_category":   2.0,
        "gender_formal_group":    6.0,
        "gender_formal_category": 8.0,
    }

    occ = OCCASION_CORE.get(norm(occasion), {"groups": [], "categories": []})
    temp_band = to_temp_band(temperature)
    weat = WEATHER_RULES.get(norm(weather), {"categories": [], "materials": [], "groups": []})
    color_pref = COLOR_PREFS.get(temp_band, [])
    age = AGE_HINTS.get(norm(age_group), {})
    gen = GENDER_HINTS.get(norm(gender), {})

    scored_items = []
    for item in outfit_items:
        breakdown = {k: 0.0 for k in ["occasion","temperature","weather","color","age_gender"]}
        raw_points = 0.0
        max_points = 0.0

        # Occasion (قوي)
        max_points += W["occasion_group"] + W["occasion_category"]
        if group_is(item, occ["groups"]):
            raw_points += W["occasion_group"]; breakdown["occasion"] += W["occasion_group"]
        if name_is(item, occ["categories"]) or norm(item.get("type")) in [norm(x) for x in occ["categories"]]:
            raw_points += W["occasion_category"]; breakdown["occasion"] += W["occasion_category"]

        # Temperature
        temp_mats = TEMP_MATERIALS.get(temp_band, [])
        cov = TEMP_COVERAGE.get(temp_band, {})
        max_points += W["temp_material"] + W["temp_sleeve"] + W["temp_insul"] + W["temp_length"]
        if has_attr(item, "material", temp_mats):
            raw_points += W["temp_material"]; breakdown["temperature"] += W["temp_material"]
        if cov.get("sleeve") and has_attr(item, "sleeve", cov["sleeve"]):
            raw_points += W["temp_sleeve"]; breakdown["temperature"] += W["temp_sleeve"]
        if cov.get("insulation") and has_attr(item, "insulation", cov["insulation"]):
            raw_points += W["temp_insul"]; breakdown["temperature"] += W["temp_insul"]
        if cov.get("length") and has_attr(item, "length", cov["length"]):
            raw_points += W["temp_length"]; breakdown["temperature"] += W["temp_length"]

        # Weather
        max_points += W["weather_group"] + W["weather_category"] + W["weather_mat"]
        if group_is(item, weat["groups"]):
            raw_points += W["weather_group"]; breakdown["weather"] += W["weather_group"]
        if name_is(item, weat["categories"]) or norm(item.get("type")) in [norm(x) for x in weat["categories"]]:
            raw_points += W["weather_category"]; breakdown["weather"] += W["weather_category"]
        if has_attr(item, "material", weat["materials"]):
            raw_points += W["weather_mat"]; breakdown["weather"] += W["weather_mat"]

        # Color
        max_points += W["color"]
        if has_attr(item, "color_group", color_pref):
            raw_points += W["color"]; breakdown["color"] += W["color"]

        # Age/Gender hints (يقوى تأثيرها بالمناسبات الرسمية)
        max_points += W["age_closure"] + W["age_fit"] + W["age_category"]
        if age.get("closure") and has_attr(item, "closure", age["closure"]):
            raw_points += W["age_closure"]; breakdown["age_gender"] += W["age_closure"]
        if age.get("fit") and has_attr(item, "fit", age["fit"]):
            raw_points += W["age_fit"]; breakdown["age_gender"] += W["age_fit"]
        if age.get("categories") and name_is(item, age["categories"]):
            raw_points += W["age_category"]; breakdown["age_gender"] += W["age_category"]
        if age.get("type") and has_attr(item, "type", age["type"]):
            raw_points += W["age_category"]; breakdown["age_gender"] += W["age_category"]

        if norm(occasion) in ["formal", "wedding"]:
            max_points += W["gender_formal_group"] + W["gender_formal_category"]
            if gen.get("formal_groups") and group_is(item, gen["formal_groups"]):
                raw_points += W["gender_formal_group"]; breakdown["age_gender"] += W["gender_formal_group"]
            if gen.get("formal_categories") and (name_is(item, gen["formal_categories"]) or norm(item.get("type")) in [norm(x) for x in gen["formal_categories"]]):
                raw_points += W["gender_formal_category"]; breakdown["age_gender"] += W["gender_formal_category"]

        score = 100.0 * (raw_points / max_points) if max_points > 0 else 0.0
        scored_items.append({"category": item.get("category"),
                             "group": item.get("category_group"),
                             "score": round(score,2)})
    return round(sum(i["score"] for i in scored_items) / len(scored_items), 2) if scored_items else 0.0

def suggest_outfit_additions(outfit_items, weather, occasion, temperature):
    have_groups = {(item.get("category_group") or "").strip() for item in outfit_items}
    suggestions = []

    # طقس ممطر/ثلج: نفس قواعدك
    if weather in ["rainy"] and "Outerwear" not in have_groups:
        suggestions.append("Raincoat / Windbreaker jacket")
    if weather in ["rainy"] and all(g not in have_groups for g in ["Footwear"]):
        suggestions.append("Rain boots")
    if weather in ["snowy"] and "Outerwear" not in have_groups:
        suggestions.append("Puffer jacket / Parka")
    if weather in ["snowy"] and "Headwear" not in have_groups:
        suggestions.append("Beanie hat")
    if weather in ["snowy"] and "Handwear" not in have_groups:
        suggestions.append("Gloves")

    # رسمي/عرس: مثل قبل
    if occasion in ["formal", "wedding"]:
        if "Neckwear" not in have_groups:
            suggestions.append("Neck tie / Bow tie")
        if "Outerwear" not in have_groups:
            suggestions.append("Blazer / Trench coat")

    # شمس/حر: نظارات فقط (بدون فرض طاقية إلا بظروف خاصة)
    if temperature in ["warm", "hot", "extreme_hot"]:
        if "Eyewear" not in have_groups:
            suggestions.append("Sunglasses")

    # Headwear بشكل “ذكي”
    if occasion == "beachwear" and temperature in ["warm", "hot", "extreme_hot"] and "Headwear" not in have_groups:
        suggestions.append("Sun hat")
    elif occasion == "sport" and "Headwear" not in have_groups:
        suggestions.append("Headband / Baseball cap")

    # Homewear: شباشب فقط مثل قبل
    if occasion == "lounge-homewear" and "Footwear" not in have_groups:
        suggestions.append("Slippers")

    return suggestions

def hard_rule_penalty(outfit, user_inputs):
    """
    Penalty على مستوى الطقم كامل إذا خالف قواعد المناسبة/الطقس.
    الهدف: المناسبة تسبق الطقس والحرارة.
    """
    occ = (user_inputs.get('occasion') or '').strip().lower()
    weat = (user_inputs.get('weather') or '').strip().lower()
    gender = (user_inputs.get('gender') or '').strip().lower()

    pen = 0

    # 1) رسمي / عرس: لا شورت، لا دنيم، لا صندل/شبشب/سنيكرز، لا Rain boots
    if occ in ('formal', 'wedding'):
        for it in outfit.items:
            name = (it.category or '').lower()
            mat  = (it.get('material') or '').lower()
            grp  = (it.category_group or '').lower()

            if name in {'shorts', 'denim shorts'}: pen += 120
            if name in {'jeans', 'straight-leg jeans', 'skinny jeans', 'bootcut jeans'}: pen += 120
            if name in {'sandals','flip-flops','sneakers','rain boots'}: pen += 120
            # الأحذية الرسمية المطلوبة
            if grp == 'footwear':
                if gender == 'female' and name != 'heel pumps':
                    pen += 80
                if gender != 'female' and name != 'oxford dress shoes' and name != 'dress shoe':
                    pen += 80

    # 2) مطر: ممنوع سويد على القدم
    if weat == 'rainy':
        for it in outfit.items:
            if (it.category_group or '').lower() == 'footwear' and (it.get('material') or '').lower() == 'suede':
                pen += 80

    # 3) شمس/حر شديد: تجنّب Outerwear الثقيل (ما رح نمنع بس نقلل)
    try:
        # user_inputs['temperature'] قد تكون band؛ خلينا نحولها بسرعة
        tband = (user_inputs.get('temperature') or '').lower()
        hot = tband in {'warm','hot','extreme_hot'}
    except:
        hot = False

    if hot:
        for it in outfit.items:
            if (it.category_group or '').lower() == 'outerwear':
                # خفّض بس لا تمنع
                pen += 20

    return pen

# NEW
def color_cohesion_penalty(outfit):
    """
    Penalty بسيط إذا في كثير مجموعات ألوان غير متناسقة بدون نيوترال يوحّد.
    إذا ≥3 مجموعات غير neutrals وما في neutrals → نزّل 30 نقطة.
    """
    groups = []
    for it in outfit.items:
        cg = (it.get('color_group') or it.attributes.get('color_group') or '').lower()
        if cg:
            groups.append(cg)
    if not groups:
        return 0
    distinct = set(groups)
    has_neutral = 'neutrals' in distinct
    if len(distinct - {'neutrals'}) >= 3 and not has_neutral:
        return 30
    return 0



def calculate_fitness(matching_outfits, outfit, user_inputs):
    best_match, max_score = _find_similar_outfit(
        matching_outfits, user_inputs['occasion'], user_inputs['weather'],
        user_inputs['temperature'], user_inputs['age'],
        user_inputs['gender'], outfit
    )
    max_score += _calculate_outfit_weight(outfit)
    max_score += rate_outfit_items(
        outfit.items, user_inputs['weather'], user_inputs['occasion'],
        user_inputs['temperature'], user_inputs['age'], user_inputs['gender']
    )

    # NEW: خصم مخالفات المناسبة/الطقس + تماسك الألوان
    max_score -= hard_rule_penalty(outfit, user_inputs)
    max_score -= color_cohesion_penalty(outfit)

    BASE_OUTFITS.append([int(max_score), best_match])
    return int(max_score)

def get_another_item_for_outer(user_wardrobe, category_group, current_item, chosen_item_ids):
    valid_items = []
    if current_item is None:
        return None
    if category_group == 'Tops':
        if current_item.category not in Top_Layer:
            return None
        valid_items = [
            item for item in user_wardrobe
            if item.category_group == category_group and item.id not in chosen_item_ids and item.category in Top_Layer[current_item.category]
        ]
    elif category_group == 'Outerwear':
        if current_item.category not in Outer_Layer:
            return None
        valid_items = [
            item for item in user_wardrobe
            if item.category_group == category_group and item.id not in chosen_item_ids and item.category in Outer_Layer[current_item.category]
        ]
    if not valid_items:
        return None
    return random.choice(valid_items)

def get_item_for_category_group(user_wardrobe, category_group, chosen_item_ids):
    valid_items = [
        item for item in user_wardrobe
        if item.category_group == category_group and item.id not in chosen_item_ids
    ]
    if not valid_items:
        return None
    return random.choice(valid_items)

def get_item_for_category(user_wardrobe, category, chosen_item_ids):
    valid_items = [
        item for item in user_wardrobe
        if item.category == category and item.id not in chosen_item_ids
    ]
    if not valid_items:
        return None
    return random.choice(valid_items)

def get_beachwear_outfit(user_inputs, user_wardrobe):
    outfit_items = []
    chosen_item_ids = set()
    gender = user_inputs["gender"]

    sandals = get_item_for_category_group(user_wardrobe, "Footwear", chosen_item_ids)
    if sandals and sandals.category == "Sandals":
        outfit_items.append(sandals)
        chosen_item_ids.add(sandals.id)

    outfit_type = random.choice(["swimwear", "casual"])

    if gender == "female":
        bra_or_one_piece = random.choice(["bra", "one-piece"])
        if bra_or_one_piece == "one-piece":
            item = get_item_for_category_group(user_wardrobe, "Underwear & Swimwear", chosen_item_ids)
            if item and item.category == "One-piece swimsuit":
                outfit_items.append(item)
                chosen_item_ids.add(item.id)
        else:
            bra = get_item_for_category_group(user_wardrobe, "Underwear & Swimwear", chosen_item_ids)
            panty = get_item_for_category_group(user_wardrobe, "Underwear & Swimwear", chosen_item_ids)
            if bra and panty and bra.category == "Bra" and panty.category == "Panty":
                outfit_items.extend([bra, panty])
                chosen_item_ids.add(bra.id)
                chosen_item_ids.add(panty.id)

    elif gender == "male":
        item = None
        if random.random() < 0.5:
            item = get_item_for_category_group(user_wardrobe, "Underwear & Swimwear", chosen_item_ids)
            if item and item.category == "Boxers":
                outfit_items.append(item)
                chosen_item_ids.add(item.id)

        shorts = get_item_for_category_group(user_wardrobe, "Bottoms", chosen_item_ids)
        if shorts and shorts.category == "Shorts":
            outfit_items.append(shorts)
            chosen_item_ids.add(shorts.id)

    if outfit_type == "casual":
        if gender == "female":
            casual_option = random.choice(["top_and_bottom", "top_and_bottom", "dress", "bottom_only"])
            if casual_option == "dress":
                item = get_item_for_category_group(user_wardrobe, "Dresses & Rompers", chosen_item_ids)
                if item and item.category == "Sundress":
                    outfit_items.append(item)
                    chosen_item_ids.add(item.id)
            elif casual_option == "top_and_bottom":
                top = get_item_for_category_group(user_wardrobe, "Tops", chosen_item_ids)
                shorts = get_item_for_category_group(user_wardrobe, "Bottoms", chosen_item_ids)
                if top and shorts and shorts.category == "Shorts":
                    outfit_items.extend([top, shorts])
                    chosen_item_ids.add(top.id)
                    chosen_item_ids.add(shorts.id)
            elif casual_option == "bottom_only":
                bottom = get_item_for_category_group(user_wardrobe, "Bottoms", chosen_item_ids)
                if bottom and (bottom.category in ["Shorts"] or bottom.category in ["Denim shorts"]):
                    outfit_items.append(bottom)
                    chosen_item_ids.add(bottom.id)
        elif gender == "male":
            top = get_item_for_category_group(user_wardrobe, "Tops", chosen_item_ids)
            if top:
                outfit_items.append(top)
                chosen_item_ids.add(top.id)

    for accessory_category in ["Eyewear", "Headwear", "Bags"]:
        if random.random() < 0.5:
            accessory = get_item_for_category_group(user_wardrobe, accessory_category, chosen_item_ids)
            if accessory and (accessory.category in ["Sunglasses", "Sun hat", "Tote bag"]):
                outfit_items.append(accessory)
                chosen_item_ids.add(accessory.id)

    return outfit_items, chosen_item_ids

def initialize_population(matching_outfits, population_size, user_inputs, user_wardrobe):
    """
    توليد السكان مع ضبط الإكسسوارات:
    - Headwear يُضاف فقط إذا كان مناسب (snowy → Beanie hat / sport → Headband/Baseball cap /
      beachwear الحار → Sun hat).
    - Neck tie/Bow tie يبقوا مقيّدين بالرسمي/العرس.
    - بناء all_possible_outfits من خزانة المستخدم وفق قواعد البنية الأساسية.
    """
    import copy
    import random

    # === Helpers محلية سريعة ===
    def pick_one(seq):
        return random.choice(seq) if seq else None

    def by_group(lst, g, exclude_ids):
        return [x for x in lst if x.category_group == g and x.id not in exclude_ids]

    def by_cat(lst, c, exclude_ids):
        return [x for x in lst if x.category == c and x.id not in exclude_ids]

    def add_unique(outfit, item, layer=None, chosen_ids=None):
        if item is None:
            return False
        if chosen_ids is not None and item.id in chosen_ids:
            return False
        outfit.add_item(item, layer)
        if chosen_ids is not None:
            chosen_ids.add(item.id)
        return True

    # تفضيلات بسيطة حسب المناسبة لتوجيه الاختيار
    occ = (user_inputs.get('occasion') or '').strip().lower()
    weat = (user_inputs.get('weather') or '').strip().lower()
    tband = (user_inputs.get('temperature') or '').strip().lower()

    # قواعد اختيار tops/footwear حسب المناسبة
    def filter_tops_for_occasion(cands):
        names = {it.category for it in cands}
        if occ in ('formal','wedding'):
            pref = [c for c in cands if c.category in ('Dress shirt','Button-down shirt','Silk blouse','Blouse')]
            return pref or cands
        if occ == 'sport':
            pref = [c for c in cands if c.category in ('Jersey','T-shirt','Pullover hoodie','Zippered hoodie','Tracksuit jacket')]
            return pref or cands
        if occ == 'smart_casual':
            pref = [c for c in cands if c.category in ('Button-down shirt','Dress shirt','Knit sweater','Blouse','Polo shirt')]
            return pref or cands
        return cands

    def filter_footwear_for_context(cands):
        # مطر → تجنّب suede إن أمكن
        if weat == 'rainy':
            non_suede = [c for c in cands if (c.get('material') or '').lower() != 'suede' and c.category != 'Suede dress shoes']
            if non_suede:
                cands = non_suede
        if occ in ('formal','wedding'):
            pref = [c for c in cands if c.category in ('Oxford dress shoes','Heel pumps','Dress shoe')]
            return pref or cands
        if occ == 'beachwear':
            pref = [c for c in cands if c.category in ('Sandals','Flip-flops')]
            return pref or cands
        if occ == 'sport':
            pref = [c for c in cands if c.category in ('Sneakers',)]
            return pref or cands
        return cands

    # تجميع مجموعات متاحة بالخزانة
    available_groups = {it.category_group for it in user_wardrobe}

    # === 1) ابنِ all_possible_outfits من الصفر ===
    all_possible_outfits = []

    # حالة beachwear: نستخدم مولّدك الجاهز
    if occ == 'beachwear':
        tries = max(60, population_size * 6)
        for _ in range(tries):
            outfit_items, chosen = get_beachwear_outfit(user_inputs, user_wardrobe)
            if not outfit_items:
                continue
            o = Outfit([])
            # عيّن طبقات مبدئية بسيطة
            for it in outfit_items:
                layer = None
                if it.category_group == 'Outerwear':
                    layer = 'outer'
                elif it.category_group == 'Tops':
                    layer = 'inner'
                elif it.category_group in ('Eyewear','Other Accessories','Neckwear','Handwear','Wristwear','Headwear','Bags'):
                    layer = 'accessory'
                o.add_item(it, layer)
            all_possible_outfits.append(o)
    else:
        # باقي المناسبات تعتمد OUTFIT_STRUCTURE_RULES
        # حضّر لوائح حسب المجموعة
        items_by_group = {}
        for g in ('Tops','Bottoms','Skirts','Dresses & Rompers','Footwear','Outerwear',
                  'Headwear','Bags','Neckwear','Earwear','Wristwear','Handwear','Eyewear','Other Accessories'):
            items_by_group[g] = [x for x in user_wardrobe if x.category_group == g]

        # جرّب تكوينات كثيرة ثم نحسم لاحقًا
        tries = max(200, population_size * 15)

        valid_rules = []
        for rule in OUTFIT_STRUCTURE_RULES:
            if rule.issubset(available_groups):
                valid_rules.append(rule)
        # fallback إذا ما في rule كامل
        if not valid_rules:
            core = set()
            if 'Tops' in available_groups: core.add('Tops')
            if 'Footwear' in available_groups: core.add('Footwear')
            # واحد من Bottoms/Skirts/Dresses
            if 'Bottoms' in available_groups: core.add('Bottoms')
            elif 'Skirts' in available_groups: core.add('Skirts')
            elif 'Dresses & Rompers' in available_groups: core.add('Dresses & Rompers')
            if len(core) >= 2:
                valid_rules = [core]

        for _ in range(tries):
            if not valid_rules:
                break
            rule = pick_one(valid_rules)
            if not rule:
                continue
            chosen_ids = set()
            o = Outfit([])

            # TOPS
            if 'Tops' in rule:
                tops = filter_tops_for_occasion([x for x in items_by_group['Tops'] if x.id not in chosen_ids])
                add_unique(o, pick_one(tops), 'inner', chosen_ids)

            # BOTTOMS / SKIRTS / DRESSES
            if 'Dresses & Rompers' in rule:
                add_unique(o, pick_one([x for x in items_by_group['Dresses & Rompers'] if x.id not in chosen_ids]), None, chosen_ids)
            else:
                if 'Bottoms' in rule:
                    add_unique(o, pick_one([x for x in items_by_group['Bottoms'] if x.id not in chosen_ids]), None, chosen_ids)
                if 'Skirts' in rule:
                    add_unique(o, pick_one([x for x in items_by_group['Skirts'] if x.id not in chosen_ids]), None, chosen_ids)

            # FOOTWEAR
            if 'Footwear' in rule:
                fw_pool = filter_footwear_for_context([x for x in items_by_group['Footwear'] if x.id not in chosen_ids])
                add_unique(o, pick_one(fw_pool), None, chosen_ids)
            # أمان إضافي: إذا تمّت إضافة Bottoms و Skirts بالخطأ، نحذف البنطلون ونبقي التنورة
            if any(it.category_group == 'Skirts' for it in o.items) and any(it.category_group == 'Bottoms' for it in o.items):
                for it in [x for x in list(o.items) if x.category_group == 'Bottoms']:
                    o.remove_item(it)

            # منع إضافة Top إضافي: لا Layering للـ Tops لتجنّب Double Top

            # احتمال إضافة Outerwear في الأجواء الباردة/المتقلبة
            if (weat in ('snowy','rainy') or tband in ('cool','cold','extreme_cold')) and random.random() < 0.5:
                add_unique(o, pick_one([x for x in items_by_group['Outerwear'] if x.id not in chosen_ids]), 'outer', chosen_ids)

            # إكسسوارات: التزام القواعد
            ALL_ACC = ['Headwear','Bags','Neckwear','Earwear','Wristwear','Handwear','Eyewear']
            if random.random() < 0.6:
                groups_to_try = random.sample(ALL_ACC, k=random.randint(1, min(3, len(ALL_ACC))))
                for g in groups_to_try:
                    if any(it.category_group == g for it in o.items):
                        continue
                    # Neckwear فقط للرسمي/العرس
                    if g == 'Neckwear' and occ not in ('formal','wedding'):
                        continue
                    # Headwear ذكي
                    if g == 'Headwear':
                        item = None
                        if weat == 'snowy':
                            cand = by_cat(user_wardrobe, 'Beanie hat', chosen_ids)
                            item = pick_one(cand)
                        elif occ == 'sport':
                            cand = by_cat(user_wardrobe, 'Headband', chosen_ids) or by_cat(user_wardrobe, 'Baseball cap', chosen_ids)
                            item = pick_one(cand)
                        elif occ == 'beachwear' and tband in ('warm','hot','extreme_hot'):
                            cand = by_cat(user_wardrobe, 'Sun hat', chosen_ids)
                            item = pick_one(cand)
                        if item is None:
                            continue
                        add_unique(o, item, 'accessory', chosen_ids)
                        continue
                    # Eyewear: نحبه بالشمس/حر
                    if g == 'Eyewear' and not ((weat in ('clear','sunny')) or tband in ('warm','hot','extreme_hot')):
                        # نخفف إضافته إذا الجو مو شمس/حر
                        if random.random() < 0.5:
                            continue
                    cand = by_group(user_wardrobe, g, chosen_ids)
                    # استثناء ties خارج الرسمي
                    cand = [x for x in cand if not (x.category in ('Neck tie','Bow tie') and occ not in ('formal','wedding'))]
                    add_unique(o, pick_one(cand), 'accessory', chosen_ids)

            # Other Accessories: حد أقصى 2، بدون تكرار
            if random.random() < 0.4:
                pool_names = ['Belt','Ring','Brooch','Pocket square','Umbrella']
                random.shuffle(pool_names)
                added = 0
                for name in pool_names:
                    if added >= 2: break
                    if any(it.category == name for it in o.items):
                        continue
                    cand = by_cat(user_wardrobe, name, chosen_ids)
                    if cand:
                        add_unique(o, pick_one(cand), 'accessory', chosen_ids)
                        added += 1

            # تجاهل الأطقم الفارغة
            if o.items:
                all_possible_outfits.append(o)

    # === 2) توسيع بـ Outerwear إضافي في البرد (نفس منطقك) ===
    A = random.random()
    B = random.random()
    if ((user_inputs['weather'] in ['snowy'] or user_inputs['temperature'] in ["cool","cold","extreme_cold"]) and A < 0.7) or B < 0.3:
        outer_items = [i for i in user_wardrobe if i.category_group == 'Outerwear']
        # مهم: إذا ما في أطقم، ما منقدر نلف على list(all_possible_outfits)
        if not all_possible_outfits:
            # حاول نولد أساس واحد ثم نضيف Outerwear
            base = Outfit([])
            add_unique(base, pick_one([x for x in user_wardrobe if x.category_group == 'Tops']), 'inner')
            add_unique(base, pick_one([x for x in user_wardrobe if x.category_group in ('Bottoms','Skirts','Dresses & Rompers')]))
            add_unique(base, pick_one([x for x in user_wardrobe if x.category_group == 'Footwear']))
            if base.items:
                all_possible_outfits.append(base)
        for base in list(all_possible_outfits):
            has_outer = any(it.category_group == 'Outerwear' for it in base.items)
            if has_outer:
                continue
            for ow in outer_items:
                new_o = copy.deepcopy(base)
                new_o.add_item(ow, 'outer')
                all_possible_outfits.append(new_o)

    population = []
    if all_possible_outfits:
        if len(all_possible_outfits) >= population_size:
            population = random.sample(all_possible_outfits, population_size)
        else:
            population = copy.deepcopy(all_possible_outfits)
            for _ in range(max(0, population_size - len(all_possible_outfits))):
                base = copy.deepcopy(random.choice(all_possible_outfits))
                # محاولات خفيفة لإضافة تنويعات
                chosen_ids = {it.id for it in base.items}
                # احتمال Layering للـ Tops
                ## منع إضافة Top إضافي في مرحلة التوسيع للحفاظ على Top واحد فقط
                # إضافة إكسسوارات (نفس القيود)
                ALL_ACC = ['Headwear','Bags','Neckwear','Earwear','Wristwear','Handwear','Eyewear']
                if random.random() < 0.6:
                    acc_groups = random.sample(ALL_ACC, random.randint(1, min(3, len(ALL_ACC))))
                    for g in acc_groups:
                        if any(it.category_group == g for it in base.items):
                            continue
                        if g == "Neckwear" and occ not in ['wedding','formal']:
                            continue
                        if g == "Headwear":
                            item = None
                            if weat == 'snowy':
                                item = pick_one(by_cat(user_wardrobe, "Beanie hat", chosen_ids))
                            elif occ == 'sport':
                                item = pick_one(by_cat(user_wardrobe, "Headband", chosen_ids)) or \
                                       pick_one(by_cat(user_wardrobe, "Baseball cap", chosen_ids))
                            elif occ == 'beachwear' and tband in ["warm","hot","extreme_hot"]:
                                item = pick_one(by_cat(user_wardrobe, "Sun hat", chosen_ids))
                            if not item:
                                continue
                            base.add_item(item, 'accessory'); chosen_ids.add(item.id)
                            continue
                        # باقي الإكسسوارات
                        cand = [x for x in by_group(user_wardrobe, g, chosen_ids)
                                if not (x.category in ["Neck tie","Bow tie"] and occ not in ['wedding','formal'])]
                        if cand:
                            item = random.choice(cand)
                            base.add_item(item, 'accessory'); chosen_ids.add(item.id)
                population.append(base)

    # Sanitization + حساب اللياقة
    clean_population = []
    for o in population:
        if not o or not getattr(o, "items", None):
            continue
        o = sanitize_outfit(o, user_inputs)
        o.fitness = calculate_fitness(matching_outfits, o, user_inputs)
        clean_population.append(o)

    # إذا فاضي (احتياط)
    if not clean_population:
        # جرّب Outfit بسيط جدًا من ثلاث قطع
        simple = Outfit([])
        ids = set()
        add_unique(simple, pick_one([x for x in user_wardrobe if x.category_group == 'Tops']), 'inner', ids)
        add_unique(simple, pick_one([x for x in user_wardrobe if x.category_group in ('Bottoms','Skirts','Dresses & Rompers')]), None, ids)
        add_unique(simple, pick_one([x for x in user_wardrobe if x.category_group == 'Footwear']), None, ids)
        if simple.items:
            simple = sanitize_outfit(simple, user_inputs)
            simple.fitness = calculate_fitness(matching_outfits, simple, user_inputs)
            clean_population.append(simple)

    return clean_population

def select_parents(population):
    if not population:
        raise ValueError("Population is empty.")
    if len(population) == 1:
        return population[0], population[0]

    tournament_size = max(2, len(population) // 10)
    tournament_size = min(tournament_size, len(population))

    def get_winner(contestants):
        return max(contestants, key=lambda outfit: outfit.fitness)

    parent1 = get_winner(random.sample(population, tournament_size))

    parent2 = parent1
    attempts = 0
    while parent2 == parent1 and len(population) > 1 and attempts < 10:
        parent2 = get_winner(random.sample(population, tournament_size))
        attempts += 1

    if parent2 == parent1:
        sorted_pop = sorted(population, key=lambda o: o.fitness, reverse=True)
        parent2 = sorted_pop[1] if len(sorted_pop) > 1 else sorted_pop[0]

    return parent1, parent2

def crossover(parent1, parent2, crossover_rate):
    """
    MODIFIED:
    - بعد أي تبادل، ننظّف الطفلين بـ sanitize_outfit لضمان منطقية النتائج.
    """
    child1 = Outfit(copy.deepcopy(parent1.items))
    child2 = Outfit(copy.deepcopy(parent2.items))

    if random.random() < crossover_rate:
        p1g = parent1.get_categories()
        p2g = parent2.get_categories()
        commons = list(p1g.intersection(p2g))
        if commons:
            swap_cat = random.choice(commons)
            p1_items = parent1.get_items_by_category_group(swap_cat)
            p2_items = parent2.get_items_by_category_group(swap_cat)

            child1.items = [it for it in child1.items if it.category_group != swap_cat]
            child2.items = [it for it in child2.items if it.category_group != swap_cat]
            child1.items.extend(p2_items)
            child2.items.extend(p1_items)

            if not child1.validate_undergarments():
                child1 = Outfit(copy.deepcopy(parent1.items))
            if not child2.validate_undergarments():
                child2 = Outfit(copy.deepcopy(parent2.items))

    # Sanitize (نحتاج user_inputs؛ نشتقّه بالحد الأدنى من الوالدين إن وُجد)
    # هنا نفترض أن آخر حساب لياقة عند الأهل تم بنفس user_inputs في الحلقة الخارجية؛
    # لذلك نعيد استعمال نفس المنطق: لن نملك user_inputs داخل هذه الدالة.
    # سنكتفي بتنظيف عام بلا اعتماد على الطقس/المناسبة (لا يؤثر على قواعد التكرار).
    # لضمان عمل sanitize_outfit، نمرر dict فارغ لمتطلبات ثانوية.
    dummy_inputs = {"occasion":"","weather":"","temperature":"","age":"","gender":""}
    child1 = sanitize_outfit(child1, dummy_inputs)
    child2 = sanitize_outfit(child2, dummy_inputs)

    return child1, child2


def mutate(matching_outfits, outfit, user_inputs, user_wardrobe, mutation_rate):
    """
    MODIFIED:
    - بعد أي تعديل نقوم بـ sanitize_outfit ثم إعادة حساب اللياقة.
    - منطق الإكسسوارات يمنع تكرار المجموعة ذاتها.
    """
    new_outfit = copy.deepcopy(outfit)
    if not new_outfit.items:
        return new_outfit

    chosen_ids = {it.id for it in new_outfit.items}
    base_categories = ["Tops","Bottoms","Skirts","Footwear","Dresses & Rompers","Outerwear"]

    def get_item_for_category_group(lst, category_group, chosen):
        cands = [x for x in lst if x.category_group == category_group and x.id not in chosen]
        return random.choice(cands) if cands else None

    def get_item_for_category(lst, category, chosen):
        cands = [x for x in lst if x.category == category and x.id not in chosen]
        return random.choice(cands) if cands else None

    # تبديل قطعة من مجموعات القاعدة أحياناً
    if random.random() < mutation_rate and any(it.category_group in base_categories for it in new_outfit.items):
        present_groups = list({it.category_group for it in new_outfit.items if it.category_group in base_categories})
        if present_groups:
            cat_to_mut = random.choice(present_groups)
            group_items = [it for it in new_outfit.items if it.category_group == cat_to_mut]
            if group_items:
                removed = random.choice(group_items)
                new_outfit.remove_item(removed); chosen_ids.discard(removed.id)
                repl = get_item_for_category_group(user_wardrobe, cat_to_mut, chosen_ids)
                if repl:
                    new_outfit.add_item(repl); chosen_ids.add(repl.id)

    # احتمال تبديل إكسسوار واحد
    acc_groups = ["Headwear","Bags","Neckwear","Earwear","Wristwear","Handwear","Eyewear","Other Accessories"]
    if random.random() < 0.5:
        present_acc_groups = list({it.category_group for it in new_outfit.items if it.category_group in acc_groups})
        if present_acc_groups:
            g = random.choice(present_acc_groups)
            # احذف كل عناصر المجموعة
            for it in [x for x in list(new_outfit.items) if x.category_group == g]:
                new_outfit.remove_item(it); chosen_ids.discard(it.id)
            # أضف بديل واحد من نفس المجموعة (إلا ربطة العنق/بابيون إلا إذا رسمي/عرس)
            repl = get_item_for_category_group(user_wardrobe, g, chosen_ids)
            if repl:
                if repl.category in ["Neck tie","Bow tie"] and user_inputs['occasion'] not in ['wedding','formal']:
                    pass
                else:
                    new_outfit.add_item(repl, layer="accessory"); chosen_ids.add(repl.id)

    # احتمال إضافة إكسسوار جديد من مجموعة غير موجودة مسبقاً
    elif random.random() < 0.4:
        missing_groups = [g for g in acc_groups if not any(it.category_group == g for it in new_outfit.items)]
        if missing_groups:
            g = random.choice(missing_groups)
            repl = get_item_for_category_group(user_wardrobe, g, chosen_ids)
            if repl:
                if repl.category in ["Neck tie","Bow tie"] and user_inputs['occasion'] not in ['wedding','formal']:
                    pass
                else:
                    new_outfit.add_item(repl, layer="accessory"); chosen_ids.add(repl.id)

    # Other Accessories (حد أقصى 2، لا تكرار لنفس الفئة)
    if random.random() < 0.5:
        others = ["Belt","Ring","Brooch","Pocket square","Umbrella"]
        random.shuffle(others)
        current_others = [it for it in new_outfit.items if it.category_group == "Other Accessories"]
        if len(current_others) < 2:
            for oc in others:
                if any(it.category == oc for it in new_outfit.items): continue
                cand = get_item_for_category(user_wardrobe, oc, chosen_ids)
                if cand:
                    new_outfit.add_item(cand, layer="accessory"); chosen_ids.add(cand.id)
                    break

    # Sanitization + إعادة حساب اللياقة
    new_outfit = sanitize_outfit(new_outfit, user_inputs)
    if not new_outfit.validate_undergarments():
        return outfit
    new_outfit.fitness = calculate_fitness(matching_outfits, new_outfit, user_inputs)
    return new_outfit
def run_genetic_algorithm(user_inputs, user_wardrobe, population_size, num_generations, mutation_rate, crossover_rate, patience=50):
    BASE_OUTFITS.clear()
    POPULATION_SIZE_LOCAL = population_size
    NUM_GENERATIONS_LOCAL = num_generations
    MUTATION_RATE_LOCAL = mutation_rate
    CROSSOVER_RATE_LOCAL = crossover_rate

    matching_outfits_dict = []
    for outfit in OUTFITS_FROM_INTERNET:
        for key, score in outfit["scores"].items():
            parts = key.split('_')
            score_weather = parts[0]
            score_occasion = parts[1]
            score_temperature = parts[2]
            score_age_group = parts[3]
            score_gender = parts[4]

            if score_weather == user_inputs["weather"] and \
               score_occasion == user_inputs["occasion"] and \
               score_temperature == user_inputs["temperature"] and \
               score_age_group == user_inputs["age"] and \
               score_gender == user_inputs["gender"]:
                outfit["score_value"] = score
                matching_outfits_dict.append(outfit)
                break

    matching_outfits = []
    for outfit_dict in matching_outfits_dict:
        matching_outfits.append(_dict_to_outfit(outfit_dict))

    population = initialize_population(matching_outfits, POPULATION_SIZE_LOCAL, user_inputs, user_wardrobe)
    POPULATION_SIZE_LOCAL = len(population)
    population = [o for o in population if o is not None and len(o.items) > 0]
    population.sort(key=lambda outfit: outfit.fitness, reverse=True)
    best_outfit_overall = population[0]

    generations_without_improvement = 0
    best_fitness_since_last_improvement = best_outfit_overall.fitness

    for _ in range(NUM_GENERATIONS_LOCAL):
        new_population = []
        new_population.append(best_outfit_overall)

        while len(new_population) < POPULATION_SIZE_LOCAL:
            parent1, parent2 = select_parents(population)
            child1, child2 = crossover(parent1, parent2, CROSSOVER_RATE_LOCAL)

            mutated_child1 = mutate(matching_outfits, child1, user_inputs, user_wardrobe, MUTATION_RATE_LOCAL)
            mutated_child2 = mutate(matching_outfits, child2, user_inputs, user_wardrobe, MUTATION_RATE_LOCAL)

            if mutated_child1 and len(mutated_child1.items) > 0:
                new_population.append(mutated_child1)
            if len(new_population) < POPULATION_SIZE_LOCAL and mutated_child2 and len(mutated_child2.items) > 0:
                new_population.append(mutated_child2)

        for outfit in new_population:
            outfit.fitness = calculate_fitness(matching_outfits, outfit, user_inputs)

        new_population.sort(key=lambda outfit: outfit.fitness, reverse=True)
        population = new_population

        if population[0].fitness > best_fitness_since_last_improvement:
            best_outfit_overall = population[0]
            best_fitness_since_last_improvement = best_outfit_overall.fitness
            generations_without_improvement = 0
        else:
            generations_without_improvement += 1

        if generations_without_improvement >= patience:
            break

    return best_outfit_overall

def generate_outfit_recommendation(weather, occasion, temperature, age, gender, user_wardrobe=None,
                                   population_size=10, num_generations=100, mutation_rate=0.16, crossover_rate=0.1, patience=300):
    weather_norm = {"sunny": "clear"}.get((weather or "").strip().lower(), weather)
    temperature = get_temperature_range_label(temperature)
    age = get_age_group(age if age is not None else 25)
    gender = (gender or "").strip().lower()
    user_inputs = {
        "weather": weather_norm,   # ← استعمل الموحّد للتوليد/التقييم
        "occasion": occasion,
        "temperature": temperature,
        "age": age,
        "gender": gender,
    }

    best_outfit = run_genetic_algorithm(user_inputs, user_wardrobe,
                                        population_size, num_generations, mutation_rate, crossover_rate, patience)
    return best_outfit

def get_user_wardrobe_by_domain(domain_name, user_access_token):
    headers = {
        'Authorization': f'Bearer {user_access_token}'
    }
    if not domain_name.endswith('/'):
        domain_name += '/'

    url = domain_name + 'api/my-clothingitems'
    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        return response.json()['data']
    else:
        return None

def user_wardrobe_check(user_wardrobe, user_inputs):
    wardrobe_categories = {item.category_group for item in user_wardrobe}
    gender = (user_inputs.get("gender") or "").strip().lower()

    OUTFIT_STRUCTURE_RULES = [
        {"Tops", "Bottoms", "Footwear"},
        {"Tops", "Skirts", "Footwear"},
        {"Dresses & Rompers", "Footwear"},
    ]

    # ---------- Non-beachwear ----------
    if user_inputs.get('occasion') != 'beachwear':
        if gender == 'female':
            # Any rule satisfied → OK
            if any(rule.issubset(wardrobe_categories) for rule in OUTFIT_STRUCTURE_RULES):
                return True, {}

            # Find the closest option with the fewest missing parts
            missing_by_option = []
            for rule in OUTFIT_STRUCTURE_RULES:
                missing = sorted(list(rule - wardrobe_categories))
                missing_by_option.append({
                    "option": sorted(list(rule)),
                    "missing": missing,
                    "missing_count": len(missing),
                })
            missing_by_option.sort(key=lambda x: x["missing_count"])
            best = missing_by_option[0]

            need_txt = ", ".join(best["missing"]) if best["missing"] else "nothing"
            msg = (
                "Your wardrobe is missing items to complete a valid outfit.\n"
                f"- Closest viable option requires adding: {need_txt}.\n"
                "- Accepted outfit paths: "
                "(Tops + Bottoms + Footwear) or (Tops + Skirts + Footwear) or (Dresses & Rompers + Footwear)."
            )
            return False, {
                "message": msg,
                "missing": best["missing"],
                "best_option": best["option"],
                "missing_by_option": missing_by_option,
            }

        else:
            # Male: must have (Tops + Bottoms + Footwear)
            rule = {"Tops", "Bottoms", "Footwear"}
            if rule.issubset(wardrobe_categories):
                return True, {}

            missing = sorted(list(rule - wardrobe_categories))
            need_txt = ", ".join(missing) if missing else "nothing"
            msg = f"Required set is (Tops + Bottoms + Footwear). Missing: {need_txt}."
            return False, {
                "message": msg,
                "missing": missing,
                "best_option": sorted(list(rule)),
                "missing_by_option": [
                    {"option": sorted(list(rule)), "missing": missing, "missing_count": len(missing)}
                ],
            }

    # ---------- Beachwear ----------
    else:
        def has_cat(name):
            target = (name or "").strip().lower()
            return any((it.category or "").strip().lower() == target for it in user_wardrobe)

        missing = []

        sandals_ok =  has_cat("Flip-flops")
        if not sandals_ok:
            missing.append("Flip-flops")

        if gender == "female":
            has_one_piece = has_cat("One-piece swimsuit")
            has_bra = has_cat("Bra")
            has_panty = has_cat("Panty")
            underwear_ok = has_bra and has_panty

            if not (underwear_ok or has_one_piece):
                # Be precise if only one of bra/panty is missing
                if has_bra and not has_panty:
                    missing.append("Panty")
                elif has_panty and not has_bra:
                    missing.append("Bra")
                else:
                    missing.append("Bikini or One-piece swimsuit")

        elif gender == "male":
            if not has_cat("Shorts"):
                missing.append("Shorts")

        if not missing:
            return True, {}

        msg = "Beachwear requirements missing: " + ", ".join(missing) + "."
        return False, {"message": msg, "missing": missing}


# base_url = "https://2afeef25fc94.ngrok-free.app"
base_url = os.getenv('BASE_URL', 'http://127.0.0.1:8000')

def _make_api_call(endpoint, access_token):
    url = f'{base_url}{endpoint}'
    headers = {
        'Authorization': f'Bearer {access_token}'
    }
    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error fetching data from {url}: {e}")
        return None

def get_user_wardrobe(access_token):
    response_data = _make_api_call('/api/my-clothingitems', access_token)
    return response_data['data'] if response_data else []

def get_user_details(access_token):
    response_data = _make_api_call('/api/users', access_token)
    if response_data:
        birthday_str = response_data.get('birthday')
        age = None
        if birthday_str:
            birth_date = datetime.fromisoformat(birthday_str.replace('Z', '+00:00')).date()
            today = date.today()
            age = today.year - birth_date.year - ((today.month, today.day) < (birth_date.month, birth_date.day))
        gender = response_data.get('gender')
        if isinstance(gender, str):
            gender = gender.strip().lower()
        return {'age': age, 'gender': gender}
    return {'age': None, 'gender': None}

def _process_wardrobe_data(user_wardrobe):
    clothing_items = []
    for item_dict in user_wardrobe:
        if item_dict.get('description'):
            item_dict.pop('description', None)
        item = ClothingItem(
            id=item_dict.get('id'),
            user_id=item_dict.get('user_id'),
            image_url=item_dict.get('image_url'),
            category_group=item_dict.get('category_group'),
            category=item_dict.get('category'),
            color_group=item_dict.get('color_group'),
            sleeve=item_dict.get('sleeve'),
            neckline=item_dict.get('neckline'),
            fit=item_dict.get('fit'),
            length=item_dict.get('length'),
            closure=item_dict.get('closure'),
            pattern=item_dict.get('pattern'),
            material=item_dict.get('material'),
            style=item_dict.get('style'),
            insulation=item_dict.get('insulation'),
            category_type=item_dict.get('type'),
            height=item_dict.get('height'),
            toe=item_dict.get('toe'),
            penalty=item_dict.get('penalty', 0),
            static_value=item_dict.get('static_value', 100)
        )
        clothing_items.append(item)
    return clothing_items

def user_wardrobe_check(user_wardrobe, user_inputs):
    wardrobe_categories = {item.category_group for item in user_wardrobe}
    gender = (user_inputs.get("gender") or "").strip().lower()

    OUTFIT_STRUCTURE_RULES = [
        {"Tops", "Bottoms", "Footwear"},
        {"Tops", "Skirts", "Footwear"},
        {"Dresses & Rompers", "Footwear"},
    ]

    # ---------- Non-beachwear ----------
    if user_inputs.get('occasion') != 'beachwear':
        if gender == 'female':
            # Any rule satisfied → OK
            if any(rule.issubset(wardrobe_categories) for rule in OUTFIT_STRUCTURE_RULES):
                return True, {}

            # Find the closest option with the fewest missing parts
            missing_by_option = []
            for rule in OUTFIT_STRUCTURE_RULES:
                missing = sorted(list(rule - wardrobe_categories))
                missing_by_option.append({
                    "option": sorted(list(rule)),
                    "missing": missing,
                    "missing_count": len(missing),
                })
            missing_by_option.sort(key=lambda x: x["missing_count"])
            best = missing_by_option[0]

            need_txt = ", ".join(best["missing"]) if best["missing"] else "nothing"
            msg = (
                "Your wardrobe is missing items to complete a valid outfit.\n"
                f"- Closest viable option requires adding: {need_txt}.\n"
                "- Accepted outfit paths: "
                "(Tops + Bottoms + Footwear) or (Tops + Skirts + Footwear) or (Dresses & Rompers + Footwear)."
            )
            return False, {
                "message": msg,
                "missing": best["missing"],
                "best_option": best["option"],
                "missing_by_option": missing_by_option,
            }

        else:
            # Male: must have (Tops + Bottoms + Footwear)
            rule = {"Tops", "Bottoms", "Footwear"}
            if rule.issubset(wardrobe_categories):
                return True, {}

            missing = sorted(list(rule - wardrobe_categories))
            need_txt = ", ".join(missing) if missing else "nothing"
            msg = f"Required set is (Tops + Bottoms + Footwear). Missing: {need_txt}."
            return False, {
                "message": msg,
                "missing": missing,
                "best_option": sorted(list(rule)),
                "missing_by_option": [
                    {"option": sorted(list(rule)), "missing": missing, "missing_count": len(missing)}
                ],
            }

    # ---------- Beachwear ----------
    else:
        def has_cat(name):
            target = (name or "").strip().lower()
            return any((it.category or "").strip().lower() == target for it in user_wardrobe)

        missing = []

        sandals_ok =  has_cat("Flip-flops")
        if not sandals_ok:
            missing.append("Flip-flops")

        if gender == "female":
            has_one_piece = has_cat("One-piece swimsuit")
            has_bra = has_cat("Bra")
            has_panty = has_cat("Panty")
            underwear_ok = has_bra and has_panty

            if not (underwear_ok or has_one_piece):
                # Be precise if only one of bra/panty is missing
                if has_bra and not has_panty:
                    missing.append("Panty")
                elif has_panty and not has_bra:
                    missing.append("Bra")
                else:
                    missing.append("Bikini or One-piece swimsuit")

        elif gender == "male":
            if not has_cat("Shorts"):
                missing.append("Shorts")

        if not missing:
            return True, {}

        msg = "Beachwear requirements missing: " + ", ".join(missing) + "."
        return False, {"message": msg, "missing": missing}


# =========================
# POSTPROCESS (Fixed & Generalized)
# =========================
def postprocess_outfit(data: dict, wardrobe: list = None, strict=None) -> dict:
    """
    Final pass (priority = OCCASION):
    - wedding/formal: يمنع تماماً الأحذية غير الرسمية (Sneakers/Sandals/Flip-flops/Rain boots).
      إن ما توفّر البديل من الخزانة → gap بدون تنزيل المناسبة.
    - wedding/formal + برد: Outerwear خفيف (Blazer/Coat…) وإن في فستان والطقس بارد → Tights لو متوفّر.
    - مطر: يمنع سويد على القدم ويبدّل من الخزانة عند الإمكان.
    - ties فقط مع Button-down/Dress shirt.
    - Headwear منطقي فقط (ثلج=Beanie، رياضة=Headband/Cap، Beach حار=Sun hat).
    - لا نعمل downgrade للمناسبة الرسمية بسبب نقص عنصر، بنسجّل gap ونحافظ على delivered_occasion.
    """
    import copy

    items  = copy.deepcopy(data.get("items", [])) or []
    layers = {str(k): v for k, v in (data.get("layers") or {}).items() if v in ("inner","outer","accessory")}
    weather   = (data.get("weather") or "").strip().lower()
    occasion  = (data.get("occasion") or "").strip().lower()
    gender    = (data.get("gender") or "").strip().lower()
    temp_input = data.get("temperature")
    wardrobe = wardrobe or []

    meta = {
        "requested_occasion": occasion,
        "delivered_occasion": occasion,
        "gaps": [],
        "substitutions": [],
        "warnings": []
    }

    # --- temperature number
    def band_to_c(b):
        m = {
            "extreme_cold": -10.0, "cold": 0.0, "cool": 8.0,
            "mild": 18.0, "warm": 26.0, "hot": 33.0, "extreme_hot": 42.0
        }
        return m.get(str(b).lower(), 18.0)

    try:
        t_c = float(temp_input)
    except (TypeError, ValueError):
        t_c = band_to_c(temp_input)

    # --- helpers
    def is_group(it, g): return (it.get("category_group","").strip().lower() == g.strip().lower())
    def cat(it): return (it.get("category") or "").strip()
    def cat_l(it): return cat(it).lower()

    def find_in_wardrobe(group=None, category=None, material=None, contains=None):
        for w in wardrobe:
            if group and (w.get("category_group","").lower() != group.lower()): continue
            if category and (w.get("category","").lower() != category.lower()): continue
            if material and (w.get("material","").lower() != material.lower()): continue
            if contains and contains not in w.get("category","").lower(): continue
            return copy.deepcopy(w)
        return None

    vseq = {"n": 0}
    def next_id(prefix="virt"): vseq["n"] += 1; return f"{prefix}-{vseq['n']}"
    def ensure_id(d):
        if d.get("id") is None:
            d["id"] = next_id(cat_l(d) or "item")
        else:
            d["id"] = str(d["id"])
        return d

    def add_from_wardrobe_or_gap(proto, layer=None, why=None):
        nonlocal items
        cand = find_in_wardrobe(proto.get("category_group"), proto.get("category"))
        if cand:
            ensure_id(cand)
            if not any(str(x.get("id")) == str(cand["id"]) for x in items):
                items.append(cand)
            if layer: layers[str(cand["id"])] = layer
            if why: meta["substitutions"].append(why)
        else:
            meta["gaps"].append((proto.get("category") or proto.get("category_group") or "item") + (f" — {why}" if why else ""))

    def remove_where(pred):
        nonlocal items
        ids_to_remove = {str(it.get("id")) for it in items if pred(it)}
        if not ids_to_remove: return
        items = [it for it in items if str(it.get("id")) not in ids_to_remove]
        for rid in list(layers.keys()):
            if rid in ids_to_remove:
                layers.pop(rid, None)

    # ========== طقس ==========
    if weather in ("rainy","snowy"):
        # لا نظارات شمس
        remove_where(lambda it: is_group(it,"Eyewear") and cat_l(it)=="sunglasses")

    if weather == "rainy":
        if not any(is_group(it,"Outerwear") and cat_l(it) in {"raincoat","trench coat","windbreaker jacket"} for it in items):
            add_from_wardrobe_or_gap({"category_group":"Outerwear","category":"Raincoat"}, "outer", "rain outerwear")
        if not any(is_group(it,"Other Accessories") and cat_l(it)=="umbrella" for it in items):
            add_from_wardrobe_or_gap({"category_group":"Other Accessories","category":"Umbrella"}, "accessory", "umbrella")

    # حرارة: شيل غير اللازم
    remove_where(lambda it: t_c > 12 and is_group(it,"Handwear") and cat_l(it)=="gloves")
    remove_where(lambda it: t_c > 15 and ((is_group(it,"Neckwear") and cat_l(it)=="scarf") or (is_group(it,"Headwear") and cat_l(it)=="beanie hat")))
    if t_c >= 26:
        remove_where(lambda it: is_group(it,"Outerwear"))

    # ========== مناسبات رسمية ==========
    tees_like   = {"t-shirt","tank top","henley shirt","sleeveless top"}
    polos_like  = {"polo shirt"}
    shirts_formal = {"button-down shirt","dress shirt"}
    shirts_like = shirts_formal | {"silk blouse","turtleneck","blouse"}
    formal_bottoms = {"dress pants","suit pants","pencil skirt","slacks"}

    if occasion in ("formal","wedding"):
        # شيل أي T-shirt/Bolo إن وجدت
        remove_where(lambda it: is_group(it,"Tops") and (cat_l(it) in tees_like or cat_l(it) in polos_like))

        # في فستان؟ إذًا ما في قميص تحته. منسمح بس بالطبقة الخارجية (بلايزر/كارديغان).
        if any(is_group(it,"Dresses & Rompers") for it in items):
            remove_where(lambda it: is_group(it,"Tops")
                         and layers.get(str(it.get("id"))) != "outer")

        # حاول تأمين قميص رسمي — إلا إذا في فستان، القميص ما بينلبس تحت الفستان
        wearing_dress = any(is_group(it,"Dresses & Rompers") for it in items)
        has_formal_shirt = any(is_group(it,"Tops") and cat_l(it) in shirts_formal for it in items)
        if not has_formal_shirt and not wearing_dress:
            wshirt = (find_in_wardrobe("Tops","Button-down shirt") or find_in_wardrobe("Tops","Dress shirt"))
            if wshirt:
                ensure_id(wshirt)
                items.append(wshirt); layers[str(wshirt["id"])] = "inner"
                meta["substitutions"].append("Added formal shirt (wardrobe)")
            else:
                meta["gaps"].append("Dress shirt")

        # بنطال/تنورة/فستان مناسب
        has_formal_bottom = any(is_group(it,"Bottoms") and cat_l(it) in formal_bottoms for it in items) or \
                            any(is_group(it,"Skirts") and cat_l(it) == "pencil skirt" for it in items) or \
                            any(is_group(it,"Dresses & Rompers") for it in items)
        if not has_formal_bottom:
            repl = (find_in_wardrobe("Bottoms","Dress pants") or
                    find_in_wardrobe("Bottoms","Trousers") or
                    find_in_wardrobe("Skirts","Pencil skirt") or
                    find_in_wardrobe("Dresses & Rompers","Evening gown") or
                    find_in_wardrobe("Dresses & Rompers","Cocktail dress"))
            if repl:
                ensure_id(repl); items.append(repl)
                meta["substitutions"].append("Added formal bottom/dress (wardrobe)")
            else:
                meta["gaps"].append("Dress pants / Pencil skirt / Formal dress")

        # أحذية: لازم Pumps للأنثى، Oxford/Dress لغير ذلك
        # امسح أي غير رسمي
        remove_where(lambda it: is_group(it,"Footwear") and cat_l(it) in {"sneakers","sandals","flip-flops","rain boots"})
        if not any(is_group(it,"Footwear") for it in items):
            want = "Heel pumps" if gender == "female" else "Oxford dress shoes"
            repl = find_in_wardrobe("Footwear", want) or (find_in_wardrobe("Footwear","Dress shoe") if gender != "female" else None)
            if repl and not (weather == "rainy" and (repl.get("material","").lower()=="suede")):
                items.append(ensure_id(repl))
                meta["substitutions"].append("Added formal footwear (wardrobe)")
            else:
                meta["gaps"].append("Formal leather shoes" + (" (Pumps)" if gender=="female" else " (Oxford)"))

        # برد: Outerwear خفيف + Tights مع فستان
        if t_c <= 15 and not any(is_group(it,"Outerwear") for it in items):
            ow = (find_in_wardrobe("Outerwear","Blazer") or
                  find_in_wardrobe("Outerwear","Coat") or
                  find_in_wardrobe("Outerwear","Trench coat") or
                  find_in_wardrobe("Outerwear","Peacoat"))
            if ow:
                items.append(ensure_id(ow)); layers[str(ow["id"])] = "outer"
                meta["substitutions"].append("Added light outerwear (wardrobe)")
            else:
                meta["gaps"].append("Light outerwear (Blazer/Coat)")

    # مطر + سويد على القدم → بدّل
    if weather == "rainy":
        swapped = False
        for i, it in enumerate(list(items)):
            if is_group(it,"Footwear") and it.get("material","").lower() == "suede":
                repl = None
                if occasion in ("formal","wedding"):
                    repl = find_in_wardrobe("Footwear","Heel pumps") if gender=="female" else find_in_wardrobe("Footwear","Oxford dress shoes")
                    if repl and repl.get("material","").lower()=="suede":
                        repl = None
                if not repl and occasion not in ("formal","wedding"):
                    repl = find_in_wardrobe("Footwear","Sneakers")
                if repl:
                    items[i] = ensure_id(repl)
                    meta["substitutions"].append("Replaced suede in rain (wardrobe)")
                    swapped = True
        if not swapped and any(is_group(it,"Footwear") and it.get("material","").lower()=="suede" for it in items):
            meta["warnings"].append("Suede shoes in rain — risk of damage")

    # Headwear منطقي فقط
    for it in list(items):
        if not is_group(it,"Headwear"): continue
        name = cat_l(it)
        ok = False
        if weather == "snowy" and name == "beanie hat": ok = True
        elif occasion == "sport" and name in {"headband","baseball cap"}: ok = True
        elif occasion == "beachwear" and t_c >= 26 and name == "sun hat": ok = True
        if not ok:
            remove_where(lambda x: str(x.get("id")) == str(it.get("id")))
            meta["warnings"].append(f"Removed headwear ({cat(it)}) — not suitable")

    # ties فقط مع قميص رسمي
    if any(is_group(it,"Neckwear") and cat_l(it) in {"neck tie","bow tie"} for it in items):
        has_strict_shirt = any(is_group(it,"Tops") and cat_l(it) in {"button-down shirt","dress shirt"} for it in items)
        if not has_strict_shirt:
            remove_where(lambda it: is_group(it,"Neckwear") and cat_l(it) in {"neck tie","bow tie"})
            meta["warnings"].append("Removed tie/bow tie (no formal shirt)")

    # إعادة بناء layers
    new_layers = {}
    tees_like_set   = {"t-shirt","tank top","henley shirt","sleeveless top"}
    shirts_like_set = {"button-down shirt","dress shirt","silk blouse","turtleneck","blouse"}
    tee_ids   = {str(it.get("id")) for it in items if is_group(it,"Tops") and cat_l(it) in tees_like_set}
    shirt_ids = {str(it.get("id")) for it in items if is_group(it,"Tops") and cat_l(it) in shirts_like_set}

    for it in items:
        gid = str(it.get("id") or next_id("item"))
        it["id"] = gid
        if is_group(it,"Outerwear"):
            new_layers[gid] = "outer"
        elif is_group(it,"Tops"):
            if tee_ids and shirt_ids and gid in shirt_ids:
                new_layers[gid] = "outer"
            else:
                new_layers[gid] = "inner"
        elif is_group(it,"Eyewear") or is_group(it,"Other Accessories") or \
             is_group(it,"Neckwear") or is_group(it,"Handwear") or \
             is_group(it,"Wristwear") or is_group(it,"Headwear") or \
             is_group(it,"Bags"):
            new_layers[gid] = "accessory"

    return {
        "weather": weather,
        "occasion": meta["delivered_occasion"],
        "temperature": data.get("temperature"),
        "age": data.get("age"),
        "gender": gender,
        "items": items,
        "layers": new_layers,
        "meta": meta
    }


def get_recommended_outfit(weather, temperature, occasion, access_token):
    user_details = get_user_details(access_token)
    user_wardrobe_raw = get_user_wardrobe(access_token)
    clothing_items_wardrobe = _process_wardrobe_data(user_wardrobe_raw)
    weather_norm = {"sunny": "clear"}.get((weather or "").strip().lower(), weather)

    user_inputs = {
        "occasion": occasion,
        "gender": user_details['gender'],
    }
    action, message = user_wardrobe_check(clothing_items_wardrobe, user_inputs)
    if not action:
        return message

    # liked_user_outfits_dict = get_liked_user_outfits(access_token)
    # disliked_user_outfits_dict = get_disliked_user_outfits(access_token)
    if user_details['age'] is None or user_details['gender'] is None or user_wardrobe_raw == [] or clothing_items_wardrobe == []:
        return {'message': 'something went wrong try again later'}
    # liked_user_outfits = []
    # for outfit in liked_user_outfits_dict:
    #     liked_user_outfits.append(_dict_to_outfit(outfit))
    # disliked_user_outfits = []
    # for outfit in disliked_user_outfits_dict:
    #     disliked_user_outfits.append(_dict_to_outfit(outfit))
    recommended_outfit = generate_outfit_recommendation(
        weather=weather,
        occasion=occasion,
        temperature=temperature,
        age=user_details.get('age'),
        gender=user_details.get('gender'),
        user_wardrobe=clothing_items_wardrobe,
        # liked_outfits=liked_user_outfits,
        # disliked_outfits=disliked_user_outfits,
        patience=50
    )

    initial_layers = {}
    for it in recommended_outfit.items:
        gid = str(it.id)
        lay = recommended_outfit.layers.get(it.id)
        if lay in ("inner","outer","accessory"):
            initial_layers[gid] = lay
        else:
            if it.category_group == "Outerwear":
                initial_layers[gid] = "outer"
            elif it.category_group == "Tops":
                initial_layers[gid] = "inner"

    id_to_raw = {w['id']: w for w in user_wardrobe_raw}
    clothings = []
    for outfit_item in recommended_outfit.items:
        raw = id_to_raw.get(outfit_item.id)
        if raw:
            clothings.append(raw)

    data = {
        'weather': weather,
        'occasion': occasion,
        'temperature': temperature,
        'age': user_details.get('age'),
        'gender': user_details.get('gender'),
        'items': clothings,
        'layers': initial_layers,
    }
    data = postprocess_outfit(data, user_wardrobe_raw, True)
    data['occasion'] = data['meta']['delivered_occasion']
    data ['gaps'] = data['meta']['gaps']
    data['suggests'] = data['meta']['substitutions']
    data['warnings'] = data['meta']['warnings']
    del  data['meta']
    return data



# Manual smoke test — supply a real Sanctum token via the environment:
#   export TEST_SANCTUM_TOKEN=...
# token = os.getenv('TEST_SANCTUM_TOKEN')
# wardrobe_raw = get_user_wardrobe(token)
# data = get_recommended_outfit('rainy', 15, 'casual', token)


# print(data)
# images_urls = []
# if data:
#     print("\n--- Images Outfit 5 Items ---")
#     for item in data["items"]:
#         print(item["image_url"])
#         images_urls.append(item["image_url"])
# download_and_plot_images(images_urls, token)


# import requests
# from PIL import Image
# from io import BytesIO
# import math
# import time
# import matplotlib.pyplot as plt
# import os

# os.makedirs("test_outfits", exist_ok=True)

# TEMP_RANGES = {
#     "extreme_cold": (-15, -4),
#     "cold": (-3, 5),
#     "cool": (6, 12),
#     "mild": (13, 20),
#     "warm": (21, 28),
#     "hot": (29, 36),
#     "extreme_hot": (37, 55)
# }

# weathers = ["clear", "snowy", "cloudy", "rainy"]
# occasions = ["casual", "formal", "sport", "party", "wedding"]

# token = os.getenv('TEST_SANCTUM_TOKEN')

# # Call this once if needed (assuming it's required for the recommendations)
# wardrobe_raw = get_user_wardrobe(token)

# def download_and_save_images(image_urls, access_token, plot_title="Clothing Items", filename="outfit.png"):
#     headers = {'Authorization': f'Bearer {access_token}'}
#     downloaded_images = []

#     for url in image_urls:
#         attempts = 0
#         while attempts < 5:
#             try:
#                 resp = requests.get(url, headers=headers, timeout=10)
#                 resp.raise_for_status()
#                 img = Image.open(BytesIO(resp.content))
#                 downloaded_images.append(img)
#                 break
#             except requests.exceptions.RequestException:
#                 attempts += 1
#                 time.sleep(2)

#     if not downloaded_images:
#         return

#     num_images = len(downloaded_images)
#     num_cols = math.ceil(math.sqrt(num_images))
#     num_rows = math.ceil(num_images / num_cols)

#     fig, axes = plt.subplots(num_rows, num_cols, figsize=(num_cols * 4, num_rows * 4))
#     if num_images == 1:
#         axes = [axes]
#     else:
#         axes = axes.flatten()

#     for i, image in enumerate(downloaded_images):
#         axes[i].imshow(image)
#         axes[i].axis('off')
#     for j in range(i + 1, len(axes)):
#         axes[j].axis('off')

#     fig.suptitle(plot_title, fontsize=16)
#     plt.tight_layout(rect=[0, 0.03, 1, 0.95])
#     plt.savefig(filename)
#     plt.close(fig)

# for weather in weathers:
#     for occasion in occasions:
#         for temp_key, (min_temp, max_temp) in TEMP_RANGES.items():
#             temp = (min_temp + max_temp) // 2  # Midpoint temperature
#             for i in range(1, 4):  # Run 3 times: 1, 2, 3
#                 data = get_recommended_outfit(weather, temp, occasion, token)
#                 if data and "items" in data:
#                     images_urls = [item["image_url"] for item in data["items"]]
#                     filename = f"test_outfits/{weather}_{occasion}_{temp_key}_{i}.png"
#                     download_and_save_images(images_urls, token, plot_title="Clothing Items", filename=filename)

        
import requests
import os
import tempfile
import uuid
import base64
import time
from pyngrok import ngrok, conf
from flask import Flask, request, jsonify

# Credentials come from the environment, never from source. Set them in a
# local .env (which is gitignored) or export them before running:
#   export NGROK_AUTH_TOKEN=...
NGROK_AUTH_TOKEN = os.getenv("NGROK_AUTH_TOKEN")
if NGROK_AUTH_TOKEN:
    conf.get_default().auth_token = NGROK_AUTH_TOKEN
else:
    print("NGROK_AUTH_TOKEN is not set — starting without an ngrok tunnel.")

LARAVEL_URL = os.getenv("LARAVEL_URL", "http://127.0.0.1:8000")
base_url = LARAVEL_URL

# Default suits Linux/Colab; override on Windows with NGROK_PATH.
ngrok_executable_path = os.getenv("NGROK_PATH", "/usr/local/bin/ngrok2")
conf.get_default().ngrok_path = ngrok_executable_path
print(f"Using ngrok executable from: {ngrok_executable_path}")


app = Flask(__name__)

ALLOWED_WEATHER = ["clear", "snowy", "cloudy", "rainy"]
ALLOWED_OCCASION = ["casual", "formal", "sport", "party", "wedding"]


@app.route('/generate-outfit', methods=['POST'])
def generate_outfit():
    try:
        data = request.get_json()

        if not data:
            return jsonify({"error": "Request body must be valid JSON"}), 400

        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({"error": "Missing or invalid Authorization header"}), 401

        access_token = auth_header.split(' ')[1]
        temperature_float = data.get('temperature')
        weather = data.get('weather')
        occasion = data.get('occasion')

        if not all([access_token, temperature_float is not None, weather, occasion]):
            return jsonify({"error": "Missing required fields in request: 'access_token', 'temperature', 'weather', or 'occasion'"}), 400

        try:
            temperature = int(float(temperature_float))
        except (ValueError, TypeError):
            return jsonify({"error": "Temperature must be a valid number"}), 400

        if weather not in ALLOWED_WEATHER:
            return jsonify({"error": f"Invalid weather value. Allowed values are: {ALLOWED_WEATHER}"}), 400

        if occasion not in ALLOWED_OCCASION:
            return jsonify({"error": f"Invalid occasion value. Allowed values are: {ALLOWED_OCCASION}"}), 400

        outfit_data = get_recommended_outfit(weather, temperature, occasion, access_token)

        return jsonify(outfit_data), 200

    except Exception as e:
        print(f"An error occurred: {e}")
        return jsonify({"error": "An internal server error occurred"}), 500

def run_flask_app():
    port = 5002
    try:
        
        # ngrok.kill()
        # public_url = ngrok.connect(port)
        # print(f" * Ngrok Tunnel URL: {public_url}")
        # print(f" * Flask app running on http://127.0.0.1:{port}")
        app.run(host='0.0.0.0', port=port, debug=False, use_reloader=False)  # Add host='0.0.0.0'
    except Exception as e:
        print(f"Error starting ngrok or Flask app: {e}")
    # finally:
        # ngrok.disconnect()

if __name__ == '__main__':
    run_flask_app()
