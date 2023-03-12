extends Node

onready var global = $"/root/Global"
onready var websocket = $WebsocketClient

export(NodePath) var server_label_path
export(String, "UDP", "Websocket") var connection_type = "UDP"

var client
var server_label: Label

func _ready() -> void:
	server_label = get_node(server_label_path)
	match connection_type:
		"UDP": 
			client = UDP_CLIENT.new()
			client.connect("on_data", self, "on_data")
		"Websocket": 
			client = websocket
			client.server_label = server_label

	yield(get_tree().create_timer(1.0), "timeout")
	if not client.establish_connection(global.PORT, global.IP):
		print("Failed to establish connection!")

func _process(_delta) -> void:
	client.poll()
	
func _exit_tree() -> void:
	client.close_connection()

func _notification(what) -> void:
	if what == NOTIFICATION_WM_QUIT_REQUEST:
		client.close_connection()
		get_tree().quit() # default behavior

func send_data(data: PoolByteArray) -> void:
	yield(get_tree().create_timer(global.PACKET_DELAY_TIME), "timeout")
	client.send_data(data)

func on_data(bytes) -> void:
	var decoded = global.decode_data(bytes.get_string_from_utf8())
	print("CLIENT: ", decoded)
	server_label.text = "CLIENT: " + bytes.get_string_from_utf8()

	match decoded.size():
		0: pass
		1: 
			if decoded[0] is String:
				if decoded[0] == "STOP": 
					client.close_connection()
				elif decoded[1] == "VIBRATE":
					Input.vibrate_handheld(global.DEFAULT_VIBRATION)
				else: pass # error
			else: pass # error
		2:
			if decoded[0] is String:
				if decoded[0] == "VIBRATE":
					Input.vibrate_handheld(decoded[1])
				else: pass # error
			else: pass # error
		_: pass #error
