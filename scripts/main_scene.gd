extends Node2D

@export var score: int = 10
@export var score_label: Label

@export var meteor_scene: PackedScene = preload("res://scenes/meteor.tscn")
@export var fighter_scene: PackedScene = preload("res://scenes/enemy_fighter.tscn")

enum EnemyType { METEOR, FIGHTER }
var spawn_bag: Array[EnemyType] = []

var elapsed_game_time: float = 0.0

@export var initial_spawn_interval: float = 3.2
@export var min_spawn_interval: float = 0.75
@export var difficulty_ramp_duration: float = 110.0 

@export var initial_meteor_speed: float = 60.0
@export var max_meteor_speed: float = 105.0

@export var initial_fighter_speed: float = 48.0
@export var max_fighter_speed: float = 85.0

@export var spawn_margin: float = 40.0

@onready var moon_center: Node2D = $"moon-center"
@onready var camera: Camera2D = $"moon-center/Camera2D"
@onready var spawn_timer: Timer = $MeteorTimer

func _ready() -> void:
	if not score_label:
		score_label = find_child("score", true, false) as Label
	update_score_display()
	
	if not meteor_scene:
		meteor_scene = preload("res://scenes/meteor.tscn")
	if not fighter_scene:
		fighter_scene = preload("res://scenes/enemy_fighter.tscn")
	
	_refill_spawn_bag()
	
	if spawn_timer:
		spawn_timer.timeout.connect(_on_meteor_timer_timeout)
		spawn_timer.wait_time = initial_spawn_interval
		spawn_timer.start()

func _process(delta: float) -> void:
	elapsed_game_time += delta

func get_difficulty_factor() -> float:
	return clampf(elapsed_game_time / maxf(1.0, difficulty_ramp_duration), 0.0, 1.0)

func get_current_spawn_interval() -> float:
	var factor := get_difficulty_factor()
	var curved_factor := factor * factor
	return lerpf(initial_spawn_interval, min_spawn_interval, curved_factor)

func get_current_meteor_speed() -> float:
	return lerpf(initial_meteor_speed, max_meteor_speed, get_difficulty_factor())

func get_current_fighter_speed() -> float:
	return lerpf(initial_fighter_speed, max_fighter_speed, get_difficulty_factor())

func _refill_spawn_bag() -> void:
	spawn_bag = [
		EnemyType.METEOR,
		EnemyType.METEOR,
		EnemyType.METEOR,
		EnemyType.METEOR,
		EnemyType.FIGHTER
	]
	spawn_bag.shuffle()

func _on_meteor_timer_timeout() -> void:
	spawn_enemy()
	
	if elapsed_game_time > 95.0 and randf() < 0.35:
		spawn_enemy()
	
	if spawn_timer:
		var current_interval := get_current_spawn_interval()
		var variation := current_interval * 0.15
		var next_time := maxf(0.5, current_interval + randf_range(-variation, variation))
		spawn_timer.wait_time = next_time

func get_random_screen_edge_position() -> Vector2:
	var viewport_size := get_viewport_rect().size
	var cam_zoom := camera.zoom if camera else Vector2(2.0, 2.0)
	
	var half_w := (viewport_size.x / cam_zoom.x) * 0.5 + spawn_margin
	var half_h := (viewport_size.y / cam_zoom.y) * 0.5 + spawn_margin
	
	var center := moon_center.global_position if moon_center else Vector2.ZERO
	
	var side := randi_range(0, 3)
	var spawn_pos := Vector2.ZERO
	
	match side:
		0:
			spawn_pos = Vector2(randf_range(-half_w, half_w), -half_h)
		1:
			spawn_pos = Vector2(randf_range(-half_w, half_w), half_h)
		2:
			spawn_pos = Vector2(-half_w, randf_range(-half_h, half_h))
		3:
			spawn_pos = Vector2(half_w, randf_range(-half_h, half_h))
	
	return center + spawn_pos

func spawn_enemy() -> void:
	if spawn_bag.is_empty():
		_refill_spawn_bag()
	
	var next_type: EnemyType = spawn_bag.pop_back()
	if next_type == EnemyType.FIGHTER:
		spawn_fighter()
	else:
		spawn_meteor()

func spawn_meteor() -> void:
	if not meteor_scene:
		meteor_scene = preload("res://scenes/meteor.tscn")
	if not meteor_scene:
		return
	
	var meteor := meteor_scene.instantiate() as Node2D
	meteor.global_position = get_random_screen_edge_position()
	
	if "speed" in meteor:
		meteor.speed = get_current_meteor_speed()
	
	if "moon_center" in meteor and moon_center:
		meteor.moon_center = moon_center
	
	if meteor.has_signal("hit_rocket"):
		meteor.hit_rocket.connect(_on_meteor_hit_rocket)
	if meteor.has_signal("hit_moon"):
		meteor.hit_moon.connect(_on_meteor_hit_moon)
	
	add_child(meteor)

func spawn_fighter() -> void:
	if not fighter_scene:
		fighter_scene = preload("res://scenes/enemy_fighter.tscn")
	if not fighter_scene:
		spawn_meteor()
		return
	
	var fighter := fighter_scene.instantiate() as Node2D
	fighter.global_position = get_random_screen_edge_position()
	
	if "speed" in fighter:
		fighter.speed = get_current_fighter_speed()
	
	if "moon_center" in fighter and moon_center:
		fighter.moon_center = moon_center
	
	if fighter.has_signal("hit_rocket"):
		fighter.hit_rocket.connect(_on_fighter_hit_rocket)
	if fighter.has_signal("hit_moon"):
		fighter.hit_moon.connect(_on_fighter_hit_moon)
	
	add_child(fighter)

func _on_meteor_hit_rocket() -> void:
	add_score(1)

func _on_meteor_hit_moon() -> void:
	add_score(-3)

func _on_fighter_hit_rocket() -> void:
	add_score(3)

func _on_fighter_hit_moon() -> void:
	add_score(-5)

func add_score(amount: int) -> void:
	score += amount
	update_score_display()

func update_score_display() -> void:
	if score_label:
		score_label.text = "Score: " + str(score)
