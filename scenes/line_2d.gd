extends Line2D
@onready var rocket: CharacterBody2D = $rocket
@onready var moon_center: Sprite2D = $"moon-center"
@onready var line_2d: Line2D = $Line2D

func _ready() -> void:
	pass # Replace with function body.


func _process(_delta):
	clear_points()
	#add_point((rocket.position.x,rocket.position.y))
	#add_point((moon_center.position.x,moon_center.position.y))
