extends Node2D

var obstacle_scene = preload("res://obstacle.tscn")
var LANES = [114, 270, 426]
const ART = "res://bounce_back_sprites/"

# ---------------- levels ----------------
const MAX_LEVELS := 9
const SPEED_UP := 5.0           # speed gained per second inside a level
const PLATE_CHANCE := 0.22      # how often a plate piece appears (raise to test)
const OUTFITS = ["base", "djellaba", "babouche", "selham"]
const OUTFIT_NAMES = {"base": "T-shirt", "djellaba": "Djellaba", "babouche": "Fez + golden babouches", "selham": "Selham"}
const EXCUSES = [
	"\"It was the cat, wallah!\"",
	"\"It broke by itself, I swear!\"",
	"\"I was going to glue it back!\"",
	"\"The plate jumped off the table!\"",
	"\"Ask the neighbour's son!\"",
]

@export var chefchaouen_texture: Texture2D

static var level := 1           # level being played (kept between restarts)
static var skip_menu := false

var current_level := 1
var unlocked := 1
var best := 0
var plates_needed := 5
var start_speed := 220.0
var max_speed := 600.0

var speed := 0.0
var elapsed := 0.0
var timer := 1.5
var pickup_timer := 2.0
var running := false
var state := "menu"             # menu, intro, play, paused, won, over
var celebrating := false
var medina_texture
var hud
var sfx := {}
var music
var shake_time := 0.0
var base_pos := Vector2.ZERO
var screen                      # menu / win / lose overlay

func _ready():
	base_pos = position
	medina_texture = $Medina.texture
	hud = get_tree().get_first_node_in_group("hud")
	if hud == null:
		hud = get_node_or_null("HUD")
	load_save()
	setup_sounds()
	if skip_menu:
		skip_menu = false
		setup_level()
		start_level()
	else:
		show_menu()

# ================================================================ level setup
func setup_level():
	level = clamp(level, 1, MAX_LEVELS)
	current_level = level
	plates_needed = min(4 + level, 12)                 # level 1: 5 pieces, level 2: 6 ...
	start_speed = 200.0 + 20.0 * (level - 1)
	max_speed = min(520.0 + 30.0 * (level - 1), 720.0)
	if level % 2 == 0 and chefchaouen_texture:
		$Medina.texture = chefchaouen_texture
	else:
		$Medina.texture = medina_texture
	$Player.set_outfit(OUTFITS[min(level - 1, OUTFITS.size() - 1)])

func city_name():
	return "Chefchaouen" if (level % 2 == 0 and chefchaouen_texture) else "Marrakech"

func start_level():
	state = "intro"
	close_screen()
	say("LEVEL " + str(level) + "\n" + city_name() + "\n\nCollect " + str(plates_needed) + " plate pieces\nto fix Mama's tbsil!")
	if music and not music.playing:
		music.play()
	await get_tree().create_timer(2.3).timeout
	if hud:
		hud.hide_message()
	state = "play"
	running = true
	speed = start_speed

func choose_level(n):
	level = n
	setup_level()
	start_level()

func next_level():
	level = min(level + 1, MAX_LEVELS)
	skip_menu = true
	get_tree().reload_current_scene()

func restart_level():
	skip_menu = true
	get_tree().reload_current_scene()

func go_menu():
	skip_menu = false
	get_tree().reload_current_scene()

# ================================================================ input
func _unhandled_input(event):
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var k = event.keycode
	if k in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		if state == "menu":
			choose_level(level)
		elif state == "won":
			if level < MAX_LEVELS:
				next_level()
			else:
				go_menu()
		elif state == "over":
			restart_level()
	elif k == KEY_R and (state == "won" or state == "over"):
		restart_level()
	elif k == KEY_M and (state == "won" or state == "over"):
		go_menu()
	elif k in [KEY_P, KEY_ESCAPE] and (state == "play" or state == "paused"):
		toggle_pause()

# ================================================================ main loop
func _process(delta):
	if shake_time > 0:
		shake_time -= delta
		position = base_pos + Vector2(randf_range(-7, 7), randf_range(-7, 7))
	else:
		position = base_pos

	if not running:
		return

	elapsed += delta
	speed = min(max_speed, start_speed + elapsed * SPEED_UP)
	var pace = 350.0 / speed

	timer -= delta
	if timer <= 0:
		timer = randf_range(1.0, 1.6) * pace
		spawn_obstacle()

	pickup_timer -= delta
	if pickup_timer <= 0:
		pickup_timer = randf_range(1.4, 2.2) * pace
		spawn_pickups()

