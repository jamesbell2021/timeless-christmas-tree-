class_name Catalogue
extends RefCounted
## Catalogue — the data definition of every decoration in the trunk.
##
## Data-driven by design: adding an ornament means adding one dictionary
## here and (if it needs a new look) one draw routine in DecorArt. Nothing
## else in the game needs to change.
##
## kind:
##   "hang"    — hangs from a branch on a thread; swings
##   "clip"    — clipped upright onto a branch (candles, glass birds)
##   "topper"  — sits on the apex of the tree (only one)
##   "garland" — a swag between two points on the tree
##   "room"    — placed in the parlour; uses `zone`
## zone (room items): "mantel_garland", "hooks", "floor", "surface", "wall", "ceiling"
## rect: hit/draw bounds relative to the item's anchor point.

const TABS := [
	{"id": "lights", "title": "Candles & Lights", "icon": "candle"},
	{"id": "glass", "title": "Blown Glass", "icon": "bauble"},
	{"id": "paper", "title": "Paper, Fruit & Sweets", "icon": "paper"},
	{"id": "garlands", "title": "Garlands & Chains", "icon": "garland"},
	{"id": "toppers", "title": "Tree Toppers", "icon": "topper"},
	{"id": "room", "title": "For the Parlour", "icon": "room"},
]

const RED := Color(0.72, 0.07, 0.09)
const GOLD := Color(0.9, 0.68, 0.24)
const SILVER := Color(0.8, 0.83, 0.88)
const GREEN := Color(0.1, 0.42, 0.22)
const BLUE := Color(0.14, 0.28, 0.66)
const AMETHYST := Color(0.44, 0.18, 0.52)

static var _items: Dictionary = {}
static var _order: Array = []


static func _add(d: Dictionary) -> void:
	_items[d["id"]] = d
	_order.append(d["id"])


