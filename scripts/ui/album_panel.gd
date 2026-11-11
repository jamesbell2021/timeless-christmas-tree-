class_name AlbumPanel
extends ModalPanel
## The Album: six saved arrangements of the tree, each kept like a page in a
## photograph album. Choose one to step into it; start afresh or copy the
## current tree into an empty page.

signal choose(index: int)
signal duplicate_to(index: int)
signal clear_current

var parlour: Parlour


func _init(p_parlour: Parlour) -> void:
	super("The Album", Vector2(1240, 760))
	parlour = p_parlour


func _build() -> void:
	add_label("Each page keeps its own tree. Step between them whenever you like.", Vector2(0, 104), "body_italic", 24, Color(UIKit.INK, 0.75), panel_size.x).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var cw := 300.0
	var ch := 236.0
	for i in GameState.ARRANGEMENT_COUNT:
		var col := i % 3
		var row := i / 3
		var card := AlbumCard.new(i, parlour.thumbnail(i))
		card.position = Vector2(130 + col * (cw + 40), 150 + row * (ch + 14))
		card.size = Vector2(cw, ch)
		card.chosen.connect(func(idx: int) -> void:
			choose.emit(idx)
			close_panel()
		)
		content.add_child(card)
	var y := panel_size.y - 86
	var dup := OrnateButton.new("Copy This Tree to a New Page", "paper")
	dup.font_size = 22
	dup.position = Vector2(150, y)
	dup.custom_minimum_size = Vector2(440, 52)
	dup.size = Vector2(440, 52)
	dup.pressed.connect(func() -> void:
		for i in GameState.ARRANGEMENT_COUNT:
			if GameState.is_arrangement_empty(i) and i != GameState.current_arrangement:
				duplicate_to.emit(i)
				close_panel()
				return
		dup.text = "Every page is in use"
		dup.queue_redraw()
	)
	content.add_child(dup)
	var clr := OrnateButton.new("Begin This Page Anew", "paper")
	clr.font_size = 22
	clr.position = Vector2(panel_size.x - 150 - 440, y)
	clr.custom_minimum_size = Vector2(440, 52)
	clr.size = Vector2(440, 52)
	clr.pressed.connect(func() -> void:
		clear_current.emit()
		close_panel()
	)
	content.add_child(clr)
