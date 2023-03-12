extends Node2D

onready var global = $"/root/Global"

onready var client  = $Client

onready var t_server = $Control/Server
onready var s_icon = $Icon

onready var b_stop = $Control/Button_STOP

onready var s_trigger_l = $Control/Trigger_L
onready var s_trigger_r = $Control/Trigger_R

onready var b_gamepad = [
	$Control/Button_A,
	$Control/Button_B,
	$Control/Button_X,
	$Control/Button_Y,
]

# A B X Y
var b_timer := [
	Timer.new(),
	Timer.new(),
	Timer.new(),
	Timer.new(),
]

var input_area: Vector2 = Vector2.ZERO
var mouse_position: Vector2 = Vector2.ZERO
var relative_position: Vector2 = Vector2.ZERO

var velocity: Vector3 = Vector3.ZERO
var smooth_velocity: Vector3 = Vector3.ZERO

var is_pressing: bool = true

func _ready() -> void:
	input_area = get_viewport_rect().size

	for i in range(b_timer.size()):
		var b = b_timer[i]
		b.connect("timeout", self, "_b_down_timeout", [i])
		add_child(b)

	for b in b_gamepad:
		b.connect("button_down", self, "_gamepad_down", [b.name])
		b.connect("button_up", self, "_gamepad_up", [b.name])

	b_stop.connect("pressed", self, "_stop_pressed")

	s_trigger_l.connect("value_changed", self, "_trigger_l")
	s_trigger_r.connect("value_changed", self, "_trigger_r")


func _b_down_timeout(id) -> void:
	if id == 0: 
		client.send_data("HOLD:A".to_utf8())
	elif id == 1: 
		client.send_data("HOLD:B".to_utf8())
	elif id == 2: 
		client.send_data("HOLD:X".to_utf8())
	elif id == 3: 
		client.send_data("HOLD:Y".to_utf8())
		
func _gamepad_down(name) -> void:
	var id = name[name.length() - 1]

	var time := 0.04

	if id == "A": b_timer[0].start(time)
	elif id == "B": b_timer[1].start(time)
	elif id == "X": b_timer[2].start(time)
	elif id == "Y": b_timer[3].start(time)

func _gamepad_up(name) -> void:
	var id = name[name.length() - 1]

	if id == "A": 
		b_timer[0].stop()
		client.send_data("RELEASE:A".to_utf8())
	elif id == "B": 
		b_timer[1].stop()
		client.send_data("RELEASE:B".to_utf8())
	elif id == "X": 
		b_timer[2].stop()
		client.send_data("RELEASE:X".to_utf8())
	elif id == "Y": 
		b_timer[3].stop()
		client.send_data("RELEASE:Y".to_utf8())

func _stop_pressed() -> void:
	client.send_data("STOP".to_ascii())

func _trigger_l(value: float) -> void:
	if value != 0: value = value / 100
	client.send_data(("LEFT_JOYSTICK_X:" + str(value)).to_utf8())

func _trigger_r(value: float) -> void:
	if value != 0: value = value / 100
	client.send_data(("LEFT_JOYSTICK_Y:" + str(value)).to_utf8())

func _input(event) -> void:
	if event is InputEventMouseButton:
		if event.pressed: is_pressing = true
		else: is_pressing = false
	elif event is InputEventMouseMotion:
		if is_pressing: 
			mouse_position = event.position
			relative_position = mouse_position - (input_area / 2)
			#s_icon.position = relative_position
			#client.send_data(encode_vector_data(relative_position))

func _process(delta) -> void:
	var acc = Input.get_accelerometer()
	var grav = Input.get_gravity()
	var mag = Input.get_magnetometer()
	var gyro = Input.get_gyroscope()

	# Check if we have all needed data
	if grav.length() < 0.1:
		if acc.length() < 0.1:
			# we don't have either...
			grav = Vector3(0.0, -1.0, 0.0)
		else:
			# The gravity vector is calculated by the OS by combining the other sensor inputs.
			# If we don't have a gravity vector, from now on, use accelerometer...
			grav = acc

	if mag.length() < 0.1:
		mag = Vector3(1.0, 0.0, 0.0)
	
	var gyro_and_grav = Basis()
	var new_basis = rotate_by_gyro(gyro, gyro_and_grav, delta).orthonormalized()
	gyro_and_grav = drift_correction(new_basis, grav)

	velocity.x = (acc.normalized()).x
	velocity.y = gyro_and_grav.transposed().z.y
	velocity.z = gyro_and_grav.transposed().z.z

