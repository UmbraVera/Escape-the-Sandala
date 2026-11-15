extends Area2D

@onready var sprite = $AnimatedSprite2D

const SPRITES = "res://bounce_back_sprites/"

var lane := 1
var busy := false
var jumping := false
var sliding := false
var caught := false
var invincible := 0.0
var mama_distance := 1.0
var score := 0.0
var coins := 0
var plates := 0

func _ready():
	area_entered.connect(_on_hit)
	var box = RectangleShape2D.new()
	box.size = Vector2(16, 30)
	$CollisionShape2D.shape = box
	$CollisionShape2D.position = Vector2(0, 4)
	set_outfit("base")

func set_outfit(outfit):
	var sf = SpriteFrames.new()
	var fps = {"run": 10, "jump": 6, "slide": 8, "hit": 4}
	for anim in ["run", "jump", "slide", "hit"]:
		var path = SPRITES + "boy_" + outfit + "_" + anim + ".png"
		if not ResourceLoader.exists(path):
			push_error("Missing picture: " + path)
			continue
		var tex = load(path)
		sf.add_animation(anim)
		sf.set_animation_speed(anim, fps[anim])
		sf.set_animation_loop(anim, anim == "run" or anim == "slide")
		var count = int(tex.get_width() / 32)
		for i in count:
			var frame = AtlasTexture.new()
			frame.atlas = tex
			frame.region = Rect2(i * 32, 0, 32, tex.get_height())
			sf.add_frame(anim, frame)
	sprite.sprite_frames = sf
	sprite.play("run")

func _process(delta):
	if caught or get_parent().state != "play":
		return
	if Input.is_action_just_pressed("left") and lane > 0:
		lane -= 1
	if Input.is_action_just_pressed("right") and lane < 2:
		lane += 1
	var target_x = [114.0, 270.0, 426.0][lane]
	position.x = lerp(position.x, target_x, 15 * delta)

	if not busy:
		if Input.is_action_just_pressed("jump"):
			jump()
		elif Input.is_action_just_pressed("slide"):
			slide()

	mama_distance = min(1.0, mama_distance + 0.06 * delta)
	invincible = max(0.0, invincible - delta)
	score += 10 * delta
	sprite.speed_scale = max(0.5, get_parent().speed / 350.0)

func jump():
	busy = true
	jumping = true
	sprite.play("jump")
	get_parent().play_sfx("jump")
	var t = create_tween()
	t.tween_property(sprite, "position:y", -45.0, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(sprite, "scale", Vector2(1.35, 1.35), 0.38)
	t.tween_property(sprite, "position:y", 0.0, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(sprite, "scale", Vector2(1, 1), 0.38)
	await t.finished
	jumping = false
	busy = false
	if not caught:
		sprite.play("run")

func slide():
	busy = true
	sliding = true
	sprite.play("slide")
	var t = create_tween()
	t.tween_property(sprite, "scale", Vector2(1.25, 0.6), 0.1)
	t.parallel().tween_property(sprite, "position:y", 12.0, 0.1)
	await get_tree().create_timer(0.6).timeout
	var back = create_tween()
	back.tween_property(sprite, "scale", Vector2(1, 1), 0.1)
	back.parallel().tween_property(sprite, "position:y", 0.0, 0.1)
	await back.finished
	sliding = false
	busy = false
	if not caught:
		sprite.play("run")

func _on_hit(area):
	if caught or get_parent().state != "play":
		return

	if area.is_in_group("pickups"):
		if area.type == "coin":
			coins += 1
			score += 5
			get_parent().play_sfx("coin")
			get_parent().popup("+1", area.position)
		elif area.type == "plate":
			plates += 1
			score += 50
			get_parent().play_sfx("plate")
			get_parent().popup("+50  plate " + str(plates) + "/" + str(get_parent().plates_needed), area.position, Color("#9fe1cb"))
		elif area.type == "atay":
			mama_distance = 1.0
			get_parent().play_sfx("plate")
			get_parent().popup("Atay! Mama falls back", area.position, Color("#c0dd97"))
		area.collect()
		if plates >= get_parent().plates_needed:
			get_parent().level_complete()
		return

	if not area.is_in_group("obstacles"):
		return
	if area.type in ["donkey", "fruit_box"] and jumping:
		return
	if area.type == "awning" and sliding:
		return
	if invincible > 0:
		return


	area.queue_free()
	invincible = 1.0
	mama_distance -= 0.5
	get_parent().play_sfx("hit")
	get_parent().play_sfx("mama")
	get_parent().shake()
	sprite.play("hit")
	var t = create_tween()
	t.tween_property(sprite, "modulate", Color(1, 0.35, 0.35), 0.08)
	t.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	if mama_distance <= 0.01:
		caught = true
		get_parent().game_over()
		return
	await get_tree().create_timer(0.4).timeout
	if not caught and not busy:
		sprite.play("run")
