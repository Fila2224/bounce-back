extends Node2D

@export var score: int = 10
@export var score_label: Label

@export var meteor_scene: PackedScene = preload("res://scenes/meteor.tscn")
@export var fighter_scene: PackedScene = preload("res://scenes/enemy_fighter.tscn")
var pixel_font: FontFile = preload("res://assets/Pixel Game.otf")

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
@onready var hit_destroy_audio: AudioStreamPlayer = $HitDestroyAudio
@onready var hit_moon_audio: AudioStreamPlayer = $HitMoonAudio
@onready var game_over_ui: Control = get_node_or_null("GameOverUI")
@onready var game_over_time: Label = get_node_or_null("GameOverUI/TimeLabel")

var is_game_over: bool = false

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
	if not is_game_over:
		elapsed_game_time += delta

func _unhandled_input(event: InputEvent) -> void:
	if is_game_over:
		if event.is_action_pressed("restart") or (event is InputEventKey and event.pressed and event.keycode == KEY_R):
			get_tree().reload_current_scene()

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

func screen_shake(strength: float = 6.0, duration: float = 0.2) -> void:
	if not camera:
		return
	var tween := create_tween()
	var steps := 5
	var step_time := duration / float(steps)
	for i in range(steps):
		var current_strength := strength * (1.0 - float(i) / float(steps))
		var offset := Vector2(randf_range(-current_strength, current_strength), randf_range(-current_strength, current_strength))
		tween.tween_property(camera, "offset", offset, step_time)
	tween.tween_property(camera, "offset", Vector2.ZERO, step_time)

func spawn_floating_text(text: String, pos: Vector2, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.z_index = 60
	label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	label.global_position = pos - Vector2(25.0, 15.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(50.0, 30.0)
	if pixel_font:
		label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	add_child(label)
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 30.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)

func spawn_explosion_particles(pos: Vector2, color: Color, count: int) -> void:
	var p := CPUParticles2D.new()
	p.z_index = 30
	p.global_position = pos
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = count
	p.lifetime = 0.4
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 90.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = color
	add_child(p)
	get_tree().create_timer(0.5).timeout.connect(p.queue_free)

func _on_meteor_hit_rocket(pos: Vector2) -> void:
	add_score(1)
	spawn_floating_text("+1", pos, Color(0.2, 1.0, 0.4))
	spawn_explosion_particles(pos, Color(1.0, 0.65, 0.2), 10)
	if hit_destroy_audio:
		hit_destroy_audio.play()

func flash_moon() -> void:
	if not moon_center:
		return
	var tween := create_tween()
	moon_center.modulate = Color(2.5, 0.25, 0.25, 1.0)
	tween.tween_property(moon_center, "modulate", Color.WHITE, 0.18)

func trigger_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	if spawn_timer:
		spawn_timer.stop()
	
	var minutes := int(elapsed_game_time) / 60
	var seconds := int(elapsed_game_time) % 60
	if game_over_time:
		if minutes > 0:
			game_over_time.text = "Survived: %dm %02ds" % [minutes, seconds]
		else:
			game_over_time.text = "Survived: %ds" % seconds
	
	if game_over_ui:
		game_over_ui.visible = true
		game_over_ui.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(game_over_ui, "modulate:a", 1.0, 0.35)

func _on_meteor_hit_moon(pos: Vector2) -> void:
	add_score(-3)
	flash_moon()
	spawn_floating_text("-3", pos, Color(1.0, 0.25, 0.25))
	spawn_explosion_particles(pos, Color(0.9, 0.4, 0.2), 16)
	screen_shake(5.0, 0.2)
	if hit_moon_audio:
		hit_moon_audio.play()

func _on_fighter_hit_rocket(pos: Vector2) -> void:
	add_score(3)
	spawn_floating_text("+3", pos, Color(0.3, 1.0, 0.5))
	spawn_explosion_particles(pos, Color(0.2, 0.9, 1.0), 14)
	screen_shake(2.0, 0.1)
	if hit_destroy_audio:
		hit_destroy_audio.play()

func _on_fighter_hit_moon(pos: Vector2) -> void:
	add_score(-5)
	flash_moon()
	spawn_floating_text("-5", pos, Color(1.0, 0.2, 0.2))
	spawn_explosion_particles(pos, Color(1.0, 0.2, 0.1), 18)
	screen_shake(8.0, 0.25)
	if hit_moon_audio:
		hit_moon_audio.play()

func add_score(amount: int) -> void:
	if is_game_over:
		return
	score += amount
	update_score_display()
	if score < 0:
		trigger_game_over()

func update_score_display() -> void:
	if score_label:
		score_label.text = "Score: " + str(score)
