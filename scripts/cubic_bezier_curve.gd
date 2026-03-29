extends Node2D

@export var control_point1: Marker2D
@export var control_point2: Marker2D
@export var control_point3: Marker2D
@export var control_point4: Marker2D

@export var step_size: float = 0.001
@export var width: float = 1.0
@export var color: Color = Color.WHITE

@export var collision: bool = false

var shader_res = preload("res://circle.gdshader")

@onready var collision_shape : CollisionPolygon2D = $CollisionPolygon2D
@onready var mesh_instance : MeshInstance2D = $MeshInstance2D

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

## Given the step size creates a cruve with 1/step points
func interpolate(step: float) -> void:
	# The S in SOLID principles refers to "Single responsibility principle"
	# I hate OOP thus we do everything in this function
	var step_count : int = (1/step) - 1
	
	var last_coord : Vector2 = Bezier(0)
	#mark_point(last_coord)
	var u = step
	
	var top_points : PackedVector2Array = []
	var bottom_points : PackedVector2Array = []
	
	var vertices : PackedVector2Array = []

	
	for i in range(step_count):
		# Constant for every rectangle
		var colorRect : ColorRect = ColorRect.new()
		#add_child(colorRect)
		
		
		var new_coord : Vector2 = Bezier(u)
		
		
		# Used to calculate the size of the rectangle
		var distance : float = last_coord.distance_to(new_coord)
		colorRect.pivot_offset = Vector2(distance/2,width/2)
		colorRect.size = Vector2(distance,width)
		
		
		# The position of the rectangle
		colorRect.global_position = last_coord
		
		# Used to calculate the rotation of the rectangle
		var angle = (last_coord-new_coord).angle()
		colorRect.rotation = angle
		
		if collision:
			# Get the Transform
			var xform = get_global_transform().affine_inverse() * colorRect.get_global_transform()
			var s = colorRect.size

			# Collect top vertices (moving forward)
			top_points.append(xform * Vector2(0, 0))
			top_points.append(xform * Vector2(s.x, 0))

			# Collect bottom vertices (moving forward, will reverse later)
			bottom_points.append(xform * Vector2(s.x, s.y))
			bottom_points.append(xform * Vector2(0, s.y))
		
		#mark_point(new_coord)
		var xform = get_global_transform().affine_inverse() * colorRect.get_global_transform()
		var s = colorRect.size
		
		# 0,0    s.x,0
		# 0,s.y  s.x,s.y
		
		
		vertices.push_back(xform * Vector2(0, 0))
		vertices.push_back(xform * Vector2(s.x, 0))
		vertices.push_back(xform * Vector2(0, s.y))
		# Needed if PRIMITIVE_TRIANGLE
		#vertices.push_back(xform * Vector2(s.x, 0))
		#vertices.push_back(xform * Vector2(0, s.y))
		vertices.push_back(xform * Vector2(s.x, s.y))
		
		
		
		u = u + step  
		last_coord = new_coord
	
	create_mesh(vertices)
	
	if collision:
		# Reverse the bottom points so the polygon draws a continuous loop
		bottom_points.reverse()

		# Combine them into one final array
		var full_hull : PackedVector2Array = top_points
		full_hull.append_array(bottom_points)
		collision_shape.polygon = full_hull



func create_mesh(vertices):
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arrays)
	mesh_instance.mesh = arr_mesh




## Returns the point the curve is at t, 0 <= t <= 1
func Bezier(t: float) -> Vector2:
	if t < 0 or t > 1:
		print("t value out of range, t = " + str(t))
		return Vector2.ZERO
		
	var omt : float = 1-t # One Minus T (OMT)
	var point = pow(omt,3)*points[0] + 3*pow(omt,2)*t*points[1] + 3*omt*pow(t,2)*points[2] + pow(t,3)*points[3]
	
	return point

## Debug Tool
func mark_point(point: Vector2) -> void:
	var debug_size = 20.0
	var colorRect : ColorRect = ColorRect.new()
	colorRect.color = Color(0.0, 0.0, 0.0, 1.0)
	colorRect.pivot_offset = Vector2(debug_size/2,debug_size/2)
	colorRect.size = Vector2(debug_size,debug_size)
	colorRect.position = point
	add_child(colorRect)

## Clear EVERYTHING related to the curve (except itself)
func clear_all() -> void:
	if get_child_count() == 0:
		return
	
	for child in get_children():
		if child == collision_shape || child == mesh_instance:
			continue
		child.queue_free()
		
