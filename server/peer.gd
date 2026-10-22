extends Node

const Host := preload("./host.tscn")
const Client := preload("./client.tscn")

func _ready():
	var args := OS.get_cmdline_args()
	if "--host" in args:
		add_child(Host.instantiate())
	else: # elif "--client" in args:
		# assumes client
		add_child(Client.instantiate())
