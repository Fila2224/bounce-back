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
## Doba průletu středem planety na druhou stranu (v sekundách)
@export var dash_duration: float = 0.25

var is_dashing: bool = false

@onready var exhaust: AnimatedSprite2D = $Exhaust
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	if exhaust:
		exhaust.visible = false
	if not planet and get_parent():
		planet = get_parent().get_node_or_null("moon-center")

func _physics_process(delta: float) -> void:
	# Spuštění průletu středem na druhou stranu planety akcí 'blip' (mezerník)
	if Input.is_action_just_pressed("blip") and not is_dashing and planet:
		start_center_dash()
		return
	
	# Pokud právě probíhá průlet středem, neovládáme raketu klávesami
	if is_dashing:
		return
	
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

## Zahájí rychlý přímý průlet středem planety na opačnou stranu
func start_center_dash() -> void:
	is_dashing = true
	velocity = Vector2.ZERO
	
	# Dočasně vypneme kolizi, aby raketa neuvízla v povrchu planety
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	# Relativní pozice vůči planetě a cílová pozice na opačné straně
	var current_offset := global_position - planet.global_position
	var target_pos := planet.global_position - current_offset
	
	# Natočení rakety ve směru průletu
	var dash_dir := (target_pos - global_position).normalized()
	if dash_dir != Vector2.ZERO:
		rotation = dash_dir.angle() + PI / 2
	
	# Zapnutí plamenů během průletu
	if exhaust:
		exhaust.visible = true
		if not exhaust.is_playing() or exhaust.animation != "flying":
			exhaust.play("flying")
	
	# Plynulý a rychlý pohyb na druhou stranu pomocí Tweenu
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", target_pos, dash_duration)
	tween.finished.connect(_on_dash_finished)

func _on_dash_finished() -> void:
	is_dashing = false
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if exhaust:
		exhaust.visible = false
		exhaust.stop()
