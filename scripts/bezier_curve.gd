extends Node2D

@export var control_point1: Marker2D
@export var control_point2: Marker2D
@export var control_point3: Marker2D
@export var control_point4: Marker2D

@export var step_size: float = 0.01
@export var square_size: float = 1.0
@export var square_color: Color = Color.WHITE

var shader_res = preload("res://circle.gdshader")

var points: Array # List of the control point coordinates
var control_points: Array

func _ready() -> void:
	control_points = [control_point1,control_point2,control_point3,control_point4]
	points = [control_point1.global_position,control_point2.global_position,control_point3.global_position,control_point4.global_position]
	interpolate(step_size)
	


func _process(_delta: float) -> void:
	
	for i in range(4):
		if control_points[i].global_position != points[i]:
			clear_all()
			points = [control_point1.global_position,control_point2.global_position,control_point3.global_position,control_point4.global_position]
			interpolate(step_size)
			return

func interpolate(step: float) -> void:
	var step_count : int = (1/step) - 1
	
	var last_coord : Vector2 = Bezier(0)
	#mark_point(last_coord)
	var u = step
	
	for i in range(step_count):
		# Constant for every rectangle
		var colorRect : ColorRect = ColorRect.new()
		add_child(colorRect)
		colorRect.color = square_color
		
		
		var new_coord : Vector2 = Bezier(u)
		
		# Used to calculate the size of the rectangle
		var distance : float = last_coord.distance_to(new_coord)
		colorRect.pivot_offset = Vector2(distance/2,square_size/2)
		colorRect.size = Vector2(distance,square_size)
		
		
		# The position of the rectangle
		colorRect.global_position = last_coord
		
		# Used to calculate the rotation of the rectangle
		var angle = (last_coord-new_coord).angle()
		colorRect.rotation = angle
		
		
		#mark_point(new_coord)
		u = u + step  
		last_coord = new_coord

# Returns the point the curve is at t, 0 <= t <= 1
func Bezier(t: float) -> Vector2:
	if t < 0 or t > 1:
		print("t value out of range, t = " + str(t))
		return Vector2.ZERO
		
	var omt : float = 1-t # One Minus T (OMT)
	var point = pow(omt,3)*points[0] + 3*pow(omt,2)*t*points[1] + 3*omt*pow(t,2)*points[2] + pow(t,3)*points[3]
	
	return point
	
func mark_point(point: Vector2) -> void:
	var debug_size = 20.0
	var colorRect : ColorRect = ColorRect.new()
	colorRect.color = Color(0.0, 0.0, 0.0, 1.0)
	colorRect.pivot_offset = Vector2(debug_size/2,debug_size/2)
	colorRect.size = Vector2(debug_size,debug_size)
	colorRect.position = point
	add_child(colorRect)

func clear_all() -> void:
	if get_child_count() == 0:
		return
	
	for child in get_children():
		child.queue_free()
