extends Line2D
@onready var rocket: CharacterBody2D = $rocket
@onready var moon_center: Sprite2D = $"moon-center"

func _ready() -> void:
	pass # Replace with function body.


func _process(_delta):
	#clear_points()
	add_point(to_local(moon_center.global_position))
	add_point(to_local(rocket.global_position))
