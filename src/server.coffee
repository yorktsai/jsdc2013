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
slideBuffer = undefined

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
        console.log('[subscribe] ' + data.channel);

        # send buffered messages
        if data.channel is 'chat'
            # TODO: get recent x messages and send to client
        else if data.channel is 'slide'
            # send recent slide to client
            if slideBuffer?
                socket.emit data.channel, slideBuffer
        else
            # invalid channel
            return

        # join the room
        socket.join data.channel

    socket.on "slide", (data) ->
        redisPublishClient.publish config.redis.channel, JSON.stringify({
            channel: 'slide'
            data: data
        })

    socket.on "chat", (data) ->
        console.log('[chat] ' + data.msg);
        redisPublishClient.publish config.redis.channel, JSON.stringify({
            channel: 'chat'
            data: data
        })
        
# setup redis clients
redisClient.on "ready", ->
    redisClient.subscribe config.redis.channel

redisClient.on "message", (channel, message) ->
    # console.log(message);
    data = JSON.parse(message)
    if not data.channel?
        # invalid message
        return

    # cache message
    if data.channel is 'chat'
        # check format
        if not data.data.msg?
            return

        # TODO: buffer
    else if data.channel is 'slide'
        # check format
        if not data.data.id?
            return

        slideBuffer = data.data

    # broadcast message
    io.sockets.in(data.channel).emit(data.channel, data.data);

