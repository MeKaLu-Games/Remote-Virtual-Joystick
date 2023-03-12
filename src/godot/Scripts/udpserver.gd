class_name UDP_SERVER

signal on_data(bytes)

var is_close: bool = true
var socket: UDPServer
var peers: Array = []

func open_connection(port: int, ip: String) -> bool:
	socket = UDPServer.new()
	if socket.listen(port, ip) != OK:
		return false
	is_close = false
	return true

func send_data(data: PoolByteArray) -> void:
	if not is_close:
		for p in peers: var _d = p.put_packet(data)

func poll() -> void:
	if not is_close:
		var _d = socket.poll()

		# new peer connected
		if (socket.is_connection_available()):
			var peer := socket.take_connection()
			var pkt = peer.get_packet()
			emit_signal("on_data", pkt)
			peers.append(peer)
		
		# get packets
		for p in peers:
			var pkt = p.get_packet()
			if pkt:	emit_signal("on_data", pkt)

func close_connection() -> void:
	if not is_close:
		is_close = true
		peers = []
		socket.stop()