func toggle_pause():
	if state == "play":
		state = "paused"
		running = false
		speed = 0
		say("PAUSED\n\nPress P to continue")
		if music:
			music.stream_paused = true
	else:
		state = "play"
		running = true
		speed = min(max_speed, start_speed + elapsed * SPEED_UP)
		if hud:
			hud.hide_message()
		if music:
			music.stream_paused = false

# ================================================================ spawning
func spawn_obstacle():
	var type = ["donkey", "cart", "fruit_box", "awning"].pick_random()
	if type == "cart" and cart_on_screen():
		type = ["donkey", "fruit_box", "awning"].pick_random()
	var free = []
	for lane in 3:
		if lane_has("obstacles", lane, 250):
			continue
		if type == "cart" and lane_has("pickups", lane, 250):
			continue
		free.append(lane)
	if free.is_empty():
		return
	spawn(type, free.pick_random(), -170)

func spawn_pickups():
	var free = []
	for lane in 3:
		if lane_has("obstacles", lane, 450, ["cart"]):
			continue
		if lane_has("pickups", lane, 100):
			continue
		free.append(lane)
	if free.is_empty():
		return
	var lane = free.pick_random()
	var r = randf()
	if r < PLATE_CHANCE:
		spawn("plate", lane, -100)
	elif r < PLATE_CHANCE + 0.1:
		spawn("atay", lane, -100)
	else:
		for i in range(4):
			spawn("coin", lane, -100 - i * 70)

func lane_has(group, lane, max_y, types = []):
	for o in get_tree().get_nodes_in_group(group):
		if abs(o.position.x - LANES[lane]) < 10 and o.position.y < max_y:
			if types.is_empty() or o.type in types:
				return true
	return false

func cart_on_screen():
	for o in get_tree().get_nodes_in_group("obstacles"):
		if o.type == "cart" and o.position.y < 480:
			return true
	return false

func spawn(type, lane, y):
	var o = obstacle_scene.instantiate()
	o.type = type
	o.position = Vector2(LANES[lane], y)
	add_child(o)
	move_child(o, 1)

func clear_objects():
	for o in get_tree().get_nodes_in_group("obstacles") + get_tree().get_nodes_in_group("pickups"):
		o.queue_free()

# ================================================================ win / lose
func level_complete():
	if state != "play":
		return
	state = "won"
	running = false
	celebrating = true                  # Mama runs to hug the boy
	speed = 0
	clear_objects()
	play_sfx("plate")
	$Player.mama_distance = 1.0
	var s = int($Player.score)
	var new_best = s > best
	if new_best:
		best = s
	unlocked = max(unlocked, min(level + 1, MAX_LEVELS))
	save_game()
	var gift = ""
	if level < OUTFITS.size():
		gift = OUTFITS[level]           # outfit he will wear next level
	await get_tree().create_timer(1.4).timeout
	show_end_screen(true, s, new_best, gift)

func game_over():
	if state != "play":
		return
	state = "over"
	running = false
	speed = 0
	shake(0.4)
	play_sfx("caught")
	if music:
		music.stop()
	var s = int($Player.score)
	var new_best = s > best
	if new_best:
		best = s
	save_game()
	await get_tree().create_timer(0.9).timeout
	show_end_screen(false, s, new_best, "")

# ================================================================ screens
func tex(name):
	var path = ART + name
	return load(path) if ResourceLoader.exists(path) else null

func close_screen():
	if screen and is_instance_valid(screen):
		screen.queue_free()
	screen = null

