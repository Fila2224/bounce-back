extends CharacterBody2D

signal hit_moon
signal hit_rocket

@onready var moon_center: Node2D = $"../moon-center"
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d: Area2D = $Area2D

## Počáteční základní rychlost stíhačky (o něco pomalejší než meteory)
@export var speed: float = 48.0

var is_dead: bool = false
var lifetime: float = 0.0

func _ready() -> void:
	if not moon_center and get_parent():
		moon_center = get_parent().get_node_or_null("moon-center")
	
	if area_2d:
		area_2d.body_entered.connect(_on_body_entered)
		area_2d.area_entered.connect(_on_area_entered)
	
	if anim:
		anim.animation_finished.connect(_on_animation_finished)
		anim.play("evasion")

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	lifetime += delta
	if lifetime > 40.0:
		queue_free()
		return
	
	if not moon_center:
		return
	
	var dir := (moon_center.global_position - global_position).normalized()
	if dir != Vector2.ZERO:
		rotation = dir.angle()
	
	global_position = global_position.move_toward(moon_center.global_position, speed * delta)
	
	if global_position.distance_to(moon_center.global_position) <= 22.0:
		on_hit_moon()

func _on_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	
	if body.name == "rocket" or body.is_in_group("rocket"):
		on_hit_rocket()
	elif body.name == "moon-center" or body.get_parent() == moon_center or body.is_in_group("moon"):
		on_hit_moon()

func _on_area_entered(area: Area2D) -> void:
	if is_dead:
		return
	if area.get_parent() and (area.get_parent().name == "rocket" or area.get_parent().is_in_group("rocket")):
		on_hit_rocket()

func _disable_collision() -> void:
	if area_2d:
		area_2d.set_deferred("monitoring", false)
		area_2d.set_deferred("monitorable", false)

func on_hit_rocket() -> void:
	if is_dead:
		return
	is_dead = true
	_disable_collision()
	hit_rocket.emit()
	print("Stíhačka zničena raketou! (+3 body)")
	
	if anim:
		anim.play("destroyed")
		get_tree().create_timer(1.2).timeout.connect(func():
			if is_instance_valid(self):
				queue_free()
		)
	else:
		queue_free()

func on_hit_moon() -> void:
	if is_dead:
		return
	is_dead = true
	_disable_collision()
	hit_moon.emit()
	print("Stíhačka zaútočila na měsíc! (-5 bodů)")
	
	if anim:
		anim.play("attack_2")
		get_tree().create_timer(1.0).timeout.connect(func():
			if is_instance_valid(self):
				queue_free()
		)
	else:
		queue_free()

func _on_animation_finished() -> void:
	if anim and (anim.animation == "destroyed" or anim.animation == "attack_2"):
		queue_free()
