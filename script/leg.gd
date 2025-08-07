extends Marker2D

@onready var joint_1: Marker2D = $joint1
@onready var joint_2: Marker2D = $joint1/joint2
@onready var hand: Marker2D = $joint1/joint2/hand

const MIN_DISTANCE = 52

var len_upper = 0
var len_middle = 0
var len_lower = 0

@export var flipped = true

var goal_pos = Vector2()
var int_pos = Vector2()
var start_pos = Vector2()
var step_height = 18
var step_rate =  0.3
var step_time = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	len_upper = joint_1.position.x
	len_middle = joint_2.position.x
	len_lower = hand.position.x
	
	if flipped:
		$Sprite2D.flip_h = true
		joint_1.get_node("Sprite2D").flip_h = true
		joint_2.get_node("Sprite2D").flip_h = true
		

func _physics_process(delta: float) -> void:
	step_time += delta
	var target_pos = Vector2()
	var t = step_time / step_rate
	if t < 0.5:
		target_pos = start_pos.lerp(int_pos, t / 0.5)
	elif t < 1.0:
		target_pos = int_pos.lerp(goal_pos, (t - 0.5) / 0.5)
	else:
		target_pos = goal_pos
	update_ik(target_pos)

func step(g_pos):
	if goal_pos == g_pos:
		return
	goal_pos = g_pos
	var hand_pos = hand.global_position
	var highest = goal_pos.y
	if hand_pos.y < highest:
		highest = hand_pos.y
	var mid = (goal_pos.x + hand_pos.x) / 2.0
	start_pos = hand_pos
	int_pos = Vector2(mid, highest - step_height)
	step_time = 0.0
 

func update_ik(target_pos):
	var offset = target_pos - global_position
	var dist_to_target = offset.length()
	if dist_to_target < MIN_DISTANCE:
		offset = (offset / dist_to_target) * MIN_DISTANCE
		dist_to_target = MIN_DISTANCE
	var base_r = offset.angle()
	var len_total = len_upper + len_middle + len_lower
	var len_dummy_side = (len_upper + len_middle) * clamp(dist_to_target / len_total, 0.0, 1.0)
	
	var base_angles = SSS_calc(len_dummy_side, len_lower, dist_to_target)
	var next_angles = SSS_calc(len_upper, len_middle, len_dummy_side)
	
	global_rotation = base_angles.B + next_angles.B + base_r
	joint_1.rotation = next_angles.C
	joint_2.rotation = base_angles.C + next_angles.A

func SSS_calc(side_a,side_b,side_c):
	if side_c >= side_a + side_b:
		return {"A": 0, "B": 0, "C": 0}
	var angle_a = law_of_cosine(side_b, side_c, side_a)
	var angle_b = law_of_cosine(side_c, side_a, side_b) + PI
	var angle_c = PI - angle_a - angle_b
	
	if flipped:
		angle_a = -angle_a
		angle_b = -angle_b
		angle_c = -angle_c
	return {"A": angle_a, "B": angle_b, "C": angle_c}


func law_of_cosine(a,b,c):
	if 2*a*b == 0:
		return 0
	return acos((a*a + b*b - c*c)/(2*a*b))
