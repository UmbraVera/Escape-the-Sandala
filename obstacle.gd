extends Area2D

var type := "donkey"
var anim_time := 0.0
var pic

const PICKUPS = ["coin", "plate", "atay"]
const PICS = {
	"donkey": preload("res://bounce_back_sprites/obstacle_donkey.png"),
	"cart": preload("res://bounce_back_sprites/obstacle_cart.png"),
	"fruit_box": preload("res://bounce_back_sprites/obstacle_fruit_box.png"),
	"awning": preload("res://bounce_back_sprites/obstacle_awning.png"),
	"coin": preload("res://bounce_back_sprites/pickup_coin.png"),
	"plate": preload("res://bounce_back_sprites/pickup_plate_piece.png"),
	"atay": preload("res://bounce_back_sprites/pickup_atay.png"),
}

func _ready():
	if type in PICKUPS:
		add_to_group("pickups")
		scale = Vector2(3, 3)
	else:
		add_to_group("obstacles")
		scale = Vector2(2.5, 2.5)
		if type == "awning":
			z_index = 10      # drawn on top: the boy passes UNDER it

	pic = get_node_or_null("Sprite2D")
	if pic == null:
		pic = Sprite2D.new()
		add_child(pic)
	pic.texture = PICS[type]
	pic.scale = Vector2(1, 1)

	var size = PICS[type].get_size()
	if type == "coin":
		pic.hframes = 4
		size.x = size.x / 4

	var col = get_node_or_null("CollisionShape2D")
	if col == null:
		col = CollisionShape2D.new()
		add_child(col)
	var box = RectangleShape2D.new()
	box.size = size * 0.8
	col.shape = box

	# hint sign above obstacles
	var hints = {"donkey": "JUMP ↑", "fruit_box": "JUMP ↑", "awning": "SLIDE ↓", "cart": "MOVE ← →"}
	if type in hints:
		var hint = Label.new()
		hint.text = hints[type]
		hint.add_theme_font_size_override("font_size", 8)
		hint.add_theme_color_override("font_color", Color("#fff0d5"))
		hint.add_theme_color_override("font_outline_color", Color.BLACK)
		hint.add_theme_constant_override("outline_size", 3)
		hint.size = Vector2(60, 12)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.position = Vector2(-30, -size.y / 2 - 14)
		add_child(hint)

func _process(delta):
	position.y += get_parent().speed * delta
	if type == "coin":
		anim_time += delta
		pic.frame = int(anim_time * 8) % 4
	if position.y > 1100:
		queue_free()

# picked up: pop, fade out, disappear (and can't be counted twice)
func collect():
	remove_from_group("pickups")
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	var t = create_tween()
	t.tween_property(self, "scale", scale * 1.7, 0.2)
	t.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	t.tween_callback(queue_free)
