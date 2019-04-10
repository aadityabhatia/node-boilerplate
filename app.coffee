process.env.NODE_ENV ?= 'dev'
debug = process.env.NODE_ENV isnt 'production'

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
	console.log "[#{process.pid}] env: #{process.env.NODE_ENV.magenta}, version: #{output.magenta}"

bundle = browserify './client/index.coffee',
	mode: if debug then 'development' else 'production'
	transform: 'coffeeify'

app = express()
app.use favicon __dirname + '/public/favicon.ico'
app.use morgan(if debug then 'dev' else 'tiny')
app.use '/app.js', bundle
app.use stylus.middleware
	src: __dirname + '/views'
	dest: __dirname + '/cache'
app.use express.static __dirname + '/cache'
app.use express.static __dirname + '/public'

if debug
	app.locals.pretty = true

app.get '/', (req, res) ->
	res.render 'index.pug',
		version: version
		devMode: debug

app.get '/api/test', (req, res) ->
	res.json {err: false, msg: "API speaks!"}

server = app.listen process.env.PORT or 0, ->
	serverInfo = server.address()
	if serverInfo.family is 'IPv6' then serverInfo.address = "[#{serverInfo.address}]"
	console.log "[#{process.pid}] http://#{serverInfo.address}:#{serverInfo.port}/"

io = require('socket.io')(server)

io.on 'connection', (socket) ->
	socket.on 'broadcastMessage', (message) ->
		console.log 'broadcastMessage:', message
		io.sockets.emit 'messageReceived', message

process.on 'SIGINT', (signal) ->
	console.log "[#{process.pid}] Caught signal: #{signal}; closing server connections."
	server.close process.exit
	io.close()

process.on 'SIGTERM', (signal) ->
	console.log "[#{process.pid}] Caught signal: #{signal}; closing server connections."
	server.close process.exit
	io.close()

module.exports = app
