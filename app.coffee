process.env.NODE_ENV ?= 'dev'
debug = process.env.NODE_ENV isnt 'production'

util = require 'util'
express = require 'express'
browserify = require 'browserify-middleware'
stylus = require 'stylus'
require 'colors'
favicon = require 'serve-favicon'
morgan = require 'morgan'

version = "unknown"
gitsha = require 'gitsha'
gitsha __dirname, (error, output) ->
	if error then return console.error output
	version = output
	util.log "[#{process.pid}] env: #{process.env.NODE_ENV.magenta}, version: #{output.magenta}"

bundle = browserify './client/index.coffee',
	mode: if debug then 'development' else 'production'
	transform: 'coffeeify'

app = express()
app.use favicon __dirname + '/public/favicon.ico'
app.use morgan()
app.use '/app.js', bundle
app.use stylus.middleware
	src: __dirname + '/views'
	dest: __dirname + '/cache'
app.use express.static __dirname + '/cache'
app.use express.static __dirname + '/public'

app.get '/', (req, res) ->
	res.render 'index.jade',
		version: version
		devMode: debug

app.get '/api/test', (req, res) ->
	res.json {err: false, msg: "API speaks!"}

server = app.listen process.env.PORT or 0, ->
	serverInfo = server.address()
	util.log "[#{process.pid}] http://#{serverInfo.address}:#{serverInfo.port}/"

io = require('socket.io').listen(server)

io.on 'connection', (socket) ->
	socket.on 'broadcastMessage', (message) ->
		console.log 'broadcastMessage:', message
		io.sockets.emit 'messageReceived', message

if debug
	io.set 'log level', 2
else
	io.set 'log level', 1
	io.enable 'browser client minification'
	io.enable 'browser client etag'
	io.enable 'browser client gzip'

module.exports = app

