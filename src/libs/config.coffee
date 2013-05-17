((exports) ->
    exports.serverHost = 'localhost'
    exports.port = 3939
    exports.redis =
        host: 'localhost'
        port: '6379'
        channel: 'jsdc:jsdc'
        msgList: 'jsdc:msgs'
) (if typeof exports is "undefined" then this["config"] = {} else exports)
