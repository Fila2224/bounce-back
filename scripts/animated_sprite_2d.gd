extends AnimatedSprite2D
@onready var rocket: CharacterBody2D = $rocket

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	frame = 6 - rocket.lives