static func _ensure() -> void:
	if not _items.is_empty():
		return
	# ---------------------------------------------------------- candles & lights
	_add({"id": "candle_white", "name": "Clip-on Candle (White)", "tab": "lights", "kind": "clip", "draw": "candle",
		"color": Color(0.95, 0.93, 0.86), "light": true, "sound": "wood", "rect": Rect2(-10, -44, 20, 52),
		"desc": "Tin clip-holders let real candles stand upright on the boughs. Lit only under a watchful eye!"})
	_add({"id": "candle_red", "name": "Clip-on Candle (Red)", "tab": "lights", "kind": "clip", "draw": "candle",
		"color": Color(0.7, 0.09, 0.1), "light": true, "sound": "wood", "rect": Rect2(-10, -44, 20, 52),
		"desc": "Coloured tapers were a small Edwardian luxury."})
	_add({"id": "candle_beeswax", "name": "Beeswax Candle", "tab": "lights", "kind": "clip", "draw": "candle",
		"color": Color(0.93, 0.78, 0.45), "light": true, "sound": "wood", "rect": Rect2(-10, -44, 20, 52),
		"desc": "Beeswax burns sweeter and brighter than tallow."})
	_add({"id": "electric_lights", "name": "Electric Fairy Lamps", "tab": "lights", "kind": "garland", "draw": "electric",
		"color": Color(0.95, 0.75, 0.3), "light": true, "sound": "glass", "rect": Rect2(-24, -24, 48, 48),
		"desc": "A marvel of the new century: a string of tiny coloured electric bulbs."})
	# -------------------------------------------------------------- blown glass
	for b in [["red", "Crimson", RED], ["gold", "Gilt", GOLD], ["silver", "Silvered", SILVER],
			["green", "Bottle-Green", GREEN], ["blue", "Cobalt", BLUE], ["amethyst", "Amethyst", AMETHYST]]:
		_add({"id": "bauble_" + b[0], "name": "%s Glass Bauble" % b[1], "tab": "glass", "kind": "hang", "draw": "bauble",
			"color": b[2], "sound": "glass", "rect": Rect2(-18, 0, 36, 46),
			"desc": "Hand-blown and silvered inside, in the German manner of Lauscha."})
	_add({"id": "teardrop_gold", "name": "Gilt Teardrop", "tab": "glass", "kind": "hang", "draw": "teardrop",
		"color": GOLD, "sound": "glass", "rect": Rect2(-14, 0, 28, 58), "desc": "A slender drop of golden glass."})
	_add({"id": "teardrop_red", "name": "Ruby Teardrop", "tab": "glass", "kind": "hang", "draw": "teardrop",
		"color": RED, "sound": "glass", "rect": Rect2(-14, 0, 28, 58), "desc": "Catches candlelight like a ruby."})
	_add({"id": "icicle", "name": "Glass Icicle", "tab": "glass", "kind": "hang", "draw": "icicle",
		"color": Color(0.85, 0.93, 1.0), "sound": "glass", "rect": Rect2(-8, 0, 16, 70), "desc": "Twisted clear glass, cold as a winter window."})
	_add({"id": "glass_bird", "name": "Clip-on Glass Bird", "tab": "glass", "kind": "clip", "draw": "bird",
		"color": Color(0.85, 0.75, 0.55), "sound": "glass", "rect": Rect2(-30, -30, 62, 40),
		"desc": "With a tail of spun glass. A bird in the tree was said to bring good fortune."})
	_add({"id": "pinecone", "name": "Glass Pine Cone", "tab": "glass", "kind": "hang", "draw": "pinecone",
		"color": Color(0.62, 0.42, 0.2), "sound": "glass", "rect": Rect2(-13, 0, 26, 52), "desc": "Moulded glass, dusted with gold."})
	_add({"id": "kugel_grapes", "name": "Grape Cluster Kugel", "tab": "glass", "kind": "hang", "draw": "grapes",
		"color": AMETHYST.lightened(0.1), "sound": "glass", "rect": Rect2(-18, 0, 36, 58), "desc": "Heavy, old-fashioned and much treasured."})
	# ------------------------------------------------------ paper, fruit & sweets
	_add({"id": "dresden_star", "name": "Dresden Paper Star", "tab": "paper", "kind": "hang", "draw": "dresden_star",
		"color": GOLD, "sound": "paper", "rect": Rect2(-22, 0, 44, 50), "desc": "Embossed gilt card, pressed in Dresden."})
	_add({"id": "cornucopia", "name": "Cornucopia of Sweets", "tab": "paper", "kind": "hang", "draw": "cornucopia",
		"color": Color(0.85, 0.35, 0.45), "sound": "paper", "rect": Rect2(-18, 0, 36, 60), "desc": "A paper cone filled with sugared almonds."})
	_add({"id": "scrap_angel", "name": "Scrap Angel", "tab": "paper", "kind": "hang", "draw": "scrap_angel",
		"color": Color(0.95, 0.85, 0.75), "sound": "paper", "rect": Rect2(-20, 0, 40, 58), "desc": "A chromolithograph 'scrap', cut out and treasured."})
	_add({"id": "paper_fan", "name": "Paper Fan", "tab": "paper", "kind": "hang", "draw": "fan",
		"color": Color(0.2, 0.45, 0.5), "sound": "paper", "rect": Rect2(-24, 0, 48, 40), "desc": "Pleated and painted with tiny flowers."})
	_add({"id": "candy_cane", "name": "Peppermint Cane", "tab": "paper", "kind": "hang", "draw": "candy_cane",
		"color": Color(0.85, 0.1, 0.12), "sound": "paper", "rect": Rect2(-14, -4, 26, 62), "desc": "Red-striped canes were the very latest thing."})
	_add({"id": "gingerbread", "name": "Gingerbread Heart", "tab": "paper", "kind": "hang", "draw": "gingerbread",
		"color": Color(0.55, 0.3, 0.13), "sound": "paper", "rect": Rect2(-20, 0, 40, 46), "desc": "Iced by the children on Christmas Eve."})
	_add({"id": "apple", "name": "Red Apple", "tab": "paper", "kind": "hang", "draw": "apple",
		"color": Color(0.7, 0.1, 0.08), "sound": "soft", "rect": Rect2(-17, 0, 34, 44), "desc": "Apples were among the very first tree decorations."})
	_add({"id": "gilded_walnut", "name": "Gilded Walnut", "tab": "paper", "kind": "hang", "draw": "walnut",
		"color": GOLD, "sound": "wood", "rect": Rect2(-12, 0, 24, 34), "desc": "Brushed with gold leaf at the kitchen table."})
	_add({"id": "pomander", "name": "Clove Orange", "tab": "paper", "kind": "hang", "draw": "pomander",
		"color": Color(0.92, 0.5, 0.12), "sound": "soft", "rect": Rect2(-17, 0, 34, 46), "desc": "Studded with cloves and tied with ribbon. It smells of Christmas."})
	_add({"id": "sugar_mouse", "name": "Sugar Mouse", "tab": "paper", "kind": "hang", "draw": "sugar_mouse",
		"color": Color(0.97, 0.75, 0.8), "sound": "paper", "rect": Rect2(-22, 0, 44, 36), "desc": "Pink sugar with a string tail, a treat for the youngest."})
	# ------------------------------------------------------- garlands & chains
	_add({"id": "tinsel_gold", "name": "Gold Tinsel", "tab": "garlands", "kind": "garland", "draw": "tinsel",
		"color": GOLD, "sound": "tinsel", "rect": Rect2(-24, -24, 48, 48), "desc": "Real tinsel was once made of beaten silver."})
	_add({"id": "tinsel_silver", "name": "Silver Tinsel", "tab": "garlands", "kind": "garland", "draw": "tinsel",
		"color": SILVER, "sound": "tinsel", "rect": Rect2(-24, -24, 48, 48), "desc": "It shimmers whenever anyone walks by."})
	_add({"id": "popcorn", "name": "Popcorn String", "tab": "garlands", "kind": "garland", "draw": "popcorn",
		"color": Color(0.98, 0.95, 0.85), "sound": "paper", "rect": Rect2(-24, -24, 48, 48), "desc": "Threaded with a needle by the fire."})
	_add({"id": "cranberry", "name": "Cranberry Chain", "tab": "garlands", "kind": "garland", "draw": "cranberry",
		"color": Color(0.65, 0.05, 0.12), "sound": "paper", "rect": Rect2(-24, -24, 48, 48), "desc": "Bright red berries on cotton thread."})
	_add({"id": "glass_beads", "name": "Glass Bead Chain", "tab": "garlands", "kind": "garland", "draw": "beads",
		"color": GOLD, "sound": "glass", "rect": Rect2(-24, -24, 48, 48), "desc": "Gilt and coloured beads from Bohemia."})
	_add({"id": "paper_chain", "name": "Paper Chain", "tab": "garlands", "kind": "garland", "draw": "paper_chain",
		"color": RED, "sound": "paper", "rect": Rect2(-24, -24, 48, 48), "desc": "Glued loop by loop on a wet afternoon."})
	# ---------------------------------------------------------------- toppers
	_add({"id": "topper_angel", "name": "Wax Angel", "tab": "toppers", "kind": "topper", "draw": "angel",
		"color": Color(0.97, 0.94, 0.88), "sound": "paper", "rect": Rect2(-42, -92, 84, 98), "desc": "A wax-faced angel with gilt paper wings."})
	_add({"id": "topper_star", "name": "Gilded Star", "tab": "toppers", "kind": "topper", "draw": "star",
		"color": GOLD, "sound": "glass", "rect": Rect2(-42, -88, 84, 92), "desc": "Pressed tin, gilded and bright as the Star of Bethlehem."})
	_add({"id": "topper_spire", "name": "Glass Spire", "tab": "toppers", "kind": "topper", "draw": "spire",
		"color": Color(0.85, 0.2, 0.25), "sound": "glass", "rect": Rect2(-20, -110, 40, 114), "desc": "A blown-glass finial, silvered within."})
	_add({"id": "topper_rosette", "name": "Dresden Rosette", "tab": "toppers", "kind": "topper", "draw": "rosette",
		"color": GOLD, "sound": "paper", "rect": Rect2(-40, -82, 80, 86), "desc": "Layers of embossed gilt card, finely punched."})
	# --------------------------------------------------------------- the room
	_add({"id": "mantel_garland", "name": "Evergreen Mantel Garland", "tab": "room", "kind": "room", "zone": "mantel_garland",
		"draw": "mantel_garland", "color": GREEN, "sound": "paper", "rect": Rect2(-240, -10, 480, 70), "max": 1,
		"desc": "Holly, ivy and fir, swagged along the mantelpiece."})
	for st in [["red", "Red", Color(0.62, 0.08, 0.1)], ["green", "Green", Color(0.12, 0.32, 0.18)], ["cream", "Cream", Color(0.9, 0.85, 0.72)]]:
		_add({"id": "stocking_" + st[0], "name": "%s Knitted Stocking" % st[1], "tab": "room", "kind": "room", "zone": "hooks",
			"draw": "stocking", "color": st[2], "sound": "soft", "rect": Rect2(-24, -4, 56, 84),
			"desc": "Hung by the chimney with care."})
	_add({"id": "present_brown", "name": "Parcel in Brown Paper", "tab": "room", "kind": "room", "zone": "floor", "draw": "present",
		"color": Color(0.62, 0.45, 0.28), "accent": Color(0.85, 0.8, 0.65), "sound": "soft", "rect": Rect2(-38, -56, 76, 58),
		"desc": "Brown paper, tied up with string."})
	_add({"id": "present_red", "name": "Crimson Gift", "tab": "room", "kind": "room", "zone": "floor", "draw": "present",
		"color": Color(0.6, 0.07, 0.09), "accent": GOLD, "sound": "soft", "rect": Rect2(-34, -50, 68, 52), "desc": "With a gold ribbon and a sprig of holly."})
	_add({"id": "present_tartan", "name": "Tartan Box", "tab": "room", "kind": "room", "zone": "floor", "draw": "present_tartan",
		"color": Color(0.12, 0.25, 0.18), "accent": Color(0.7, 0.1, 0.1), "sound": "soft", "rect": Rect2(-42, -48, 84, 50), "desc": "Wrapped in a remnant of tartan."})
	_add({"id": "present_green", "name": "Tall Green Box", "tab": "room", "kind": "room", "zone": "floor", "draw": "present",
		"color": Color(0.1, 0.3, 0.2), "accent": Color(0.85, 0.12, 0.15), "sound": "soft", "rect": Rect2(-24, -76, 48, 78), "desc": "Something long and mysterious."})
	_add({"id": "candlestick", "name": "Brass Candlestick", "tab": "room", "kind": "room", "zone": "surface", "draw": "candlestick",
		"color": GOLD, "light": true, "sound": "wood", "rect": Rect2(-16, -88, 32, 90), "desc": "Polished brass, for the mantel or a side table."})
	_add({"id": "holly", "name": "Holly Sprig", "tab": "room", "kind": "room", "zone": "wall", "draw": "holly",
		"color": GREEN, "sound": "paper", "rect": Rect2(-34, -20, 68, 40), "desc": "Tucked behind a picture frame for luck."})
	_add({"id": "wreath", "name": "Holly Wreath", "tab": "room", "kind": "room", "zone": "wall", "draw": "wreath",
		"color": GREEN, "sound": "paper", "rect": Rect2(-52, -6, 104, 112), "desc": "A ring of holly with a crimson bow."})
	_add({"id": "mistletoe", "name": "Mistletoe Kissing Ball", "tab": "room", "kind": "room", "zone": "ceiling", "draw": "mistletoe",
		"color": Color(0.45, 0.58, 0.3), "sound": "paper", "rect": Rect2(-30, -30, 60, 70), "desc": "Mind where you stand..."})
	_add({"id": "teddy", "name": "Teddy Bear", "tab": "room", "kind": "room", "zone": "floor", "draw": "teddy",
		"color": Color(0.66, 0.46, 0.24), "sound": "soft", "rect": Rect2(-30, -74, 60, 76), "desc": "Brand new! Named for President Roosevelt in 1902."})
	_add({"id": "rocking_horse", "name": "Rocking Horse", "tab": "room", "kind": "room", "zone": "floor", "draw": "rocking_horse",
		"color": Color(0.9, 0.88, 0.82), "sound": "wood", "rect": Rect2(-62, -96, 124, 98), "desc": "Dapple-grey, with a real horsehair mane."})
	_add({"id": "soldier", "name": "Wooden Soldier", "tab": "room", "kind": "room", "zone": "floor", "draw": "soldier",
		"color": Color(0.7, 0.08, 0.1), "sound": "wood", "rect": Rect2(-16, -84, 32, 86), "desc": "A guardsman in a scarlet tunic."})
	_add({"id": "noahs_ark", "name": "Noah's Ark", "tab": "room", "kind": "room", "zone": "floor", "draw": "ark",
		"color": Color(0.5, 0.3, 0.15), "sound": "wood", "rect": Rect2(-58, -62, 116, 64), "desc": "A Sunday toy, with animals two by two."})
	_add({"id": "drum", "name": "Toy Drum", "tab": "room", "kind": "room", "zone": "floor", "draw": "drum",
		"color": Color(0.12, 0.2, 0.45), "sound": "wood", "rect": Rect2(-30, -48, 60, 50), "desc": "Rat-a-tat-tat, on Christmas morning."})
	_add({"id": "christmas_cards", "name": "Christmas Cards", "tab": "room", "kind": "room", "zone": "surface", "draw": "cards",
		"color": PAPER_COL, "sound": "paper", "rect": Rect2(-46, -50, 92, 52), "desc": "From aunts, cousins and old friends."})


const PAPER_COL := Color(0.94, 0.88, 0.75)


static func get_item(id: String) -> Dictionary:
	_ensure()
	return _items.get(id, {})


static func has_item(id: String) -> bool:
	_ensure()
	return _items.has(id)


static func items_in_tab(tab: String) -> Array:
	_ensure()
	var out: Array = []
	for id in _order:
		if _items[id]["tab"] == tab:
			out.append(_items[id])
	return out


static func all_ids() -> Array:
	_ensure()
	return _order.duplicate()


static func zone_hint(d: Dictionary) -> String:
	## A short instruction shown while dragging this item.
	match d.get("kind", ""):
		"hang":
			return "Hang it on the tree"
		"clip":
			return "Clip it onto a bough"
		"topper":
			return "Crown the top of the tree"
		"garland":
			return "Drop onto the tree, then drag its ends to drape it"
	match d.get("zone", ""):
		"mantel_garland":
			return "Drape it along the mantelpiece"
		"hooks":
			return "Hang it from the mantelpiece"
		"floor":
			return "Set it on the floor or by the hearth"
		"surface":
			return "Stand it on the mantel or a table"
		"wall":
			return "Hang it on a wall or window"
		"ceiling":
			return "Hang it from the ceiling"
	return ""
