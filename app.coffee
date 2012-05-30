process.env.NODE_ENV ?= 'dev'

util = require 'util'
express = require 'express'

app = express.createServer()
io = require('socket.io').listen(app)

app.set 'view options',
	layout: false

app.configure 'dev', ->
	app.use express.logger 'dev'
	io.set 'log level', 2

app.configure 'production', ->
	app.use express.logger()
	io.set 'log level', 1
	io.enable 'browser client minification'
	io.enable 'browser client etag'
	io.enable 'browser client gzip'

app.configure ->
	app.use express.responseTime()
	app.use require('connect-assets')()
	app.use express.static(__dirname + '/public')

app.get '/', (req, res) ->
	res.render("index.jade")

app.get '/api/test', (req, res) ->
	res.json {err: false, msg: "API speaks!"}

io.on 'connection', (socket) ->
	socket.on 'broadcastMessage', (message) ->
		console.log 'broadcastMessage:', message
		io.sockets.emit 'messageReceived', message

app.listen process.env.PORT || 1337, ->
	util.log util.format "[%s] http://%s:%d/", process.env.NODE_ENV, app.address().address, app.address().port
