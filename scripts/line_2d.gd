extends Line2D

@onready var rocket: CharacterBody2D = $"../rocket"
@onready var moon_center: Node2D = $"../moon-center"

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	clear_points()
	if rocket and moon_center:
		var rocket_point: Vector2 = rocket.global_position
		if rocket.has_node("connector"):
			rocket_point = rocket.get_node("connector").global_position
		
		add_point(to_local(rocket_point))
		add_point(to_local(moon_center.global_position))
		
		var length := points[0].distance_to(points[1])
		width = maxf(1.0, 10.0 - length / 50.0)
