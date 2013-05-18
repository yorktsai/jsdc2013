# requires
express = require("express")
app = express()
server = require("http").createServer(app)
io = require("socket.io").listen(server)
redis = require("redis")
config = require('./libs/config')
moment = require('moment');

# routing
require('./libs/routes').config(app, __dirname)

# start web server
server.listen config.port

# message buffer
slideBuffer = undefined
isPrizeWon = false

# redis clients
redisClient = redis.createClient(config.redis.port, config.redis.host)
redisPublishClient = redis.createClient(config.redis.port, config.redis.host)

# socket.io
connectCounter = 0
io.sockets.on "connection", (socket) ->
    #on connect send a welcome message
    console.log('welcome');

    socket.on 'connect', () ->
        connectCounter++
        # TODO: put connect counter in REDIS

    socket.on 'disconnect', () ->
        connectCounter--
        # TODO: put connect counter in REDIS

    #on subscription request joins specified room
    #later messages are broadcasted on the rooms
    socket.on "subscribe", (data) ->
        try
            console.log('[subscribe] ' + data.channel);

            # send buffered messages
            if data.channel is 'chat'
                # get recent x messages and send to client
                n = 5
                redisPublishClient.llen config.redis.msgList, (err, res) ->
                    endIndex = res
                    startIndex = Math.max(endIndex - n, 0)

                    redisPublishClient.lrange config.redis.msgList, startIndex, endIndex, (err, res) ->
                        counter = 0
                        dataToPub = []
                        for json in res
                            data = JSON.parse(json)
                            data.id = startIndex + counter

                            if data.ts?
                                data.ts = moment.unix(data.ts).format('HH:mm:ss YYYY-MM-DD')

                            counter++

                            dataToPub.unshift(data)

                        socket.emit "chat", dataToPub

            else if data.channel is 'slide'
                # send recent slide to client
                if slideBuffer?
                    socket.emit data.channel, slideBuffer

            # join the room
            socket.join data.channel
        catch err
            console.trace()

    socket.on "admin-slide", (data) ->
        try
            if not data.id?
                return

            console.log('[slide] ' + data);

            redisPublishClient.publish config.redis.channel, JSON.stringify({
                channel: 'slide'
                data: data
            })
        catch err
            console.trace()

    socket.on "chat", (data) ->
        try
            if not data.msg?
                return

            data.ts = moment().unix()

            console.log('[chat] ' + JSON.stringify(data));

            # add to list
            redisPublishClient.rpush config.redis.msgList, JSON.stringify(data), (err, res) ->
                # pub
                data.id = res
                data.ts = moment.unix(data.ts).format('HH:mm:ss YYYY-MM-DD')
                redisPublishClient.publish config.redis.channel, JSON.stringify({
                    channel: 'chat'
                    data: data
                })
        catch err
            console.trace()

    socket.on "chat-append", (data) ->
        try
            if not data.id?
                return
            
            n = 10
            endIndex = data.id
            startIndex = Math.max(endIndex - n, 0)

            redisPublishClient.lrange config.redis.msgList, startIndex, endIndex, (err, res) ->
                counter = 0
                dataToPub = []
                for json in res
                    data = JSON.parse(json)
                    data.id = startIndex + counter

                    if data.ts?
                        data.ts = moment.unix(data.ts).format('HH:mm:ss YYYY-MM-DD')

                    counter++
                    dataToPub.unshift(data)

                socket.emit "chat-append", dataToPub
        catch err
            console.trace()

    socket.on "prize", (data) ->
        try
            if not isPrizeWon
                isPrizeWon = true
                socket.broadcast.emit "prize", data
        catch err
            console.trace()

# setup redis clients
redisClient.on "ready", ->
    redisClient.subscribe config.redis.channel

redisClient.on "message", (channel, message) ->
    try
        # console.log(message);
        data = JSON.parse(message)
        if not data.channel?
            # invalid message
            return

        dataToPub = undefined

        # cache message
        if data.channel is 'chat'
            # check format
            if not data.data.msg?
                return

            dataToPub = [data.data]
        else if data.channel is 'slide'
            # check format
            if not data.data.id?
                return

            slideBuffer = data.data
            dataToPub = data.data

        # broadcast message
        if dataToPub?
            io.sockets.in(data.channel).emit(data.channel, dataToPub)
    catch err
        console.trace()

