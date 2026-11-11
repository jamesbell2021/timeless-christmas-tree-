class_name RoomLayout
extends RefCounted
## RoomLayout — every measurement of the parlour in one place, shared by the
## painters (room_*.gd) and the placement rules (Placement). Change a number
## here and both the art and the gameplay zones move together.
##
## Canvas: 1920 x 1080. The bottom 132 px are covered by the UI bar.

const CORNICE_H := 46.0
const PICTURE_RAIL_Y := 96.0
const DADO_Y := 528.0
const SKIRTING_Y := 742.0
const FLOOR_Y := 772.0
const UI_BAR_TOP := 948.0
const VANISH := Vector2(960, 330)

# Bay window behind the tree
const WINDOW := Rect2(724, 150, 472, 520)
const PELMET := Rect2(606, 92, 708, 74)

# Right-hand window and its drapes
const WINDOW_R := Rect2(1500, 168, 290, 392)
const PELMET_R := Rect2(1440, 118, 410, 62)

# Fireplace (left)
const MANTEL_Y := 420.0                 # top surface of the mantel shelf
const MANTEL_X0 := 88.0
const MANTEL_X1 := 592.0
const FIREBOX := Rect2(214, 568, 252, 204)
const OVERMANTEL := Rect2(206, 150, 268, 214)
const CLOCK_X := 340.0
const SCONCES := [Vector2(146, 256), Vector2(534, 256)]
const STOCKING_HOOKS := [Vector2(150, 448), Vector2(240, 448), Vector2(440, 448), Vector2(530, 448)]

# Tree
const TREE_BASE := Vector2(960, 884)
const TREE_HEIGHT := 700.0
const TREE_WIDTH := 600.0

# Furniture
const ARMCHAIR := Rect2(1436, 548, 330, 360)
const SIDE_TABLE := Vector2(1838, 652)  # centre of the table top
const LAMP_GLOW := Vector2(1840, 540)

# Placement surfaces: [x0, x1, y]
const SURFACES := [
	[110.0, 290.0, MANTEL_Y],
	[392.0, 572.0, MANTEL_Y],
	[1790.0, 1890.0, 652.0],
	[1512.0, 1780.0, 560.0],
]

const FLOOR_ZONE := Rect2(30, 792, 1860, 150)
const FLOOR_EXCLUDE := Rect2(1420, 740, 360, 150)   # behind / under the armchair
const WALL_ZONE := Rect2(30, 62, 1860, 676)
const CEILING_ZONE := Rect2(40, 110, 1840, 250)


static func floor_point(u: float, depth: float) -> Vector2:
	## Maps a floor position (u: 0..1 across the room, depth: 0 = back wall,
	## 1 = front edge of the screen) through simple one-point perspective.
	var y := lerpf(FLOOR_Y, 1080.0 + 60.0, depth)
	var spread := lerpf(1.0, 1.55, depth)
	var x := VANISH.x + (u * 1920.0 - VANISH.x) * spread
	return Vector2(x, y)
