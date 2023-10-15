extends CharacterBody2D

enum State
{
	IDLE,
	RUNNING,
	JUMP,
	FALL,
	LANDING,
	WALLSLIDING,
}

const GROUND_STATES := [State.IDLE,State.RUNNING,State.LANDING]
const RUN_SPEED := 160.0
const FLOOR_ACCELERATION := RUN_SPEED / 0.2
const AIR_ACCELERATION := RUN_SPEED / 0.02
const JUMP_VELOCITY := -320.0

var default_grivity = ProjectSettings.get("physics/2d/default_gravity") as float
#切换状态后的第一帧
var is_first_tick := false 
@onready var graphics: Node2D = $Graphics
@onready var animation_player = $AnimationPlayer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer
@onready var hand_check: RayCast2D = $Graphics/HandCheck
@onready var foot_check: RayCast2D = $Graphics/FootCheck


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_request_timer.start() 
	if event.is_action_released("jump"):
		jump_request_timer.stop()
		if velocity.y < velocity.y/2:
			velocity = velocity/2

func tick_physics(state:State,delta:float) -> void:
	match state:
		State.IDLE:
			move(default_grivity,delta)
		State.RUNNING:
			move(default_grivity,delta)
		State.JUMP:
			move(0.0 if is_first_tick else default_grivity,delta)
		State.FALL:
			move(default_grivity,delta)
		State.LANDING:
			move(default_grivity,delta)
		State.WALLSLIDING:
			move(default_grivity/3,delta)
			graphics.scale.x = get_wall_normal().x
	is_first_tick = false
			
func move(gravity:float, delta:float) -> void:
	var direction := Input.get_axis("ui_left","ui_right")
#	速度由快变慢,0.2s完成
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION;
	velocity.x = move_toward(velocity.x,direction*RUN_SPEED,acceleration*delta)
	velocity.y += gravity*delta	 
	
	if not is_zero_approx(direction):
		graphics.scale.x = -1 if direction < 0 else +1
	
	move_and_slide()

func stand(delta:float) -> void:
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION;
	velocity.x = move_toward(velocity.x,0.0,acceleration*delta)
	velocity.y += default_grivity*delta	 
	move_and_slide()

func get_next_state(state: State) -> State:
	var can_jump = is_on_floor() or coyote_timer.time_left > 0
	var should_jump = can_jump and jump_request_timer.time_left > 0
	if should_jump : return State.JUMP
	var direction := Input.get_axis("ui_left","ui_right")
	var is_still := is_zero_approx(direction) and is_zero_approx(velocity.x)
	
	match state:
		State.IDLE:
			if not is_on_floor():
				return State.FALL
			if not is_still:
				return State.RUNNING
		State.RUNNING:
			if not is_on_floor():
				return State.FALL
			if is_still:
				return State.IDLE
		State.JUMP:
			if velocity.y >= 0 :
				return State.FALL
		State.FALL:
			if is_on_floor():
				return State.LANDING if is_still else State.RUNNING
			if is_on_wall() and hand_check.is_colliding() and foot_check.is_colliding():
				return State.WALLSLIDING
		State.LANDING:
			if not is_still:
				return State.RUNNING
			if not animation_player.is_playing():
				return State.IDLE
		State.WALLSLIDING:
			if is_on_floor():
				return State.IDLE
			if not is_on_wall():
				return State.FALL
	return state
	pass
	
func transition_state(from: State,to: State) -> void:
	if from not in GROUND_STATES and to in GROUND_STATES :
		coyote_timer.stop()  
	
	match to:
		State.IDLE:
			animation_player.play("idle")
			print("idle")
		State.RUNNING:
			print("running")
			animation_player.play("running")
		State.JUMP:
			print("jump")
			animation_player.play("jump")
			velocity.y = JUMP_VELOCITY
			coyote_timer.stop()
			jump_request_timer.stop()
		State.FALL:	
			print("fall")
			animation_player.play("fall")
			if from in GROUND_STATES:
				coyote_timer.start()
		State.LANDING:
			print("landing")
			animation_player.play("landing")
		State.WALLSLIDING:
			print("WALLSLIDING")
			animation_player.play("wall_sliding")
	is_first_tick = true
	pass
	
