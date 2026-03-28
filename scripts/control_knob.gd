extends Area2D

var dragging = false
var offset = Vector2.ZERO

func _ready():
	# Ensure the Area2D can detect mouse input
	input_pickable = true

func _input_event(_viewport, event, _shape_idx):
	# Triggered when the mouse interacts with the CollisionShape2D
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start dragging and calculate how far the mouse is from the center
				dragging = true
				offset = global_position - get_global_mouse_position()
			else:
				# Stop dragging when button is released
				dragging = false

func _input(event):
	# Global input check to stop dragging even if the mouse leaves the collision shape
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			dragging = false

func _process(_delta):
	if dragging:
		# Update position while maintaining the initial click offset
		global_position = get_global_mouse_position() + offset