func new_card(ribbon_text, ribbon_color, art_name) -> Control:
	close_screen()
	if hud:
		hud.hide_message()
	screen = CanvasLayer.new()
	screen.layer = 10
	add_child(screen)
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size = Vector2(540, 960)
	screen.add_child(dim)

	var card = Control.new()
	card.size = Vector2(540, 960)
	card.pivot_offset = Vector2(270, 450)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(card)

	var frame = TextureRect.new()
	frame.texture = tex("screen_card.png")
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.position = Vector2(30, 90)
	frame.size = Vector2(480, 708)
	card.add_child(frame)

	var art = TextureRect.new()
	art.texture = tex(art_name)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.position = Vector2(90, 150)
	art.size = Vector2(360, 270)
	card.add_child(art)

	var ribbon = Panel.new()
	var rs = StyleBoxFlat.new()
	rs.bg_color = ribbon_color
	rs.border_color = Color("#d9a521")
	rs.set_border_width_all(4)
	rs.set_corner_radius_all(14)
	ribbon.add_theme_stylebox_override("panel", rs)
	ribbon.position = Vector2(55, 66)
	ribbon.size = Vector2(430, 66)
	card.add_child(ribbon)
	var title = text_label(card, ribbon_text, Vector2(55, 66), Vector2(430, 66), 30, Color.WHITE, true)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# pop-in animation
	card.scale = Vector2(0.6, 0.6)
	card.modulate.a = 0.0
	var t = card.create_tween()
	t.tween_property(card, "scale", Vector2(1, 1), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(card, "modulate:a", 1.0, 0.25)
	return card

func text_label(parent, text, pos, size, font_size, color, outlined := false) -> Label:
	var l = Label.new()
	l.text = text
	l.position = pos
	l.size = size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if outlined:
		l.add_theme_color_override("font_outline_color", Color("#2a1a14"))
		l.add_theme_constant_override("outline_size", 7)
	parent.add_child(l)
	return l

func make_button(parent, text, pos, size, color, callback, font_size := 24) -> Button:
	var b = Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.focus_mode = Control.FOCUS_NONE
	var sb = StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(14)
	sb.border_color = Color("#3b2a1e")
	sb.set_border_width_all(3)
	var hover = sb.duplicate()
	hover.bg_color = color.lightened(0.18)
	var down = sb.duplicate()
	down.bg_color = color.darkened(0.18)
	var off = sb.duplicate()
	off.bg_color = Color("#9a948a")
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", down)
	b.add_theme_stylebox_override("disabled", off)
	b.add_theme_font_size_override("font_size", font_size)
	for c in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(c, Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color("#e6e1d6"))
	b.add_theme_color_override("font_outline_color", Color("#2a1a14"))
	b.add_theme_constant_override("outline_size", 5)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

# ---------------- start menu with level buttons ----------------
func show_menu():
	state = "menu"
	running = false
	speed = 0
	level = clamp(unlocked, 1, MAX_LEVELS)
	var card = new_card("BOUNCE BACK", Color("#d85a30"), "screen_menu.png")
	text_label(card, "Moroccan Edition", Vector2(30, 128), Vector2(480, 24), 16, Color("#6b3d22"))
	text_label(card, "Choose a level        Best score: " + str(best), Vector2(30, 428), Vector2(480, 30), 18, Color("#6b3d22"))
	for n in range(1, MAX_LEVELS + 1):
		var col = (n - 1) % 3
		var row = (n - 1) / 3
		var pos = Vector2(88 + col * 125, 462 + row * 64)
		var open = n <= unlocked
		var color = Color("#258b56") if n % 2 == 1 else Color("#2f6fa8")
		var b = make_button(card, str(n) if open else "-", pos, Vector2(114, 54), color, choose_level.bind(n), 26)
		b.disabled = not open
	make_button(card, "PLAY LEVEL " + str(level), Vector2(110, 662), Vector2(320, 62), Color("#d85a30"), choose_level.bind(level), 28)
	text_label(card, "← → move    ↑ jump    ↓ slide    P pause", Vector2(30, 740), Vector2(480, 24), 15, Color("#6b3d22"))

# ---------------- win / lose screen ----------------
func show_end_screen(won: bool, s: int, new_best: bool, gift: String):
	var card
	if won:
		card = new_card("LEVEL " + str(level) + " COMPLETE!", Color("#258b56"), "screen_win.png")
	else:
		card = new_card("MAMA CAUGHT YOU!", Color("#b3261e"), "screen_lose.png")

	text_label(card, "SCORE", Vector2(30, 428), Vector2(480, 22), 17, Color("#6b3d22"))
	var big = text_label(card, str(s), Vector2(30, 448), Vector2(480, 56), 46, Color("#ffd23f"), true)
	if new_best:
		var nb = text_label(card, "NEW BEST!", Vector2(350, 446), Vector2(140, 30), 18, Color("#ffffff"), true)
		nb.add_theme_color_override("font_outline_color", Color("#d4537e"))
		nb.rotation = 0.2
	var p = $Player
	text_label(card, "Coins " + str(p.coins) + "     Plates " + str(p.plates) + "/" + str(plates_needed) + "     Best " + str(best),
		Vector2(30, 508), Vector2(480, 28), 19, Color("#3b2a1e"))

	# middle box: the gift (win) or the boy's excuse (lose)
	var box = Panel.new()
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color("#fde7b8") if won else Color("#ffffff")
	bs.border_color = Color("#d9a521") if won else Color("#3b2a1e")
	bs.set_border_width_all(3)
	bs.set_corner_radius_all(14)
	box.add_theme_stylebox_override("panel", bs)
	box.position = Vector2(70, 546)
	box.size = Vector2(400, 104)
	card.add_child(box)
	if won:
		if gift != "":
			var frames = tex("boy_" + gift + "_run.png")
			if frames:
				var a = AtlasTexture.new()
				a.atlas = frames
				a.region = Rect2(0, 0, 32, frames.get_height())
				var pic = TextureRect.new()
				pic.texture = a
				pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				pic.stretch_mode = TextureRect.STRETCH_SCALE
				pic.position = Vector2(84, 550)
				pic.size = Vector2(56, 96)
				card.add_child(pic)
			text_label(card, "YOUR GIFT", Vector2(150, 556), Vector2(310, 24), 16, Color("#993c1d"))
			text_label(card, OUTFIT_NAMES[gift] + "!", Vector2(150, 580), Vector2(310, 34), 26, Color("#258b56"), true)
			text_label(card, "He wears it from level " + str(level + 1), Vector2(150, 618), Vector2(310, 24), 15, Color("#6b3d22"))
		else:
			text_label(card, "YOUR GIFT", Vector2(70, 560), Vector2(400, 24), 16, Color("#993c1d"))
			text_label(card, "Mama's love + a fixed tbsil!", Vector2(70, 590), Vector2(400, 40), 24, Color("#258b56"), true)
	else:
		text_label(card, EXCUSES.pick_random(), Vector2(80, 560), Vector2(380, 56), 22, Color("#2a1a14"))
		text_label(card, "- the boy, every time", Vector2(80, 618), Vector2(380, 24), 15, Color("#888780"))

	# buttons
	if won:
		if level < MAX_LEVELS:
			make_button(card, "NEXT LEVEL ▶", Vector2(66, 668), Vector2(250, 62), Color("#258b56"), next_level, 26)
		else:
			make_button(card, "ALL DONE! ★", Vector2(66, 668), Vector2(250, 62), Color("#258b56"), go_menu, 26)
		make_button(card, "RESTART", Vector2(326, 668), Vector2(150, 62), Color("#d85a30"), restart_level, 22)
	else:
		make_button(card, "TRY AGAIN", Vector2(66, 668), Vector2(250, 62), Color("#d85a30"), restart_level, 26)
		make_button(card, "MENU", Vector2(326, 668), Vector2(150, 62), Color("#2f6fa8"), go_menu, 22)
	if won:
		make_button(card, "MENU", Vector2(195, 740), Vector2(150, 44), Color("#2f6fa8"), go_menu, 18)
		confetti()

func confetti():
	var colors = [Color("#e24b4a"), Color("#e8b923"), Color("#258b56"), Color("#2f6fa8"), Color("#d4537e"), Color("#fff0d5")]
	for i in 70:
		var c = ColorRect.new()
		c.color = colors.pick_random()
		c.size = Vector2(randf_range(6, 12), randf_range(10, 18))
		c.position = Vector2(randf_range(0, 540), randf_range(-400, -20))
		c.rotation = randf() * TAU
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		screen.add_child(c)
		var t = c.create_tween()
		t.tween_property(c, "position:y", 1000.0, randf_range(1.8, 3.4)).set_delay(randf_range(0.0, 0.8))
		t.parallel().tween_property(c, "rotation", c.rotation + randf_range(-9.0, 9.0), 3.0)

# ================================================================ effects / helpers
func shake(time := 0.25):
	shake_time = time

func popup(text, at: Vector2, color := Color("#ffd23f")):
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	l.size = Vector2(400, 34)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(clamp(at.x - 200, 0, 140), at.y - 90)
	l.z_index = 20
	add_child(l)
	var t = create_tween()
	t.tween_property(l, "position:y", l.position.y - 70, 0.7)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.7)
	t.tween_callback(l.queue_free)

