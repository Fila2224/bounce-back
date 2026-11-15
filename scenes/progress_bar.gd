extends ProgressBar

@onready var rocket: CharacterBody2D = $"../rocket"
var fill_style: StyleBoxFlat

func _ready() -> void:
	value = 100
	fill_style = StyleBoxFlat.new()
	fill_style.corner_radius_top_left = 3
	fill_style.corner_radius_top_right = 3
	fill_style.corner_radius_bottom_left = 3
	fill_style.corner_radius_bottom_right = 3
	add_theme_stylebox_override("fill", fill_style)
	
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.08, 0.08, 0.12, 0.75)
	bg_style.border_color = Color(0.35, 0.35, 0.45, 0.9)
	bg_style.border_width_left = 2
	bg_style.border_width_top = 2
	bg_style.border_width_right = 2
	bg_style.border_width_bottom = 2
	bg_style.corner_radius_top_left = 3
	bg_style.corner_radius_top_right = 3
	bg_style.corner_radius_bottom_left = 3
	bg_style.corner_radius_bottom_right = 3
	add_theme_stylebox_override("background", bg_style)

func _process(_delta: float) -> void:
	if not fill_style:
		return
	if value >= 50.0:
		fill_style.bg_color = Color(0.2, 0.85, 0.35, 1.0)
		modulate = Color.WHITE
	elif value >= 20.0:
		fill_style.bg_color = Color(1.0, 0.65, 0.15, 1.0)
		modulate = Color.WHITE
	else:
		var flash := (sin(Time.get_ticks_msec() * 0.016) + 1.0) * 0.5
		fill_style.bg_color = lerp(Color(0.85, 0.15, 0.15, 1.0), Color(1.4, 0.35, 0.35, 1.0), flash)
		modulate = lerp(Color.WHITE, Color(1.3, 0.4, 0.4, 1.0), flash * 0.7)
