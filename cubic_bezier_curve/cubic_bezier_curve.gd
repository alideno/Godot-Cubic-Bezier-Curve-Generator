@tool
extends Node2D

@export var control_point1: Marker2D
@export var control_point2: Marker2D
@export var control_point3: Marker2D
@export var control_point4: Marker2D

@export var step_size: float = 0.001
@export var width: float = 1.0

@export var collision: bool = false

@export var texture_repeat_dist: float

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

## Final refined interpolate for smooth, tiled, and simplified Bezier geometry
func interpolate(step: float) -> void:
	var step_count : int = int(1.0 / step)
	var last_coord : Vector2 = Bezier(0)
	
	var vertices : PackedVector2Array = []
	var uvs : PackedVector2Array = []
	var top_points : PackedVector2Array = []
	var bottom_points : PackedVector2Array = []

	# 1. Pre-calculate Total Length for tiling
	var total_length : float = 0.0
	var temp_last = last_coord
	for i in range(1, step_count + 1):
		var p = Bezier(i * step)
		total_length += temp_last.distance_to(p)
		temp_last = p
	
	var tiling_factor : float = 1.0
	if mesh_instance.texture:
		var tex_size = mesh_instance.texture.get_size()
		var aspect_ratio = tex_size.x / tex_size.y
		# This ensures the texture doesn't stretch vertically
		tiling_factor = 1.0 / (width * aspect_ratio)

	# 2. Explicitly handle the start (t=0) to prevent smear
	var start_dir = (Bezier(0.001) - last_coord).normalized()
	var start_normal = Vector2(-start_dir.y, start_dir.x) * (width / 2.0)
	
	vertices.push_back(last_coord + start_normal)
	vertices.push_back(last_coord - start_normal)
	uvs.push_back(Vector2(0.0, 0.0))
	uvs.push_back(Vector2(0.0, 1.0))

	# 3. Generate raw pairs based on distance
	var current_dist : float = 0.0
	for i in range(1, step_count + 1):
		var t = clamp(i * step, 0.0, 1.0)
		var new_coord : Vector2 = Bezier(t)
		
		# Direction based on previous point to current point
		var dir = (new_coord - last_coord).normalized()
		var normal = Vector2(-dir.y, dir.x) * (width / 2.0)
		
		current_dist += last_coord.distance_to(new_coord)
		var uv_x = current_dist * tiling_factor
		
		vertices.push_back(new_coord + normal)
		vertices.push_back(new_coord - normal)
		uvs.push_back(Vector2(uv_x, 0.0))
		uvs.push_back(Vector2(uv_x, 1.0))
		
		last_coord = new_coord

	# 4. Simplification Logic (Pity Counter)
	var final_vertices : PackedVector2Array = []
	var final_uvs : PackedVector2Array = []
	
	# Always keep the start pair
	final_vertices.push_back(vertices[0])
	final_vertices.push_back(vertices[1])
	final_uvs.push_back(uvs[0])
	final_uvs.push_back(uvs[1])
	
	if collision:
		top_points.push_back(vertices[0])
		bottom_points.push_back(vertices[1])

	const PITY_RATE := 3 
	var pity_counter := 0
	
	# Loop through raw pairs (step by 2)
	for i in range(2, vertices.size() - 2, 2):
		var prev = vertices[i-2]
		var curr = vertices[i]
		var next = vertices[i+2]
		
		var angle_diff = abs(deg_angle(prev, curr) - deg_angle(curr, next))
		
		# If it's a straight line, count pity and skip
		if angle_diff <= 0.2 and pity_counter < PITY_RATE:
			pity_counter += 1
			continue
		
		# Keep points at curves or when pity is up
		pity_counter = 0
		final_vertices.push_back(vertices[i])
		final_vertices.push_back(vertices[i+1])
		final_uvs.push_back(uvs[i])
		final_uvs.push_back(uvs[i+1])
		
		if collision:
			top_points.append(vertices[i])
			bottom_points.append(vertices[i+1])
			
	# Always keep the end pair
	final_vertices.push_back(vertices[-2])
	final_vertices.push_back(vertices[-1])
	final_uvs.push_back(uvs[-2])
	final_uvs.push_back(uvs[-1])
	
	if collision:
		top_points.push_back(vertices[-2])
		bottom_points.push_back(vertices[-1])

	# 5. Application
	create_mesh(final_vertices, final_uvs) 
	
	if collision:
		bottom_points.reverse()
		top_points.append_array(bottom_points)
		collision_shape.set_deferred("polygon", top_points)

func create_mesh(vertices: PackedVector2Array, uvs: PackedVector2Array):
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs # Assign UVs here
	
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
