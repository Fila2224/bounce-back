extends CharacterBody2D

signal hit_moon
signal hit_rocket

@onready var moon_center: Node2D = $"../moon-center"
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d: Area2D = $Area2D

## Rychlost letu stíhačky (o něco pomalejší než meteory, které mají 100)
@export var speed: float = 75.0

var is_dead: bool = false

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
	
	if not moon_center:
		return
	
	# Otáčení čelem k měsíci (sprite má špičku doprava, takže rotation přímo odpovídá úhlu směru)
	var dir := (moon_center.global_position - global_position).normalized()
	if dir != Vector2.ZERO:
		rotation = dir.angle()
	
	global_position = global_position.move_toward(moon_center.global_position, speed * delta)
	
	# Záložní detekce nárazu na povrch měsíce (poloměr měsíce cca 20 px)
	if global_position.distance_to(moon_center.global_position) <= 22.0:
		on_hit_moon()

func _on_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	
	# 1. Zásah naší raketou
	if body.name == "rocket" or body.is_in_group("rocket"):
		on_hit_rocket()
	# 2. Zásah měsíce
	elif body.name == "moon-center" or body.get_parent() == moon_center or body.is_in_group("moon"):
		on_hit_moon()

func _on_area_entered(area: Area2D) -> void:
	if is_dead:
		return
	if area.get_parent() and (area.get_parent().name == "rocket" or area.get_parent().is_in_group("rocket")):
		on_hit_rocket()

## Zničení stíhačky naší raketou -> animace 'destroyed'
func on_hit_rocket() -> void:
	if is_dead:
		return
	is_dead = true
	hit_rocket.emit()
	print("Stíhačka zničena raketou! (+3 body)")
	
	if anim:
		anim.play("destroyed")
	else:
		queue_free()

## Dotyk stíhačky s měsícem -> animace 'attack_2'
func on_hit_moon() -> void:
	if is_dead:
		return
	is_dead = true
	hit_moon.emit()
	print("Stíhačka zaútočila na měsíc! (-5 bodů)")
	
	if anim:
		anim.play("attack_2")
	else:
		queue_free()

func _on_animation_finished() -> void:
	if anim and (anim.animation == "destroyed" or anim.animation == "attack_2"):
		queue_free()
