extends TextureRect

@export var mouth_open_eyes_open : Texture2D
@export var mouth_closed_eyes_open : Texture2D
@export var mouth_open_eyes_closed : Texture2D
@export var mouth_closed_eyes_closed : Texture2D

@export var threshhold : float = 0.01
@export var blink_duration : float = 0.2
@export var blink_cooldown : float = 5.0
var is_blinking : bool = false

var effect : AudioEffectSpectrumAnalyzerInstance

func _ready():
	var idx = AudioServer.get_bus_index("Record")
	var record_effect : AudioEffectRecord = AudioServer.get_bus_effect(idx, 0)
	record_effect.set_recording_active(true)
	effect = AudioServer.get_bus_effect_instance(idx, 1)
	get_tree().create_timer(blink_cooldown).timeout.connect(blink)

func blink() -> void:
	is_blinking = true
	await(get_tree().create_timer(blink_duration).timeout)
	get_tree().create_timer(blink_cooldown).timeout.connect(blink)
	is_blinking = false

func _process(delta : float) -> void:
	var volume : float = effect.get_magnitude_for_frequency_range(0, 10000).length()
	var idx : int = int(is_blinking)
	if (volume > threshhold):
		idx += 2
	match (idx):
		0:
			texture = mouth_closed_eyes_open
		1:
			texture = mouth_closed_eyes_closed
		2:
			texture = mouth_open_eyes_open
		3:
			texture = mouth_open_eyes_closed