#	velocity.x = -acc.x
#	velocity.y = acc.y
#	velocity.z = acc.z

func get_average_vel(seconds: float, delta: float) -> Vector3:
	var avg := Vector3.ZERO

	var c := Vector3.ZERO
	var i: float = 0
	while (i < seconds):
		c += velocity
		i += delta

	avg = c / i
	return avg

func _physics_process(delta) -> void:
	var value = get_average_vel(0.01, delta)
	smooth_velocity = lerp(smooth_velocity, value, 0.6)	
	var data = smooth_velocity * delta
	client.send_data(global.encode_vector_data(data))


# Stol- Yoinked from godot examples 
# Below are a number of helper functions that show how you can use the raw sensor data to determine the orientation
# of your phone/device. The cheapest phones only have an accelerometer only the most expensive phones have all three.
# Note that none of this logic filters data. Filters introduce lag but also provide stability. There are plenty
# of examples on the internet on how to implement these. I wanted to keep this straight forward.

# We draw a few arrow objects to visualize the vectors and two cubes to show two implementation for orientating
# these cubes to our phones orientation.
# This is a 3D example however reading the phones orientation is also invaluable for 2D

# This function calculates a rotation matrix based on a direction vector. As our arrows are cylindrical we don't
# care about the rotation around this axis.
func get_basis_for_arrow(p_vector):
	var rotate = Basis()

	# as our arrow points up, Y = our direction vector
	rotate.y = p_vector.normalized()

	# get an arbitrary vector we can use to calculate our other two vectors
	var v = Vector3(1.0, 0.0, 0.0)
	if abs(v.dot(rotate.y)) > 0.9:
		v = Vector3(0.0, 1.0, 0.0)

	# use our vector to get a vector perpendicular to our two vectors
	rotate.x = rotate.y.cross(v).normalized()

	# and the cross product again gives us our final vector perpendicular to our previous two vectors
	rotate.z = rotate.x.cross(rotate.y).normalized()

	return rotate

# This function combines the magnetometer reading with the gravity vector to get a vector that points due north
func calc_north(p_grav, p_mag):
	# Always use normalized vectors!
	p_grav = p_grav.normalized()

	# Calculate east (or is it west) by getting our cross product.
	# The cross product of two normalized vectors returns a vector that
	# is perpendicular to our two vectors
	var east = p_grav.cross(p_mag.normalized()).normalized()

	# Cross again to get our horizon aligned north
	return east.cross(p_grav).normalized()

# This function creates an orientation matrix using the magnetometer and gravity vector as inputs.
func orientate_by_mag_and_grav(p_mag, p_grav):
	var rotate = Basis()

	# as always, normalize!
	p_mag = p_mag.normalized()

	# gravity points down, so - gravity points up!
	rotate.y = -p_grav.normalized()

	# Cross products with our magnetic north gives an aligned east (or west, I always forget)
	rotate.x = rotate.y.cross(p_mag)

	# And cross product again and we get our aligned north completing our matrix
	rotate.z = rotate.x.cross(rotate.y)

	return rotate

# This function takes our gyro input and update an orientation matrix accordingly
# The gyro is special as this vector does not contain a direction but rather a
# rotational velocity. This is why we multiply our values with delta.
func rotate_by_gyro(p_gyro, p_basis, p_delta):
	var rotate = Basis()

	rotate = rotate.rotated(p_basis.x, -p_gyro.x * p_delta)
	rotate = rotate.rotated(p_basis.y, -p_gyro.y * p_delta)
	rotate = rotate.rotated(p_basis.z, -p_gyro.z * p_delta)

	return rotate * p_basis

# This function corrects the drift in our matrix by our gravity vector
func drift_correction(p_basis, p_grav):
	# as always, make sure our vector is normalized but also invert as our gravity points down
	var real_up = -p_grav.normalized()

	# start by calculating the dot product, this gives us the cosine angle between our two vectors
	var dot = p_basis.y.dot(real_up)

	# if our dot is 1.0 we're good
	if dot < 1.0:
		# the cross between our two vectors gives us a vector perpendicular to our two vectors
		var axis = p_basis.y.cross(real_up).normalized()
		var correction = Basis(axis, acos(dot))
		p_basis = correction * p_basis

	return p_basis
