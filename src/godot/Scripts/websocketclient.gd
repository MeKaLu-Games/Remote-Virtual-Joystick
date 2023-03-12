extends Node

onready var global = $"/root/Global"
var client = WebSocketClient.new()
var is_close: bool = true
var server_label: Label

func _ready() -> void:
	client.connect("connection_closed", self, "_closed")
	client.connect("connection_error", self, "_closed")
	client.connect("connection_established", self, "_connected")
	client.connect("data_received", self, "_on_data")

func _closed(was_clean = false):
	# was_clean will tell you if the disconnection was correctly notified
	# by the remote peer before closing the socket.
	print("Closed, clean: ", was_clean)
	server_label.text = "Closed, clean: " + str(was_clean)
	is_close = true

func _connected(proto = ""):
	# This is called on connection, "proto" will be the selected WebSocket
	# sub-protocol (which is optional)
	print("Connected with protocol: ", proto)
	server_label.text = "Connected with protocol: " + str(proto)

	client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)

	send_data("Test Packet".to_utf8())

func _on_data():
	# Print the received packet, you MUST always use get_peer(1).get_packet
	# to receive data from server, and not get_packet directly when not
	# using the MultiplayerAPI.
	var data: String = client.get_peer(1).get_packet().get_string_from_utf8()
	var decoded = global.decode_data(data)

	server_label.text = "CLIENT: " + str(decoded)

	if decoded.size() == 1:
		if decoded[0] == "STOP":
			client.disconnect_from_host()
			#get_tree().quit()
		elif decoded[0] == "VIBRATE": Input.vibrate_handheld(global.DEFAULT_VIBRATION)
	elif decoded.size() == 2:
		if decoded[0] == "VIBRATE": Input.vibrate_handheld(decoded[1].to_float())

func establish_connection(port: int, ip: String) -> bool:
	# Initiate connection to the given URL.
	var err = client.connect_to_url("http://" + ip  + ":" + str(port))
	print(err)
	if err != OK:
		print("Unable to connect")
		is_close = true
		return false
	
	is_close = false
	return true

func send_data(data: PoolByteArray) -> void:
	if not is_close:
		client.get_peer(1).put_packet(data)

func poll() -> void:
	if not is_close:
		client.poll()

func close_connection() -> void:
	is_close = true
	client.disconnect_from_host()

