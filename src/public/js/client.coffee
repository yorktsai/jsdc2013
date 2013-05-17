# status bar, TODO: use backbone
setStatus = (msg) ->
    $("#status").html msg

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

class ChatModel extends Backbone.Model

class ChatView extends Backbone.View
    el: $('#chat-div')

    events: {
        'submit form': 'onFormSubmit'
    }

    initialize: () ->
        # model
        @model.on 'change', @render
        @model.view = @

    render: () =>
        msgsDiv = @$el.find(".msgs")
        msgs = @model.get("msgs")

        template = $('#template-msg').html()

        if not @model.get('append')
            msgs.reverse()
            $.each(msgs, (idx, msg) ->
                if msgsDiv.find('.msg[data-id="' + msg.id+ '"]').length <= 0
                    html = Mustache.render(template, msg)
                    msgsDiv.prepend(html)
            )
        else
            $.each(msgs, (idx, msg) ->
                if msgsDiv.find('.msg[data-id="' + msg.id+ '"]').length <= 0
                    html = Mustache.render(template, msg)
                    msgsDiv.append(html)
            )

    onFormSubmit: () ->
        form = @$el.find('form')
        msg = form.find('input[name="msg"]').val()
        form.find('input[name="msg"]').val('')
        if msg.length <= 0
            return false

        @socket.emit "chat",
            msg: msg

        return false

scrollLock = false
$(document).ready(() ->
    # hljs
    hljs.initHighlightingOnLoad()
    $('pre code').each((i, e) ->
        hljs.highlightBlock(e)
    )

    # views
    slideModel = new SlideModel()
    slideView = new SlideView({
        model: slideModel
    })

    slideModel.set({
        channel: 'slide'
        id: 0
    })

    chatModel = new ChatModel()
    chatView = new ChatView({
        model: chatModel
    })

    # socket io
    socket = io.connect("http://" + location.hostname + ":" + config.port)
    chatView.socket = socket

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

    socket.on "chat", (data) ->
        chatModel.set({
            msgs: data
            random: Math.random()
            append: false
        })

    socket.on "chat-append", (data) ->
        chatModel.set({
            msgs: data
            random: Math.random()
            append: true
        })
        scrollLock = false

    socket.on "prize", (data) ->
        $('#prize-div').text(data)

    # scroll
    $(document).bind "scroll", ->
        if not scrollLock and $(document).height() - $(window).scrollTop() - $(window).height() < 300
            lastMsg = $('#chat-div .msg:last')
            if lastMsg.length > 0
                scrollLock = true
                id = lastMsg.data("id") - 1

                if id > 0
                    socket.emit "chat-append",
                        id: lastMsg.data("id")
)