func say(t):
	if hud:
		hud.show_message(t)

# ================================================================ save
func load_save():
	var cfg = ConfigFile.new()
	if cfg.load("user://bounce_back.cfg") == OK:
		best = cfg.get_value("game", "best", 0)
		unlocked = cfg.get_value("game", "unlocked", 1)

func save_game():
	var cfg = ConfigFile.new()
	cfg.set_value("game", "best", best)
	cfg.set_value("game", "unlocked", unlocked)
	cfg.save("user://bounce_back.cfg")

# ================================================================ sounds
func setup_sounds():
	for n in ["coin", "jump", "hit", "plate", "caught", "mama"]:
		for ext in [".wav", ".ogg", ".mp3"]:
			var path = "res://sounds/" + n + ext
			if ResourceLoader.exists(path):
				var p = AudioStreamPlayer.new()
				p.stream = load(path)
				add_child(p)
				sfx[n] = p
				break
	for ext in [".ogg", ".mp3", ".wav"]:
		var path = "res://sounds/music" + ext
		if ResourceLoader.exists(path):
			music = AudioStreamPlayer.new()
			music.stream = load(path)
			music.volume_db = -8
			add_child(music)
			music.finished.connect(music.play)
			break

func play_sfx(n):
	if sfx.has(n):
		sfx[n].play()
