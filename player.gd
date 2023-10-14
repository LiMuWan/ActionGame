extends CharacterBody2D

const RUN_SPEED := 160.0
const FLOOR_ACCELERATION := RUN_SPEED / 0.2
const AIR_ACCELERATION := RUN_SPEED / 0.02
const JUMP_VELOCITY := -320.0

var grivity = ProjectSettings.get("physics/2d/default_gravity") as float
@onready var sprite_2d = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_request_timer.start() 
	if event.is_action_released("jump"):
		jump_request_timer.stop()
		if velocity.y < velocity.y/2:
			velocity = velocity/2

func _physics_process(delta):
	var direction := Input.get_axis("ui_left","ui_right")
#	速度由快变慢,0.2s完成
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION;
	velocity.x = move_toward(velocity.x,direction*RUN_SPEED,acceleration*delta)
	velocity.y += grivity*delta	 
	var can_jump = is_on_floor() or coyote_timer.time_left > 0
	var should_jump = can_jump and jump_request_timer.time_left > 0
	if should_jump:
		velocity.y = JUMP_VELOCITY
		coyote_timer.stop()
		jump_request_timer.stop()
		
	if is_on_floor():
		if is_zero_approx(direction) and is_zero_approx(velocity.x):
			animation_player.play("idle")
		else:
			animation_player.play("running")
	else:
		animation_player.play("jump")
	
	if not is_zero_approx(direction):
		sprite_2d.flip_h = direction < 0
	
	var was_on_floor := is_on_floor()	
	move_and_slide()
	if was_on_floor != is_on_floor():
		if was_on_floor and not should_jump:
			coyote_timer.start()
		else:
			coyote_timer.stop()


