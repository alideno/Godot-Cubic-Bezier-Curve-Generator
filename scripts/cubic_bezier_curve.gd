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
	points = [
			to_local(control_point1.global_position),
			to_local(control_point2.global_position),
			to_local(control_point3.global_position),
			to_local(control_point4.global_position)
			]
	interpolate(step_size)


func _process(_delta: float) -> void:
	
	if Engine.get_process_frames() % 2 == 0:
		for i in range(4):
			if to_local(control_points[i].global_position) != points[i]:
				points = [
						to_local(control_point1.global_position),
						to_local(control_point2.global_position),
						to_local(control_point3.global_position),
						to_local(control_point4.global_position)
						]
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
		var new_coord : Vector2 = Bezier(u)
		u = u + step 
		
		var dir = (new_coord - last_coord).normalized()
		var normal = Vector2(-dir.y, dir.x) * (width / 2.0)
		
		# Top and bottom left points
		vertices.push_back(last_coord + normal)
		vertices.push_back(last_coord - normal)
		last_coord = new_coord
	
	var final_vertices : PackedVector2Array = []
	var count = vertices.size()
	final_vertices.push_back(vertices[0])
	final_vertices.push_back(vertices[1])
	if collision:
		top_points.push_back(vertices[0])
		bottom_points.push_back(vertices[1])
	
	const PITY_RATE := 3 
	var pity_counter := 0
	
	
	for i in range(0,count-6, 6):
		var first_angle = deg_angle(vertices[i],vertices[i+2])
		var second_angle = deg_angle(vertices[i+2],vertices[i+4])
		
		if abs(first_angle - second_angle) <= 0.2:
			if pity_counter < PITY_RATE:
				pity_counter += 1
				continue
		
		for j in range(0,6):
			final_vertices.push_back(vertices[i+j])
			if collision:
				if j % 2 == 0: 
					top_points.append(vertices[i+j])
				else:
					bottom_points.append(vertices[i+j])
		
		if pity_counter == PITY_RATE:
			pity_counter = 0
			
	final_vertices.push_back(vertices[-2])
	final_vertices.push_back(vertices[-1])
	if collision:
		top_points.push_back(vertices[-2])
		bottom_points.push_back(vertices[-1])
	
	create_mesh(final_vertices)
	
	if collision:
		# Reverse the bottom points so the polygon draws a continuous loop
		bottom_points.reverse()

		# Combine them into one final array
		top_points.append_array(bottom_points)
		collision_shape.set_deferred("polygon", top_points)
		
	print("Initial vertex count: " + str(vertices.size()))
	print("Final vertex count: " + str(final_vertices.size()))



func create_mesh(vertices):
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arrays)
	mesh_instance.mesh = arr_mesh

func deg_angle(first: Vector2,second: Vector2) -> float:
	return rad_to_deg((first-second).angle())


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
