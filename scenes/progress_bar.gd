extends ProgressBar
@onready var rocket: CharacterBody2D = $"../rocket"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	value = 100

