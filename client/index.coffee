socket = io.connect '/'

$ ->
	req = $.get '/api/test', (data) ->
		if data.err
			console.error data.err
			$('#output').empty().append data.err
		$('#output').empty().append data.msg

	sendMessage = ->
		message = $('#txtMessage').val()
		$('#txtMessage').val ''
		socket.emit 'broadcastMessage', message

	$('#btnSend').click sendMessage

	$('#txtMessage').keydown (e) ->
		if e.which is 13 then sendMessage()

	socket.on 'messageReceived', (message) ->
		console.log 'messageReceived:', message
		time = new Date().toLocaleTimeString()
		$('#messages').append $('<div>').text "[#{time}] #{message}"

