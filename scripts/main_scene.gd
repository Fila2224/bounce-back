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
@onready var game_start_audio: AudioStreamPlayer = get_node_or_null("GameStartAudio")
@onready var game_over_audio: AudioStreamPlayer = get_node_or_null("GameOverAudio")
@onready var pause_ui: Control = get_node_or_null("PauseUI")
@onready var game_over_ui: Control = get_node_or_null("GameOverUI")
@onready var game_over_time: Label = get_node_or_null("GameOverUI/TimeLabel")
@onready var game_over_score: Label = get_node_or_null("GameOverUI/ScoreLabel")
@onready var time_label: Label = get_node_or_null("time_label")
@onready var best_label: Label = get_node_or_null("best_label")
@onready var start_ui: Control = get_node_or_null("StartUI")

var is_game_started: bool = false
var is_game_over: bool = false
var current_wave: int = 0
var wave_sound: AudioStream = preload("res://assets/sounds/wave_alert.wav")

static var best_score: int = 10
static var best_time: float = 0.0
var peak_score: int = 10

func _ready() -> void:
	if FileAccess.file_exists("user://records.cfg"):
		DirAccess.remove_absolute("user://records.cfg")
	if not score_label:
		score_label = find_child("score", true, false) as Label
	update_score_display()
	
	update_records_display()
	update_time_display()
	
	if start_ui:
		start_ui.visible = true
		var tween := create_tween().set_loops()
		tween.tween_property(start_ui, "modulate:a", 0.35, 0.7).set_trans(Tween.TRANS_SINE)
		tween.tween_property(start_ui, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)
	
	if not meteor_scene:
		meteor_scene = preload("res://scenes/meteor.tscn")
	if not fighter_scene:
		fighter_scene = preload("res://scenes/enemy_fighter.tscn")
	
	_refill_spawn_bag()
	
	if spawn_timer:
		spawn_timer.timeout.connect(_on_meteor_timer_timeout)
		spawn_timer.wait_time = initial_spawn_interval

func _process(delta: float) -> void:
	if is_game_started and not is_game_over:
		elapsed_game_time += delta
		update_time_display()
		if elapsed_game_time > best_time:
			best_time = elapsed_game_time
			update_records_display()
		check_waves()

func check_waves() -> void:
	if current_wave == 0:
		current_wave = 1
		show_wave_announcement("WAVE 1", "DEFEND THE VOID")
	elif current_wave == 1 and elapsed_game_time >= 30.0:
		current_wave = 2
		show_wave_announcement("WAVE 2", "FIGHTER SQUADRON")
	elif current_wave == 2 and elapsed_game_time >= 60.0:
		current_wave = 3
		show_wave_announcement("WAVE 3", "METEOR STORM")
	elif current_wave == 3 and elapsed_game_time >= 90.0:
		current_wave = 4
		show_wave_announcement("FINAL WAVE", "GRAVITY COLLAPSE")

func show_wave_announcement(title: String, subtitle: String) -> void:
	var container := VBoxContainer.new()
	container.z_index = 80
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.custom_minimum_size = Vector2(500.0, 100.0)
	container.size = Vector2(500.0, 100.0)
	container.pivot_offset = Vector2(250.0, 50.0)
	container.position = Vector2(-250.0, -90.0)
	container.modulate.a = 0.0
	container.scale = Vector2(0.6, 0.6)
	
	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if pixel_font:
		title_lbl.add_theme_font_override("font", pixel_font)
	title_lbl.add_theme_font_size_override("font_size", 34)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	title_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	title_lbl.add_theme_constant_override("outline_size", 8)
	container.add_child(title_lbl)
	
	var sub_lbl := Label.new()
	sub_lbl.text = subtitle
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if pixel_font:
		sub_lbl.add_theme_font_override("font", pixel_font)
	sub_lbl.add_theme_font_size_override("font_size", 20)
	sub_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	sub_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	sub_lbl.add_theme_constant_override("outline_size", 6)
	container.add_child(sub_lbl)
	
	add_child(container)
	
	if wave_sound:
		var audio := AudioStreamPlayer.new()
		audio.stream = wave_sound
		audio.volume_db = -2.0
		add_child(audio)
		audio.play()
		audio.finished.connect(audio.queue_free)
	
	var tween := create_tween()
	tween.tween_property(container, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(container, "modulate:a", 1.0, 0.4)
	tween.tween_interval(2.5)
	tween.tween_property(container, "modulate:a", 0.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(container, "position:y", container.position.y - 15.0, 0.9).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(container.queue_free)

func _unhandled_input(event: InputEvent) -> void:
	if is_game_over:
		if event.is_action_pressed("restart") or (event is InputEventKey and event.pressed and event.keycode == KEY_R):
			get_tree().reload_current_scene()
		return
	
	if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		toggle_pause()
		get_viewport().set_input_as_handled()
		return
	
	if not is_game_started:
		if event.is_action_pressed("blip") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
			start_game()
			get_viewport().set_input_as_handled()
		return

func toggle_pause() -> void:
	if is_game_over:
		return
	var new_paused := not get_tree().paused
	get_tree().paused = new_paused
	if pause_ui:
		pause_ui.visible = new_paused

func start_game() -> void:
	if is_game_started or is_game_over:
		return
	is_game_started = true
	if start_ui:
		start_ui.visible = false
	if game_start_audio:
		game_start_audio.play()
	if spawn_timer:
		spawn_timer.start()

func format_time(t: float) -> String:
	var mins: int = floori(t / 60.0)
	var secs: int = int(t) % 60
	return "%02d:%02d" % [mins, secs]

func update_time_display() -> void:
	if time_label:
		time_label.text = "Time: " + format_time(elapsed_game_time)

func update_records_display() -> void:
	if best_label:
		best_label.text = "Best: %s | %d pts" % [format_time(best_time), best_score]

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
	if game_over_audio:
		game_over_audio.play()
	
	if elapsed_game_time > best_time:
		best_time = elapsed_game_time
	if peak_score > best_score:
		best_score = peak_score
	update_records_display()
	
	if game_over_time:
		game_over_time.text = "Time: %s (Best: %s)" % [format_time(elapsed_game_time), format_time(best_time)]
	
	if game_over_score:
		game_over_score.text = "Peak: %d (Best: %d)" % [peak_score, best_score]
	
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
	if score > peak_score:
		peak_score = score
		if peak_score > best_score:
			best_score = peak_score
			update_records_display()
	update_score_display()
	if score < 0:
		trigger_game_over()

func update_score_display() -> void:
	if score_label:
		score_label.text = "Score: " + str(score)
