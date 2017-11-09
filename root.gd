# Copyright Radu Bolovan, 2017, radubolovan {AT} gmail {DOT} com
# This file is part of a MIT software license
# Feel free to use this file in any possible way that you want
# Adding me in the loop of the Credits of your application it's going to be appreciated, but not a must

extends Control

func _ready():
	var headers=[
		"User-Agent: Pirulo/1.0 (Godot)",
		"Accept: */*"
	]

	get_node("http_loading").get_request("www.php.net", 80, headers, "/ChangeLog-5.php")
	pass
