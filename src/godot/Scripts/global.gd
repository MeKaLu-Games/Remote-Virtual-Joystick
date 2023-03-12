extends Node

const PORT = 80
const IP = "<your ip adress>"
const PACKET_DELAY_TIME = 0.005
const DEFAULT_VIBRATION = 300

func encode_vector_data(data) -> PoolByteArray:
	if data is Vector2: return (str(data.x) + ":" + str(data.y)).to_utf8()
	elif data is Vector3: return (str(data.x) + ":" + str(data.y) + ":" + str(data.z)).to_utf8()
	return "null".to_utf8()

func decode_data(data: String) -> Array:
	if data == "null": return ["null"]
	var r := data.split(":", true, 0)
	var arr := []
	for b in r:
		if b.is_valid_float(): arr.append(float(b))
		else: arr.append(b)

	return arr

