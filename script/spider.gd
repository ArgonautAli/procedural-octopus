extends CharacterBody2D

@onready var low_mid_check: RayCast2D = $LowMidCheck
@onready var high_mid_check: RayCast2D = $HighMidCheck
@onready var front_check: RayCast2D = $FrontCheck
@onready var back_check: RayCast2D = $BackCheck
@onready var front_mid_check: RayCast2D = $FrontMidCheck
@onready var back_mid_check: RayCast2D = $BackMidCheck

@onready var front_leg_node: Node2D = $FrontLegs
@onready var back_leg_node: Node2D = $BackLegs

@onready var front_up_check: RayCast2D = $FrontUpCheck
@onready var body_up_check: RayCast2D = $BodyUpCheck

@onready var front_crouch_check: RayCast2D = $FrontCrouchCheck

var front_legs = []
var back_legs = []


@export var x_speed = 25
@export var y_speed = 20
@export var step_rate = 0.3

var time_since_last_step = 0
var cur_f_leg = 0
var cur_b_leg = 0
var use_front = false

@export var base_height := 40
@export var duck_height := 85.0
@export var rise_height := 40.0
@export var smooth_height := 5.0

var target_height := 0.0
var current_height := 0.0
var base_y := 0.0

var stay_down := false

func _ready():
	base_y = global_position.y
	front_legs = front_leg_node.get_children()
	back_legs = back_leg_node.get_children()
	front_crouch_check.force_raycast_update()
	for i in range(8):
		step()

func _draw() -> void:
	#draw_line(Vector2.ZERO, front_mid_check.target_position, Color.RED)
	#draw_line(Vector2.ZERO, back_mid_check.target_position, Color.BLUE)
	#draw_line(Vector2.ZERO, front_up_check.target_position, Color.BLUE)
	#draw_line(Vector2.ZERO, body_up_check.target_position, Color.RED)
	draw_line(Vector2.ZERO, front_crouch_check.target_position, Color.RED)

func _physics_process(delta):
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - global_position).normalized()
	var move_vec = dir * x_speed

	# --- Anchoring the body in world space (original logic) ---
	if high_mid_check.is_colliding():
		move_vec.y = -y_speed  # move upward to avoid ceiling
	elif !low_mid_check.is_colliding():
		move_vec.y = y_speed   # move downward to reach ground
		
	if stay_down == true:
		current_height = lerp(current_height, duck_height, delta * smooth_height)
	# --- Bracing the pose based on what's ahead (new logic) ---
	var moving_forward = dir.x >= 0.0
	var obstacle_ahead = front_mid_check.is_colliding()  || body_up_check.is_colliding() || front_up_check.is_colliding() if moving_forward else back_mid_check.is_colliding()
	var ledge_ahead    = !front_mid_check.is_colliding() if moving_forward else !back_mid_check.is_colliding()
	var cant_crouch = front_crouch_check.is_colliding()
	print("cant crouch: ", cant_crouch)
	if obstacle_ahead:
		stay_down = true
		target_height = duck_height
	elif ledge_ahead:
		target_height = rise_height
		stay_down = false
	elif cant_crouch:
		jump()
	else:
		target_height = base_height
	current_height     = lerp(current_height, target_height, delta * smooth_height)
	global_position.y  = base_y + current_height
	move_and_collide(move_vec * delta)


func _process(delta):
	time_since_last_step += delta
	if time_since_last_step >= step_rate:
		time_since_last_step = 0
		step()
 

func step():
	if front_legs.is_empty() or back_legs.is_empty():
		print("Leg lists not initialized yet")
		return
	var leg = null
	var sensor = null
	if use_front:
		leg = front_legs[cur_f_leg]
		cur_f_leg += 1
		cur_f_leg %= front_legs.size()
		sensor = front_check
	else:
		leg = back_legs[cur_b_leg]
		cur_b_leg += 1
		cur_b_leg %= back_legs.size()
		sensor = back_check
	use_front = !use_front
	var target = sensor.get_collision_point()
	leg.step(target)

# test

func jump():
	print("jump!")
