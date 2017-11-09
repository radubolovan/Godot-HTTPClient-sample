# Copyright Radu Bolovan, 2017, radubolovan {AT} gmail {DOT} com
# This file is part of a MIT software license
# Feel free to use this file in any possible way that you want
# Adding me in the loop of the Credits of your application it's going to be appreciated, but not a must

extends Control

const HTTP_STATE_FAILED = -1
const HTTP_STATUS_IDLE = 0
const HTTP_STATE_CONNECTING = 1
const HTTP_STATE_REQUESTING = 2

var m_http = null
var m_method = -1
var m_headers = ""
var m_url = ""
var m_status = HTTP_STATUS_IDLE
var m_rb = RawArray()

func _ready():
	m_http = HTTPClient.new()
	get_node(".").hide()

func get_request(address, port, headers, url):
	m_headers = headers
	m_url = url
	m_method = HTTPClient.METHOD_GET
	var err = m_http.connect(address, port, false)
	if(err == OK):
		m_status = HTTP_STATE_CONNECTING
		m_rb.resize(0)
		set_process(true)
		get_node(".").show()
	else:
		print("ERROR: Failed connecting!")
		m_status = HTTP_STATE_FAILED

func _process(delta):
	var http_status = m_http.get_status()
	if(m_status == HTTP_STATE_CONNECTING):
		update_connecting(http_status)
	elif(m_status == HTTP_STATE_REQUESTING):
		update_requesting(http_status)

func update_connecting(http_status):
	if(http_status == HTTPClient.STATUS_RESOLVING):
		m_http.poll()
		#OS.delay_msec(500)
		print("Resolving ...")
	elif(http_status == HTTPClient.STATUS_CONNECTING):
		m_http.poll()
		#OS.delay_msec(500)
		print("Connecting ...")
	elif(http_status == HTTPClient.STATUS_CONNECTED):
		print("Connected!")
		var err = m_http.request(m_method, m_url, m_headers)
		if(err != OK):
			print("ERROR: Failed requesting!")
			m_http.close()
			m_status = HTTP_STATE_FAILED
			get_node(".").hide()
	elif(http_status == HTTPClient.STATUS_REQUESTING):
		print("Requesting ...")
		m_http.poll()
		#OS.delay_msec(500)
		m_status = HTTP_STATE_REQUESTING

func update_requesting(http_status):
	if(http_status == HTTPClient.STATUS_REQUESTING):
		m_http.poll()
		#OS.delay_msec(500)
	elif(http_status == HTTPClient.STATUS_BODY):
		m_http.poll()
		if (m_http.has_response()):
			print("Has response!")
			var http_headers = m_http.get_response_headers_as_dictionary()
			# print("code: ", m_http.get_response_code())
			# print("**headers:\\n", http_headers)
			var chunk = m_http.read_response_body_chunk()
			if (chunk.size()==0):
				print("chunk is empty")
				OS.delay_usec(1000)
			else:
				# print(str(chunk.get_string_from_ascii())+"\n")
				m_rb = m_rb + chunk
		else:
			# print(str(m_rb.get_string_from_ascii())+"\n")
			print("Done!")
			m_status = HTTP_STATUS_IDLE
			m_http.close()
			set_process(false)
			get_node(".").hide()
	else:
		print(str(http_status))




