Stream = require('stream').Stream

exports.jsonEncoder = (input, path)->
  output = new Stream()
  output.readable = true
  first = true
  
  input.on "data", (entry) ->
    if path
      #console.log path
      entry.href = path + entry.name
      mime = if entry.linkStat then entry.linkStat.mime else entry.mime
      if mime and mime.match(/(directory|folder)$/) 
        entry.href += "/"
        
    if first
      output.emit("data", "[\n " + JSON.stringify(entry))
      first = false
    else 
      output.emit("data", ",\n " + JSON.stringify(entry))

  input.on "end", ->
    if first 
      output.emit("data", "[]")
    else 
      output.emit("data", "\n]")
    output.emit("end")
    
  if input.pause
      output.pause = ->
        input.pause()

  if input.resume
    output.resume = ->
      input.resume()

  return output
