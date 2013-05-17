# requires
express = require("express")
app = express()
server = require("http").createServer(app)
io = require("socket.io").listen(server)
redis = require("redis")
config = require('./libs/config')

# routing
require('./libs/routes').config(app, __dirname)

# start web server
server.listen config.port

# message buffer
messageBuffer = require('./libs/messageBuffer')
generalBuffer = []

# init redis clients
# redis clients
redisClient = redis.createClient(config.redis.port, config.redis.host)
redisPublishClient = redis.createClient(config.redis.port, config.redis.host)

# socket.io
io.sockets.on "connection", (socket) ->
    #on connect send a welcome message
    console.log('welcome');

    #on subscription request joins specified room
    #later messages are broadcasted on the rooms
    socket.on "subscribe", (data) ->
        console.log('subscribe: ' + data.channel);
        socket.join data.channel

        # send buffered messages
        if data.channel is 'message'
            messages = messageBuffer.getAll()
            for message in messages
                socket.emit('message', message)
        else if generalBuffer[data.channel]?
            socket.emit('message', generalBuffer[data.channel])

    socket.on "message", (data) ->
        console.log('message: ' + data.channel);
        redisPublishClient.publish config.redis.channel, JSON.stringify(data)
        

# setup redis clients
redisClient.on "ready", ->
    redisClient.subscribe config.redis.channel

redisClient.on "message", (channel, message) ->
    # console.log(message);
    data = JSON.parse(message)
    io.sockets.in(data.channel).emit('message', data);

    if data.channel is 'message'
        messageBuffer.append(data)
    else
        generalBuffer[data.channel] = data

