process.env.NODE_ENV ?= 'dev'
debug = process.env.NODE_ENV isnt 'production'

util = require 'util'
express = require 'express'
fs = require 'fs'
browserify = require 'browserify'
jade = require 'jade'
stylus = require 'stylus'
require 'colors'

version = "unknown"
gitsha = require 'gitsha'
gitsha __dirname, (error, output) ->
	if error then return console.error output
	version = output
	util.log "[#{process.pid}] env: #{process.env.NODE_ENV.magenta}, version: #{output.magenta}"

bundle = browserify
	mount: "/app.js"
	watch: debug
	debug: debug
	filter: if debug then String else require 'uglify-js'

jadeRuntime = require('fs').readFileSync(__dirname+"/node_modules/jade/runtime.js", 'utf8')
bundle.prepend jadeRuntime
bundle.register '.jade', (body) ->
	templateFn = jade.compile body,
		"client": true
		"compileDebug": false
	template = "module.exports = " + templateFn.toString() + ";"
bundle.addEntry __dirname + "/client/index.coffee"

app = express.createServer()
io = require('socket.io').listen(app)

app.set 'views', __dirname + '/views'
app.set 'view options', layout: false

accessLogStream = fs.createWriteStream './access.log',
	flags: 'a'
	encoding: 'utf8'
	mode: 0o0644

app.use express.logger
	format: if debug then 'dev' else 'default'
	stream: accessLogStream

app.configure 'dev', ->
	io.set 'log level', 2

app.configure 'production', ->
	io.set 'log level', 1
	io.enable 'browser client minification'
	io.enable 'browser client etag'
	io.enable 'browser client gzip'
	app.use (req, res, next) ->
		if not res.getHeader 'Cache-Control'
			maxAge = 86400 # seconds in one day
			res.setHeader 'Cache-Control', 'public, max-age=' + maxAge
		next()

app.configure ->
	app.use express.responseTime()
	app.use bundle
	app.use stylus.middleware
		src: __dirname + '/views'
		dest: __dirname + '/public'
	app.use express.static __dirname + '/public'

app.get '/', (req, res) ->
	res.render 'index.jade',
		version: version
		devMode: debug

app.get '/api/test', (req, res) ->
	res.json {err: false, msg: "API speaks!"}

io.on 'connection', (socket) ->
	socket.on 'broadcastMessage', (message) ->
		console.log 'broadcastMessage:', message
		io.sockets.emit 'messageReceived', message

app.listen process.env.PORT or 0, ->
	addr = app.address().address
	port = app.address().port
	util.log "[#{process.pid}] http://#{addr}:#{port}/"

module.exports = app

