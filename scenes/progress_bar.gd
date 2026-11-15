extends ProgressBar

@onready var rocket: CharacterBody2D = $"../rocket"

func _ready() -> void:
	value = 100

func _process(_delta: float) -> void:
	if value < 20.0:
		var flash := (sin(Time.get_ticks_msec() * 0.016) + 1.0) * 0.5
		modulate = lerp(Color.WHITE, Color(1.8, 0.2, 0.2, 1.0), flash)
	elif modulate != Color.WHITE:
		modulate = Color.WHITE
