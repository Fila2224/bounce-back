extends CharacterBody2D

## Maximální rychlost letu těsně u planety
@export var speed: float = 80.0
## Minimální rychlost letu při maximálním vzdálení od planety
@export var min_speed: float = 15.0
## Vzdálenost od planety, při které rychlost klesne na minimum (odpovídá maximálnímu natažení lana)
@export var max_distance: float = 500.0
## Rychlost otáčení rakety (nastavte na 0 pro okamžité otočení, nebo např. 12 pro plynulé)
@export var rotation_speed: float = 5.0
## Uzel planety/měsíce, ke kterému je raketa přitahována
@export var planet: Node2D
## Rychlost pomalého stahování k planetě, když neletíte
@export var pull_speed: float = 35.0

@onready var exhaust: AnimatedSprite2D = $Exhaust

func _ready() -> void:
	if exhaust:
		exhaust.visible = false
	if not planet and get_parent():
		planet = get_parent().get_node_or_null("moon-center")

func _physics_process(delta: float) -> void:
	# Získání směru podle nastavených akcí z Input Map (left, right, up, down)
	var direction := Input.get_vector("left", "right", "up", "down")
	
	# Pokud držíme klávesy pohybu -> aktivní let
	if direction != Vector2.ZERO:
		# Výpočet rychlosti podle vzdálenosti od planety:
		# U povrchu planety letíme plnou rychlostí 'speed', se vzdalováním rychlost klesá k 'min_speed'
		var current_speed := speed
		if planet:
			var dist := global_position.distance_to(planet.global_position)
			var t := clampf((dist - 40.0) / maxf(1.0, max_distance - 40.0), 0.0, 1.0)
			current_speed = lerp(speed, min_speed, t)
		
		velocity = direction * current_speed
		
		# Obrázek rakety defaultně míří nahoru, proto k úhlu přičítáme 90 stupňů (PI / 2)
		var target_rotation := direction.angle() + PI / 2
		if rotation_speed > 0.0:
			rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)
		else:
			rotation = target_rotation
		
		# Spuštění plamenů za raketou
		if exhaust:
			exhaust.visible = true
			if not exhaust.is_playing() or exhaust.animation != "flying":
				exhaust.play("flying")
	else:
		# Zhasnutí motorů při nečinnosti
		if exhaust:
			exhaust.visible = false
			exhaust.stop()
		
		# Pokud nikam neletíme, gravitace nás pomalu stahuje k planetě
		if planet:
			var to_planet := planet.global_position - global_position
			if to_planet.length() > 1.0:
				velocity = to_planet.normalized() * pull_speed
			else:
				velocity = Vector2.ZERO
		else:
			velocity = Vector2.ZERO
	
	move_and_slide()
