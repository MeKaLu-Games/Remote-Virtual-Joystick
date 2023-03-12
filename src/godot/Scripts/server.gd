extends Node

onready var global = $"/root/Global"
export(NodePath) var server_label_path

var server = UDP_SERVER.new()
var server_label: Label
var vigem: LibVigem
var left_joystick: Vector2

func _ready() -> void:
	server_label = get_node(server_label_path)
	server.connect("on_data", self, "on_data")
	if not server.open_connection(global.PORT, global.IP):
		print("Failed to open connection!")

	vigem = LibVigem.new()
	if not vigem.connect_device():
		print("Failed to connect (virtual)device")
	
func _process(_delta) -> void:
	server.poll()

func _exit_tree() -> void:
	close_connection()

func _notification(what) -> void:
	if what == NOTIFICATION_WM_QUIT_REQUEST:
		close_connection()
		get_tree().quit() # default behavior

func close_connection() -> void:
	vigem.disconnect_device()
	server.close_connection()

func send_data(data: PoolByteArray, no_wait: bool = false) -> void:
	if not no_wait: yield(get_tree().create_timer(global.PACKET_DELAY_TIME), "timeout")
	server.send_data(data)

func on_data(bytes) -> void:
	var decoded = global.decode_data(bytes.get_string_from_utf8())	
	print("SERVER: ", decoded)

	var data_queue := []
	var echo := false

	match decoded.size():
		0: pass
		1: 
			if decoded[0] is String:
				if decoded[0] == "STOP": 
					send_data("VIBRATE:300".to_utf8())
					vigem.reset()
					vigem.disconnect_device()
					yield(get_tree().create_timer(0.5), "timeout")
					close_connection()
				else: pass # error
			else: pass # error
			echo = true
		2: 
			if decoded[0] is String:
				if "LEFT_JOYSTICK_" in decoded[0]:
					if decoded[0].ends_with("X"):
						left_joystick.x = decoded[1]
					elif decoded[0].ends_with("Y"):
						left_joystick.y = decoded[1]
					else: pass # error
					vigem.left_joystick(left_joystick.x, left_joystick.y)
					data_queue.append("VIBRATE:50")
				elif decoded[1] is String:
					if decoded[0] == "HOLD":
						if decoded[1] == "A": vigem.button_a(true)
						elif decoded[1] == "B": vigem.button_b(true)
						elif decoded[1] == "X": vigem.button_x(true)
						elif decoded[1] == "Y": vigem.button_y(true)
					elif decoded[0] == "RELEASE":
						if decoded[1] == "A": vigem.button_a(false)
						elif decoded[1] == "B": vigem.button_b(false)
						elif decoded[1] == "X": vigem.button_x(false)
						elif decoded[1] == "Y": vigem.button_y(false)
					data_queue.append("VIBRATE:10")
				else: pass # error
			else: pass # error
			echo = true
		3:
			if decoded[0] is float:
				if decoded[1] is float:
					if decoded[2] is float:
						vigem.right_joystick(decoded[0], -decoded[1])
					else: pass # error
				else: pass # error
			else: pass # error

	vigem.update()
	
	if data_queue.size() > 0:
		if echo: 
			server_label.text = "SERVER: " + bytes.get_string_from_utf8()
			send_data(bytes, true)
		print(data_queue)
		for d in data_queue:
			var byte: PoolByteArray
			if d is String: byte = d.to_utf8()
			else: byte = str(d).to_utf8()
			send_data(byte, true)
			print(d)
		yield(get_tree().create_timer(global.PACKET_DELAY_TIME), "timeout")
	elif echo: send_data(bytes)
