extends Area2D

var player

func _ready():
	player = get_parent().get_node("Player")

	var spr = get_node_or_null("AnimatedSprite2D")
	var path = "res://bounce_back_sprites/mama_run.png"
	if spr and ResourceLoader.exists(path):
		var tex = load(path)
		var sf = SpriteFrames.new()
		sf.add_animation("run")
		sf.set_animation_speed("run", 10)
		sf.set_animation_loop("run", true)
		for i in int(tex.get_width() / 40):
			var frame = AtlasTexture.new()
			frame.atlas = tex
			frame.region = Rect2(i * 40, 0, 40, tex.get_height())
			sf.add_frame("run", frame)
		spr.sprite_frames = sf
		spr.play("run")

func _process(delta):
	if player:
		position.x = lerp(position.x, player.position.x, 4 * delta)
		var target_y = 770 + 90 * player.mama_distance
		if get_parent().celebrating:
			target_y = player.position.y + 75
		position.y = lerp(position.y, target_y, 3 * delta)
		var spr = get_node_or_null("AnimatedSprite2D")
		if spr:
			spr.speed_scale = 0.0 if get_parent().speed == 0 and not get_parent().celebrating else 1.0
