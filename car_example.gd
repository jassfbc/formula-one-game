extends Node3D

# Node references
@onready var ball: RigidBody3D = $Ball
@onready var car_mesh: Node3D = $CarMesh
@onready var ground_ray: RayCast3D = $GroundRay
@onready var camera_pivot: Node3D = $CarMesh/CameraPivot
@onready var camera_3d: Camera3D = $CarMesh/CameraPivot/Camera3D

# Mesh references
@onready var right_wheel : MeshInstance3D = $"CarMesh/wheel-front-right"
@onready var left_wheel : MeshInstance3D = $"CarMesh/wheel-front-left"
@onready var body_mesh : MeshInstance3D = $"CarMesh/body"


# Where to place the car mesh relative to the rigid body sphere
@export var sphere_offset : Vector3 = Vector3(0, -1.0, 0)
# Engine power
@export var acceleration : float = 50.0
# Turn amount in degrees
@export var steering : float = 21.0
# How quickly the car turns
@export var turn_speed : float = 5.0
# Below this speed the car doesn't turn
@export var turn_stop_limit : float = 0.75
# Amount to tilt the body on turns
@export var body_tilt: float = 35

# Variables for input values
var speed_input : float = 0.0
var rotate_input : float = 0.0

func _ready():
	ground_ray.add_exception(ball)

func _physics_process(delta: float) -> void:
	# Keep the car mesh aligned with the rigid body sphere
	car_mesh.transform.origin = ball.transform.origin + sphere_offset
	# Accelerate based on car's forward direction
	ball.apply_central_force(-car_mesh.global_transform.basis.z * speed_input)

func _process(delta: float) -> void:
	# Can't accelerate/steer when in the air
	if not ground_ray.is_colliding():
		return
	# Get accelerate/brake input
	speed_input = 0.0
	speed_input -= Input.get_action_strength("accelerate")
	speed_input += Input.get_action_strength("brake")
	speed_input *= acceleration
	# Get steering input
	rotate_input = 0.0
	rotate_input += Input.get_action_strength("steer_left")
	rotate_input -= Input.get_action_strength("steer_right")
	rotate_input *= deg_to_rad(steering)
	
	# Rotate the wheels
	right_wheel.rotation.y = rotate_input
	left_wheel.rotation.y = rotate_input
	
	# Rotate car mesh
	if ball.linear_velocity.length() > turn_stop_limit:
		var new_basis = car_mesh.global_transform.basis.rotated(car_mesh.global_transform.basis.y, rotate_input)
		car_mesh.global_transform.basis = car_mesh.global_transform.basis.slerp(new_basis, turn_speed * delta)
		car_mesh.global_transform = car_mesh.global_transform.orthonormalized()
		# Tilt the body
		var tilt = -rotate_input * ball.linear_velocity.length() / body_tilt
		body_mesh.rotation.z = lerp(body_mesh.rotation.z, tilt, 10 * delta)
	
	# Align with the ground
	var ground_ray_normal = ground_ray.get_collision_normal()
	var xform = align_with_y(car_mesh.global_transform, ground_ray_normal.normalized())
	car_mesh.global_transform = car_mesh.global_transform.interpolate_with(xform, 10 * delta)

func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform
