# status bar, TODO: use backbone
setStatus = (msg) ->
    $("#status").html "Connection Status : " + msg

$(document).ready(() ->
    # socket io
    socket = io.connect("http://" + config.serverHost + ":" + config.port)

    socket.on "connect", (data) ->
        setStatus "connected"
        socket.emit "subscribe",
            channel: "booking"

        socket.emit "subscribe",
            channel: "purchase"

        socket.emit "subscribe",
            channel: "message"

    socket.on "reconnecting", (data) ->
        setStatus "reconnecting"
)

