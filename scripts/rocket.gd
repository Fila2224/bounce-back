
extends CharacterBody2D

@export var speed: float = 80.0

@export var min_speed: float = 15.0

@export var max_distance: float = 500.0
@export var rotation_speed: float = 5.0
@export var planet: Node2D
@export var pull_speed: float = 35.0
@export var dash_duration: float = 0.25

@export var boost_multiplier: float = 2.0

var lives = 6
var is_dashing: bool = false
var is_boosting: bool = false

@onready var timer: Timer = $"../ProgressBar/Timer"
@onready var exhaust: AnimatedSprite2D = $Exhaust
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var progress_bar: ProgressBar = $"../ProgressBar"


func _ready() -> void:
	if exhaust:
		exhaust.visible = false

	if not planet and get_parent():
		planet = get_parent().get_node_or_null("moon-center")

	if timer:
		timer.wait_time = 0.05
		timer.one_shot = false
		timer.timeout.connect(_on_boost_timer_timeout)
		timer.start()


func _physics_process(delta: float) -> void:

	if Input.is_action_just_pressed("blip") and not is_dashing and planet:
		start_center_dash()
		return

	is_boosting = Input.is_action_pressed("speed") and progress_bar.value > 0

	if is_dashing:
		return

	var direction := Input.get_vector("left", "right", "up", "down")

	if direction != Vector2.ZERO:

		var current_speed := speed

		if planet:
			var dist := global_position.distance_to(planet.global_position)
			var t := clampf(
				(dist - 40.0) / maxf(1.0, max_distance - 40.0),
				0.0,
				1.0
			)
			current_speed = lerp(speed, min_speed, t)

		if is_boosting:
			current_speed *= boost_multiplier

		velocity = direction * current_speed

		var target_rotation := direction.angle() + PI / 2

		if rotation_speed > 0.0:
			rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)
		else:
			rotation = target_rotation

		if exhaust:
			exhaust.visible = true
			if not exhaust.is_playing() or exhaust.animation != "flying":
				exhaust.play("flying")

	else:
		if exhaust:
			exhaust.visible = false
			exhaust.stop()

		if planet:
			var to_planet := planet.global_position - global_position

			if to_planet.length() > 1.0:
				velocity = to_planet.normalized() * pull_speed
			else:
				velocity = Vector2.ZERO
		else:
			velocity = Vector2.ZERO

	move_and_slide()


func _on_boost_timer_timeout() -> void:

	if Input.is_action_pressed("speed") and progress_bar.value > 0:
		progress_bar.value = maxf(0.0, progress_bar.value - 1.0)
	else:
		progress_bar.value = minf(100.0, progress_bar.value + 1.0)


func start_center_dash() -> void:
	is_dashing = true
	velocity = Vector2.ZERO

	if collision_shape:
		collision_shape.set_deferred("disabled", true)

	var current_offset := global_position - planet.global_position
	var target_pos := planet.global_position - current_offset

	var dash_dir := (target_pos - global_position).normalized()

	if dash_dir != Vector2.ZERO:
		rotation = dash_dir.angle() + PI / 2

	if exhaust:
		exhaust.visible = true
		if not exhaust.is_playing() or exhaust.animation != "flying":
			exhaust.play("flying")

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
