extends CharacterBody2D
@onready var moon_center: Sprite2D = $"../moon-center"
@export var target: Node2D
@export var speed: float = 100.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.



func _physics_process(delta):
	var angle = (moon_center.position - position).angle()
	rotation = angle +90
	global_position = global_position.move_toward(moon_center.global_position, speed * delta)
