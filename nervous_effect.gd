# Modified 'nervous' RichtTextLabel effect from https://github.com/teebarjunk/godot-text_effects/blob/master/addons/teeb.text_effects/effects/Nervous.gd
@tool
class_name RichTextNervous
extends RichTextEffect

var bbcode = "nervous"

var SPLITTERS : Array[int] = [" ".to_ascii_buffer()[0], ".".to_ascii_buffer()[0], ",".to_ascii_buffer()[0], "-".to_ascii_buffer()[0]]

var _word = 0.0

func _process_custom_fx(char_fx : CharFXTransform) -> bool:
	if char_fx.relative_index == 0:
		_word = 0
	
	var scale:float = char_fx.env.get("scale", 1.0)
	var freq:float = char_fx.env.get("freq", 8.0)
	if TextServerManager.get_primary_interface().font_get_char_from_glyph_index(char_fx.font, 1, char_fx.glyph_index) in SPLITTERS:
		_word += 1
	
	var s = fmod((_word + char_fx.elapsed_time) * PI * 1.25, PI * 2.0)
	var p = sin(char_fx.elapsed_time * freq)
	char_fx.offset.x += sin(s) * p * scale
	char_fx.offset.y += cos(s) * p * scale
	
	return true
