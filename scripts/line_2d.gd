extends Line2D

@onready var rocket: CharacterBody2D = $"../rocket"
@onready var moon_center: Node2D = $"../moon-center"

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	clear_points()
	if rocket and moon_center:
		# Pokud má raketa konektor, navážeme lano na něj, jinak na střed rakety
		var rocket_point: Vector2 = rocket.global_position
		if rocket.has_node("connector"):
			rocket_point = rocket.get_node("connector").global_position
		
		# Přidání bodů převedených do lokálních souřadnic Line2D
		add_point(to_local(rocket_point))
		add_point(to_local(moon_center.global_position))
		
		var length := points[0].distance_to(points[1])
		# Tloušťka lana se zmenšuje se vzdáleností, minimálně na 1 px
		width = maxf(1.0, 10.0 - length / 50.0)
