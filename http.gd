extends Control

signal connection_started
signal connection_finished

enum e_http_status {
	e_http_status_not_configured = -1,
	e_http_status_idle = 0,
	e_http_status_waiting,
	e_http_status_requesting
}

var m_http = null

var m_err = 0

var m_server_address = null
var m_port = 0
var m_url = ""

var m_status = e_http_status_idle

var m_response_headers = null
var m_response_code = ""
var m_response_length = 0
var m_response = null

func _exit_tree():
	close_connection()
	m_response = null
	m_http = null

func setup(server_address, port):
	m_http = HTTPClient.new()
	m_server_address = server_address
	m_port = port

	m_err = 0
	m_status = e_http_status_idle

	m_response_length = 0
	m_response = PoolByteArray()

func start_connection():
	# check the configuration
	if(m_status == e_http_status_not_configured):
		print("HTTP error: HTTP not configured. Call 'setup' function")
		return false

	# check the connection
	if(m_status == e_http_status_waiting):
		print("HTTP error: a connection to " + m_server_address + ":" + str(m_port) + "already started")
		return false

	# trying to connect
	m_err = m_http.connect_to_host(m_server_address, m_port)
	if(m_err != OK):
		print("HTTP error: Cannot connect to server: " + m_server_address + ":" + str(m_port))
		return false

	# Wait until resolved and connected
	var http_status = m_http.get_status()
	while(http_status == HTTPClient.STATUS_CONNECTING || http_status == HTTPClient.STATUS_RESOLVING):
		# print("connecting ...")
		m_http.poll()
		OS.delay_msec(500)
		http_status = m_http.get_status()

	# print("Succesfully connected to ['" + m_server_address + "', " + str(m_port) + "]")

	m_response_length = 0
	m_response.resize(0)
	m_status = e_http_status_waiting
	return true

func close_connection():
	if(m_status == e_http_status_not_configured):
		return

	if(m_status == e_http_status_idle):
		print("HTTP warning: cannot close connection to " + m_server_address + ":" + str(m_port) + ". Connection not atsrted.")
		if(null != m_http):
			m_http.close()
		return

	#print("Succesfully disconnected from ['" + m_server_address + "', " + str(m_port) + "]")
	m_status = e_http_status_idle
	m_http.close()

func get_request(url):
	if(!start_connection()):
		return

	m_url = url

	var headers = [
		"User-Agent: Pirulo/1.0 (Godot)",
		"Accept: */*"
	]

	m_err = m_http.request(HTTPClient.METHOD_GET, m_url, headers)
	if(m_err != OK):
		print("HTTP error: GET request failed for '" + m_url + "'")
		return

	m_status = e_http_status_requesting
	emit_signal("connection_started")

func post_request(url, params):
	if(!start_connection()):
		return

	m_url = url

	var request = m_http.query_string_from_dict(params)

	var headers = [
		"Content-Type: application/x-www-form-urlencoded",
		"Content-Length: " + str(request.length())
	]

	m_err = m_http.request(HTTPClient.METHOD_POST, m_url, headers, request)
	if(m_err != OK):
		print("HTTP error: POST request failed for '" + m_url + "'")
		return

	m_status = e_http_status_requesting
	emit_signal("connection_started")

func put_request(url, params):
	if(!start_connection()):
		return

	m_url = url

	var request = m_http.query_string_from_dict(params)

	var headers = [
		"Content-Type: application/x-www-form-urlencoded",
		"Content-Length: " + str(request.length())
	]

	m_err = m_http.request(HTTPClient.METHOD_PUT, m_url, headers, request)
	if(m_err != OK):
		print("HTTP error: POST request failed for '" + m_url + "'")
		return

	m_status = e_http_status_requesting
	emit_signal("connection_started")

