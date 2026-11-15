extends Sprite2D

func _process(delta):
	region_rect.position.y -= get_parent().speed * delta
