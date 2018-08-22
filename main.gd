extends TextureRect

var m_host = ""
var m_port = ""
var m_get_request = "/ChangeLog-5.php"

func _ready():
	m_host = "http://www.php.net"
	m_port = 80

	$host_edt.set_text(m_host)
	$port_edt.set_text(str(m_port))
	$get_edt.set_text(m_get_request)

	$request_get_btn.connect("pressed", self, "on_get_request")

	$status_lbl.set_text("Status: idle")

	g_http.setup(m_host, m_port)
	g_http.connect("connection_finished", self, "on_request_finished")

	$loading/AnimationPlayer.play("idle")
	$loading.hide()

func on_get_request():
	$host_edt.set_editable(false)
	$port_edt.set_editable(false)
	$get_edt.set_editable(false)
	$request_get_btn.set_disabled(true)
	$status_lbl.set_text("Status: connecting")
	$loading.show()
	$response.clear()
	g_http.get_request(m_get_request)

func on_request_finished(response):
	$host_edt.set_editable(true)
	$port_edt.set_editable(true)
	$get_edt.set_editable(true)
	$request_get_btn.set_disabled(false)
	$loading.hide()
	if(null == response):
		$response.append_bbcode("NULL")
	else:
		$response.append_bbcode(response.get_string_from_utf8())

func _process(delta):
	var http_status = g_http.get_http_status()
	$status_lbl.set_text("Status: " + http_status)
