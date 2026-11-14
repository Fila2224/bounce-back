extends CharacterBody2D

signal hit_moon
signal hit_rocket

@onready var moon_center: Node2D = $"../moon-center"
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d: Area2D = $Area2D

@export var speed: float = 100.0

var is_exploded: bool = false

func _ready() -> void:
	if not moon_center and get_parent():
		moon_center = get_parent().get_node_or_null("moon-center")
	
	if area_2d:
		area_2d.body_entered.connect(_on_body_entered)
		area_2d.area_entered.connect(_on_area_entered)
	
	if anim:
		anim.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if is_exploded:
		return
	
	if not moon_center:
		return
	
	var dir := (moon_center.global_position - global_position).normalized()
	if dir != Vector2.ZERO:
		rotation = dir.angle() + PI / 2
	
	global_position = global_position.move_toward(moon_center.global_position, speed * delta)
	
	# Záložní detekce: pokud meteor doletí přímo k povrchu měsíce (poloměr měsíce je cca 20 px)
	if global_position.distance_to(moon_center.global_position) <= 22.0:
		explode("moon")

func _on_body_entered(body: Node2D) -> void:
	if is_exploded:
		return
	
	# 1. Zásah raketou
	if body.name == "rocket" or body.is_in_group("rocket"):
		explode("rocket")
	# 2. Zásah měsíce
	elif body.name == "moon-center" or body.get_parent() == moon_center or body.is_in_group("moon"):
		explode("moon")

func _on_area_entered(area: Area2D) -> void:
	if is_exploded:
		return
	if area.get_parent() and (area.get_parent().name == "rocket" or area.get_parent().is_in_group("rocket")):
		explode("rocket")
		

## Provede explozi meteoru a rozliší, do čeho narazil
func explode(source: String) -> void:
	if is_exploded:
		return
	is_exploded = true
	
	if source == "moon":
		hit_moon.emit()
		# --- ZDE BUDE ODEČÍTÁNÍ BODŮ ZA ZÁSAH MĚSÍCE ---
		print("Meteor zasáhl měsíc! (-body)")
	elif source == "rocket":
		hit_rocket.emit()
		# --- ZDE BUDE PŘIČÍTÁNÍ BODŮ ZA OCHRANU MĚSÍCE ---
		print("Raketa zničila meteor!")
	
	# Spustíme animaci výbuchu z Exhaust_03
	if anim:
		anim.play("explode")
	else:
		queue_free()

func _on_animation_finished() -> void:
	if anim and anim.animation == "explode":
		queue_free()
