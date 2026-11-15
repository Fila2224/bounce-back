extends Control

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		var p := get_parent()
		if p and p.has_method("toggle_pause"):
			p.toggle_pause()
			get_viewport().set_input_as_handled()
