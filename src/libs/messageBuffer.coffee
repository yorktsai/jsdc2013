messages = []

exports.append = (data) ->
    messages.push(data)
    while messages.length > 10
    	messages.shift()

exports.getAll = (data) ->
	return messages