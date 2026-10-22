extends Node

const Ghost := preload("res://objects/ghost.tscn")
const GhostScript := preload("res://objects/ghost.gd")
const Player := preload("res://scripts/player.gd")

@export var websocket_url = "ws://localhost:9090"
#@export var websocket_url = "wss://gdu.socksdev.win"

var socket := WebSocketPeer.new()
var state: WebSocketPeer.State = WebSocketPeer.STATE_CLOSED

var players := {}
var ghosts := {}

var last_username: String

@export var send_timer: Timer

func _ready():
	ensure_connection()

func update_ghosts(dt):
	# updates players
	for id in players.keys():
		if players[id].is_client:
			get_tree().get_first_node_in_group("player").id = id
			continue
		
		if id not in ghosts.keys():
			ghosts[id] = Ghost.instantiate()
			#ghosts[id].id = id
			get_parent().get_parent().add_child(ghosts[id])
		ghosts[id].position.x = lerp(ghosts[id].position.x, players[id].x, 20 * dt)
		ghosts[id].position.y = lerp(ghosts[id].position.y, players[id].y, 20 * dt)
		ghosts[id].position.z = lerp(ghosts[id].position.z, players[id].z, 20 * dt)
		ghosts[id].rotation.y = lerp_angle(ghosts[id].rotation.y, players[id].rotation, 20 * dt)
		ghosts[id].animation.play(players[id].animation)
		ghosts[id].get_node("Character").scale = Vector3(players[id].scale_x, players[id].scale_y, players[id].scale_z)
		if players[id].has("username") && ghosts[id].name_label.text != players[id].username:
			ghosts[id].name_label.text = players[id].username
		#ghosts[id].update(dt, players[id])
	
	# disconnects players
	for id in ghosts.keys():
		if id not in players:
			#ghosts[id].disconnected()
			ghosts[id].queue_free()
			ghosts.erase(id)

func _process(dt):
	update_ghosts(dt)
	
	socket.poll()
	state = socket.get_ready_state()
	get_data()

func get_data():
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			var packet = socket.get_packet()
			if socket.was_string_packet():
				var packet_text = packet.get_string_from_utf8()
				players = JSON.parse_string(packet_text)
			else:
				print("< Got binary data from server: %d bytes" % packet.size())

func send_data():
	if state == WebSocketPeer.STATE_OPEN:
		var player: Player = get_tree().get_first_node_in_group("player")
		var data = {
			x = player.position.x,
			y = player.position.y,
			z = player.position.z,
			rotation = player.rotation.y,
			animation = player.animation.assigned_animation,
			scale_x = player.model.scale.x,
			scale_y = player.model.scale.y,
			scale_z = player.model.scale.z,
		}
		var username = get_tree().get_first_node_in_group("username")
		if username != null && last_username != username.text:
			data.username = username.text.substr(0, 10)
		socket.send_text(JSON.stringify(data))

func ensure_connection():
	if state == WebSocketPeer.STATE_CLOSED:
		var err = socket.connect_to_url(websocket_url)
		if err != OK:
			push_error("Unable to connect. Error code: %d" % err)
		
		remove_all_ghosts()
		players.clear()

func remove_all_ghosts():
	for ghost: Node2D in ghosts.values():
		ghost.disconnected()
	ghosts.clear()
