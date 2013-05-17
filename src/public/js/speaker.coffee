# status bar, TODO: use backbone
setStatus = (msg) ->
    $("#status").html "Connection Status : " + msg

class SlideModel extends Backbone.Model

class SlideView extends Backbone.View
    el: $('#slides-div')

    events: {}

    initialize: () ->
        # model
        @model.on 'change', @render
        @model.view = @

    render: () =>
        id = @model.get('id')

        $('#slides-div .slide:visible').hide()
        $('#slides-div .slide:eq(' + id + ')').show()


$(document).ready(() ->
    # views
    slideModel = new SlideModel()
    slideView = new SlideView({
        model: slideModel
    })

    slideModel.set({
        channel: 'slide'
        id: 0
    })

    # socket io
    socket = io.connect("http://" + config.serverHost + ":" + config.port)

    socket.on "connect", (data) ->
        setStatus "connected"
        socket.emit "subscribe",
            channel: "slide"

        socket.emit "subscribe",
            channel: "chat"

    socket.on "reconnecting", (data) ->
        setStatus "reconnecting"

    socket.on "slide", (data) ->
        numSlides = $('#slides-div .slide').length
        if data.id? and data.id < numSlides and data.id >= 0
            slideModel.set(data)

    # bind slide events
    $(document).keydown((event) ->
        diff = 0
        if event.which is 219
            diff = -1
        else if event.which is 221
            diff = 1

        if diff isnt 0
            numSlides = $('#slides-div .slide').length

            id = slideModel.get('id')
            id = id + diff
            if id < numSlides and id >= 0
                socket.emit 'slide'
                    channel: 'slide'
                    id: id
    )
)

