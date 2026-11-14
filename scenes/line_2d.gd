extends Line2D
@onready var rocket: CharacterBody2D = $"../rocket"
@onready var moon_center: Sprite2D = $"../moon-center"
var lenght = 0
func _ready() -> void:
	pass # Replace with function body.
	

func _process(_delta):
	clear_points()

	add_point(rocket.position)
	add_point(moon_center.position)
	#length = points[0].distance_to(points[1])
	#width -= lenght/10