func _process(delta):
	if((m_status == e_http_status_not_configured) || (m_status == e_http_status_idle) || (m_status == e_http_status_waiting)):
		return

	var http_status = m_http.get_status()

	var check_for_body = false

	# Disconnected from the server.
	if(http_status == HTTPClient.STATUS_DISCONNECTED):
		m_status = e_http_status_idle
		print("HTTP error: disconnected")
		emit_signal("connection_finished", null)

	# Currently resolving the hostname for the given URL into an IP.
	elif(http_status == HTTPClient.STATUS_RESOLVING):
		m_http.poll()

	# DNS failure: Can’t resolve the hostname for the given URL.
	elif(http_status == HTTPClient.STATUS_CANT_RESOLVE):
		print("HTTP error: can't resolve")
		m_status = e_http_status_idle
		emit_signal("connection_finished", null)

	# Currently connecting to server.
	elif(http_status == HTTPClient.STATUS_CONNECTING):
		m_http.poll()

	# Can’t connect to the server.
	elif(http_status == HTTPClient.STATUS_CANT_CONNECT):
		print("HTTP error: can't connect")
		m_status = e_http_status_idle
		emit_signal("connection_finished", null)

	# Connection established.
	elif(http_status == HTTPClient.STATUS_CONNECTED):
		check_for_body = true

	# Currently sending request.
	elif(http_status == HTTPClient.STATUS_REQUESTING):
		m_http.poll()

	# HTTP body received.
	elif(http_status == HTTPClient.STATUS_BODY):
		check_for_body = true

	# Error in HTTP connection.
	elif(http_status == HTTPClient.STATUS_CONNECTION_ERROR):
		print("HTTP error: connection error")
		m_status = e_http_status_idle
		emit_signal("connection_finished", null)

	# Error in SSL handshake.
	elif(http_status == HTTPClient.STATUS_SSL_HANDSHAKE_ERROR):
		print("HTTP error: ssl handshake error")
		emit_signal("connection_finished", null)

	if(check_for_body):
		if(m_http.has_response()):
			m_response_headers = m_http.get_response_headers_as_dictionary()
			m_response_code = m_http.get_response_code()

			#print("Response code: " + str(m_response_code))
			#print("Response headers: " + JSON.print(m_response_headers))

			if(m_http.is_response_chunked()):
				print("Response is chunked - handle this properly !!!")
			else:
				m_response_length = m_http.get_response_body_length()
				#print("Response length: " + str(m_response_length))

			while m_http.get_status() == HTTPClient.STATUS_BODY:
				# While there is body left to be read
				m_http.poll()
				var chunk = m_http.read_response_body_chunk() # Get a chunk
				if(chunk.size() == 0):
					# Got nothing, wait for buffers to fill a bit
					OS.delay_usec(1000)
				else:
					m_response.append_array(chunk) # Append to read buffer

			#print(m_response.get_string_from_utf8())
			#var dict = JSON.parse(m_response.get_string_from_utf8()).result
			#print(dict)

			close_connection()
			emit_signal("connection_finished", m_response)

func get_status():
	return m_status

func get_http_status():
	if(null == m_http):
		return "NOT CONFIGURED"

	var http_status = m_http.get_status()

	# Disconnected from the server.
	if(http_status == HTTPClient.STATUS_DISCONNECTED):
		return "disconnected"

	# Currently resolving the hostname for the given URL into an IP.
	elif(http_status == HTTPClient.STATUS_RESOLVING):
		return "resolving"

	# DNS failure: Can’t resolve the hostname for the given URL.
	elif(http_status == HTTPClient.STATUS_CANT_RESOLVE):
		return "can't resolve"

	# Currently connecting to server.
	elif(http_status == HTTPClient.STATUS_CONNECTING):
		return "connecting ..."

	# Can’t connect to the server.
	elif(http_status == HTTPClient.STATUS_CANT_CONNECT):
		return "can't connect"

	# Connection established.
	elif(http_status == HTTPClient.STATUS_CONNECTED):
		return "connected"

	# Currently sending request.
	elif(http_status == HTTPClient.STATUS_REQUESTING):
		return "requesting"

	# HTTP body received.
	elif(http_status == HTTPClient.STATUS_BODY):
		return "status body"

	# Error in HTTP connection.
	elif(http_status == HTTPClient.STATUS_CONNECTION_ERROR):
		return "connection error"

	# Error in SSL handshake.
	elif(http_status == HTTPClient.STATUS_SSL_HANDSHAKE_ERROR):
		return "ssl handshake error"
	