extends ProgressBar
@onready var rocket: CharacterBody2D = $"../rocket"

func _ready() -> void:
	value = 100

