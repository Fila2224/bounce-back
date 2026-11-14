extends Line2D

@onready var rocket: CharacterBody2D = $"../rocket"
@onready var moon_center: Sprite2D = $"../moon-center"

func _ready() -> void:
	pass

func _process(_delta):
	clear_points()
	if rocket and moon_center:
		add_point(rocket.position)
		add_point(moon_center.position)
		var length = points[0].distance_to(points[1])
		# Tloušťka lana se zmenšuje se vzdáleností, minimálně na 1 px
		width = maxf(1.0, 10.0 - length / 50.0)
