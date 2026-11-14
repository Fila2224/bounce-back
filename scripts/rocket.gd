extends CharacterBody2D

@export var speed: float = 80.0
## Rychlost otáčení rakety (nastavte na 0 pro okamžité otočení, nebo např. 12 pro plynulé)
@export var rotation_speed: float = 5.0

func _physics_process(delta: float) -> void:
	# Získání směru podle nastavených akcí z Input Map (left, right, up, down)
	var direction := Input.get_vector("left", "right", "up", "down")
	
	velocity = direction * speed
	move_and_slide()
	
	# Otáčení ve směru letu
	if direction != Vector2.ZERO:
		# Obrázek rakety defaultně míří nahoru, proto k úhlu přičítáme 90 stupňů (PI / 2)
		var target_rotation := direction.angle() + PI / 2
		if rotation_speed > 0.0:
			rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)
		else:
			rotation = target_rotation
