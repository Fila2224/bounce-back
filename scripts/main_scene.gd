extends Node2D

@export var score: int = 10
@export var score_label: Label

@export var meteor_scene: PackedScene = preload("res://scenes/meteor.tscn")
@export var fighter_scene: PackedScene = preload("res://scenes/enemy_fighter.tscn")

## Šance na spawnutí stíhačky místo meteoru (0.20 odpovídá poměru 1 stíhačka na 4 meteory)
@export var fighter_spawn_chance: float = 0.20

@export var spawn_interval: float = 2.5
@export var spawn_interval_variation: float = 0.5
@export var spawn_margin: float = 40.0

@onready var moon_center: Node2D = $"moon-center"
@onready var camera: Camera2D = $"moon-center/Camera2D"
@onready var spawn_timer: Timer = $MeteorTimer

func _ready() -> void:
	if not score_label:
		score_label = find_child("score", true, false) as Label
	update_score_display()
	
	if spawn_timer:
		spawn_timer.timeout.connect(_on_meteor_timer_timeout)
		spawn_timer.wait_time = spawn_interval
		spawn_timer.start()

func _on_meteor_timer_timeout() -> void:
	spawn_enemy()
	if spawn_timer:
		var next_time := maxf(0.8, spawn_interval + randf_range(-spawn_interval_variation, spawn_interval_variation))
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
		0: # Nahoře
			spawn_pos = Vector2(randf_range(-half_w, half_w), -half_h)
		1: # Dole
			spawn_pos = Vector2(randf_range(-half_w, half_w), half_h)
		2: # Vlevo
			spawn_pos = Vector2(-half_w, randf_range(-half_h, half_h))
		3: # Vpravo
			spawn_pos = Vector2(half_w, randf_range(-half_h, half_h))
	
	return center + spawn_pos

## Vybere a vygeneruje nepřítele (stíhačku nebo meteor v poměru 1:4)
func spawn_enemy() -> void:
	if randf() < fighter_spawn_chance and fighter_scene:
		spawn_fighter()
	else:
		spawn_meteor()

func spawn_meteor() -> void:
	if not meteor_scene:
		return
	
	var meteor := meteor_scene.instantiate() as Node2D
	meteor.global_position = get_random_screen_edge_position()
	
	if "moon_center" in meteor and moon_center:
		meteor.moon_center = moon_center
	
	if meteor.has_signal("hit_rocket"):
		meteor.hit_rocket.connect(_on_meteor_hit_rocket)
	if meteor.has_signal("hit_moon"):
		meteor.hit_moon.connect(_on_meteor_hit_moon)
	
	add_child(meteor)

func spawn_fighter() -> void:
	if not fighter_scene:
		return
	
	var fighter := fighter_scene.instantiate() as Node2D
	fighter.global_position = get_random_screen_edge_position()
	
	if "moon_center" in fighter and moon_center:
		fighter.moon_center = moon_center
	
	if fighter.has_signal("hit_rocket"):
		fighter.hit_rocket.connect(_on_fighter_hit_rocket)
	if fighter.has_signal("hit_moon"):
		fighter.hit_moon.connect(_on_fighter_hit_moon)
	
	add_child(fighter)

## Meteor zničen raketou -> +1 bod
func _on_meteor_hit_rocket() -> void:
	add_score(1)

## Meteor zasáhl měsíc -> -3 body
func _on_meteor_hit_moon() -> void:
	add_score(-3)

## Stíhačka zničena raketou -> +3 body
func _on_fighter_hit_rocket() -> void:
	add_score(3)

## Stíhačka zasáhla měsíc -> -5 bodů
func _on_fighter_hit_moon() -> void:
	add_score(-5)

func add_score(amount: int) -> void:
	score += amount
	update_score_display()

func update_score_display() -> void:
	if score_label:
		score_label.text = "Score: " + str(score)
