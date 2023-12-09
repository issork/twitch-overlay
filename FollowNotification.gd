extends RichTextLabel

const DURATION : float = 2.0
const FADE_OUT_DURATION : float = 2.0

var mutex : Mutex = Mutex.new()

func _ready() -> void:
	modulate.a = 0

func show_notification(message : String) -> void:
	mutex.lock()
	clear()
	push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	append_text("[nervous frequency=12.0]")
	add_text(message)
	var tween : Tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.1)
	tween.tween_interval(DURATION)
	tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_DURATION)
	await(tween.finished)
	mutex.unlock()
