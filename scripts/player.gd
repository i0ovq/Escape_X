extends CharacterBody3D

signal coin_collected

@export_subgroup("Components")
@export var view: Node3D

@export_subgroup("Properties")
@export var movement_speed := 8.0
@export var jump_strength := 7.0
@export var mouse_sensitivity := 0.002
@export var body_turn_speed := 10.0 

var movement_velocity: Vector3
var gravity := 0.0

var mouse_rotation := Vector2.ZERO
var previously_floored := false

var jump_single := true
var jump_double := true

var coins := 0

# --- متغيرات نظام الحفظ الجديدة ---
var last_checkpoint_position: Vector3 

@onready var particles_trail = $ParticlesTrail
@onready var sound_footsteps = $SoundFootsteps
@onready var model = $Character
@onready var animation = $Character/AnimationPlayer

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	model.rotation.y = PI
	# حفظ موقع البداية كأول نقطة حفظ تلقائية
	last_checkpoint_position = global_position 

func _input(event):
	if event is InputEventMouseMotion:
		mouse_rotation.y -= event.relative.x * mouse_sensitivity
		mouse_rotation.x -= event.relative.y * mouse_sensitivity
		mouse_rotation.x = clamp(mouse_rotation.x, -1.2, 1.2)

func _physics_process(delta):
	handle_controls(delta)
	handle_gravity(delta)
	handle_effects(delta)

	view.rotation.y = mouse_rotation.y
	view.rotation.x = mouse_rotation.x

	rotation.y = lerp_angle(rotation.y, mouse_rotation.y, delta * body_turn_speed)

	var applied_velocity = velocity.lerp(movement_velocity, delta * 10)
	applied_velocity.y = -gravity
	velocity = applied_velocity
	move_and_slide()

	# تم تعديل هذا الجزء: استدعاء respawn بدلاً من reload_scene
	if position.y < -10:
		respawn()

	model.scale = model.scale.lerp(Vector3.ONE, delta * 10)
	if is_on_floor() and gravity > 2 and !previously_floored:
		model.scale = Vector3(1.25, 0.75, 1.25)
		Audio.play("res://sounds/land.ogg")

	previously_floored = is_on_floor()

func handle_controls(delta):
	var input := Vector3.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.z = Input.get_axis("move_forward", "move_back")

	input = input.rotated(Vector3.UP, view.rotation.y)

	if input.length() > 1:
		input = input.normalized()

	movement_velocity = input * movement_speed

	if Input.is_action_just_pressed("jump"):
		if jump_single or jump_double:
			jump()

func handle_gravity(delta):
	gravity += 25 * delta
	if gravity > 0 and is_on_floor():
		jump_single = true
		jump_double = true
		gravity = 0

func jump():
	Audio.play("res://sounds/jump.ogg")
	gravity = -jump_strength
	model.scale = Vector3(0.5, 1.5, 0.5)

	if jump_single:
		jump_single = false
	else:
		jump_double = false

func handle_effects(delta):
	particles_trail.emitting = false
	sound_footsteps.stream_paused = true

	if is_on_floor():
		var horizontal_velocity = Vector2(velocity.x, velocity.z)
		var speed_factor = horizontal_velocity.length() / movement_speed

		if speed_factor > 0.05:
			if animation.current_animation != "walk":
				animation.play("walk", 0.1)

			if speed_factor > 0.3:
				sound_footsteps.stream_paused = false
				sound_footsteps.pitch_scale = speed_factor

			if speed_factor > 0.75:
				particles_trail.emitting = true
		else:
			if animation.current_animation != "idle":
				animation.play("idle", 0.1)

		animation.speed_scale = speed_factor if animation.current_animation == "walk" else 1.0
	else:
		if animation.current_animation != "jump":
			animation.play("jump", 0.1)

func collect_coin():
	coins += 1
	coin_collected.emit(coins)

# --- دوال التحكم بنقاط الحفظ ---

func update_checkpoint(new_pos: Vector3):
	last_checkpoint_position = new_pos

func respawn():
	# نقل اللاعب للموقع المحفوظ
	global_position = last_checkpoint_position
	# تصفير القوى الفيزيائية لمنع حدوث مشاكل عند الانتقال
	gravity = 0
	velocity = Vector3.ZERO
	movement_velocity = Vector3.ZERO
