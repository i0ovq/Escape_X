extends Node3D

var falling := false
var fall_velocity := 0.0
var initial_position : Vector3 

func _ready():
	initial_position = position

func _physics_process(delta):
	scale = scale.lerp(Vector3(1, 1, 1), delta * 10)
	
	if falling:
		fall_velocity += 15.0 * delta
		position.y -= fall_velocity * delta
	else:
		fall_velocity = 0.0
	
	if position.y < -10 and falling:
		reset_vampire()

func _on_body_entered(_body):
	if !falling:
		Audio.play("res://sounds/fall.ogg") 
		scale = Vector3(1.25, 1, 1.25) 
		falling = true

func reset_vampire():
	falling = false 
	position.y = -50 
	
	# ننتظر 5 ثوانٍ
	await get_tree().create_timer(3.0).timeout
	
	# نعيده للمكان الأصلي ونصفر السرعة
	position = initial_position
	fall_velocity = 0.0
	falling = false
