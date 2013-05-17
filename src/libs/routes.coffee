express = require("express")

exports.config = (app, dirname) ->
    app.get "/", (req, res) ->
        res.sendfile dirname + "/public/client.html"

    app.get "/speaker", (req, res) ->
        res.sendfile dirname + "/public/speaker.html"

    app.use '/lib', express.static(dirname + '/public/lib')
    app.use '/js', express.static(dirname + '/public/js')
    app.use '/css', express.static(dirname + '/public/css')
    app.use '/image', express.static(dirname + '/public/image')
