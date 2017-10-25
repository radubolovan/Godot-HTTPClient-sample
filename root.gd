extends Control

func _ready():
	var headers=[
		"User-Agent: Pirulo/1.0 (Godot)",
		"Accept: */*"
	]

	get_node("http_loading").get_request("www.php.net", 80, headers, "/ChangeLog-5.php")
	pass
