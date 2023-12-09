@tool
extends Control

@export var duration : float = 3.0

func _ready() -> void:
	var viewport : Rect2 = get_viewport_rect()
	size = Vector2(viewport.size.x / 2, viewport.size.y / 2)

func put_emote(emote : Texture2D) -> void:
	var tex : TextureRect = TextureRect.new()
	tex.texture = emote
	tex.position = Vector2(randi_range(0, size.x), randi_range(0, size.y))
	var direction : Vector2 = Vector2(1, 0)
	direction.rotated(PI * randf())
	print(direction)
	add_child(tex)
	var tween : Tween = get_tree().create_tween()
	tween.set_parallel()
	tween.tween_property(tex, "position", tex.position + direction * 400, duration)
	tween.tween_property(tex, "rotation_degrees", randf_range(-30.0, 30.0), duration)
	tween.tween_property(tex, "modulate:a", 0.0, duration)
	await(tween.finished)
	tex.queue_free()
