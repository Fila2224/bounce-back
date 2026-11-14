extends CharacterBody2D

@export var speed: float = 300.0

func _physics_process(_delta: float) -> void:
	# Získání směru podle nastavených akcí z Input Map (left, right, up, down)
	var direction := Input.get_vector("left", "right", "up", "down")
	
	velocity = direction * speed
	move_and_slide()
