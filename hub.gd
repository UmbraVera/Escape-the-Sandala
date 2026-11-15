extends CanvasLayer

var player
var level_label
var score_label
var coin_label
var plate_label
var mama_bar
var message
var message_bg
var blink_time := 0.0

func _ready():
	add_to_group("hud")
	player = get_parent().get_node("Player")

	var bar = ColorRect.new()
	bar.color = Color("#3b2a1e")
	bar.size = Vector2(540, 72)
	add_child(bar)

	level_label = make_label(Vector2(16, 8), 22)
	level_label.add_theme_color_override("font_color", Color("#ffd23f"))
	score_label = make_label(Vector2(100, 8), 22)
	coin_label = make_label(Vector2(262, 8), 22)
	plate_label = make_label(Vector2(388, 8), 22)

	mama_bar = ProgressBar.new()
	mama_bar.position = Vector2(16, 44)
	mama_bar.size = Vector2(390, 18)
	mama_bar.max_value = 1.0
	mama_bar.step = 0.01
	mama_bar.show_percentage = false
	mama_bar.modulate = Color("#ff7b5c")
	add_child(mama_bar)
	var m = make_label(Vector2(420, 38), 20)
	m.text = "Mama"

	message_bg = ColorRect.new()
	message_bg.color = Color(0, 0, 0, 0.65)
	message_bg.position = Vector2(0, 300)
	message_bg.size = Vector2(540, 330)
	message_bg.visible = false
	add_child(message_bg)

	message = make_label(Vector2(0, 300), 28)
	message.size = Vector2(540, 330)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.visible = false

func make_label(pos, font_size):
	var l = Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color("#fff0d5"))
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	add_child(l)
	return l

func _process(delta):
	var main = get_parent()
	if player:
		level_label.text = "Lv " + str(main.current_level)
		score_label.text = "Score " + str(int(player.score))
		coin_label.text = "Coins " + str(player.coins)
		plate_label.text = "Plate " + str(player.plates) + "/" + str(main.plates_needed)
		mama_bar.value = 1.0 - player.mama_distance
	
	if message.visible and "Press" in message.text:
		blink_time += delta
		message.modulate.a = 0.6 + 0.4 * sin(blink_time * 5)
	else:
		message.modulate.a = 1.0

func show_message(t):
	message.text = t
	message.visible = true
	message_bg.visible = true

func hide_message():
	message.visible = false
	message_bg.visible = false
