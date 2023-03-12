class_name UDP_CLIENT

signal on_data(bytes)

var is_close: bool = true
var socket: PacketPeerUDP

func establish_connection(port: int, ip: String) -> bool:
	socket = PacketPeerUDP.new()

	if socket.connect_to_host(ip, port) != OK:
		return false
	is_close = false

	send_data("Test Packet".to_utf8())
	return true

func send_data(data: PoolByteArray) -> void:
	if not is_close:
		var _d = socket.put_packet(data)

func poll() -> void:
	if not is_close:
		if (socket.get_available_packet_count() > 0):
			var data = socket.get_packet()
			emit_signal("on_data", data)

func close_connection() -> void:
	if not is_close:
		is_close = true
		socket.close()
