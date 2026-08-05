extends Node2D

const SHEETS: Array[String] = ["idletest", "up", "down", "left", "right"]
const CELL := 220.0


func _ready() -> void:
	var row := 0
	for sheet: String in SHEETS:
		var texture: Texture2D = load("res://sprites/%s.png" % sheet)
		var frames: int = 4 if sheet == "idletest" else 5
		for i in range(frames):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2((i % 3) * 500, (i / 3) * 500, 500, 500)

			var sprite := Sprite2D.new()
			sprite.texture = atlas
			sprite.scale = Vector2(CELL / 500.0, CELL / 500.0)
			sprite.position = Vector2(110 + i * CELL, 110 + row * CELL)
			add_child(sprite)

			var frame_box := ColorRect.new()
			frame_box.color = Color(1, 0, 0, 0.12)
			frame_box.size = Vector2(CELL, CELL)
			frame_box.position = sprite.position - Vector2(CELL, CELL) / 2.0
			add_child(frame_box)

			var label := Label.new()
			label.text = "%s %d" % [sheet, i]
			label.position = sprite.position - Vector2(CELL, CELL) / 2.0
			add_child(label)
		row += 1
