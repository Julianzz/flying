Terminal = require "lib/term"
Request = require "lib/request"

File = require "models/file"


$ = document.querySelectorAll.bind(document)

module.exports = ->
  socket = io.connect()
  
  id = null

  #data = Request.get( "/files/").then (data) ->
  #  console.log data
  
  file  = new File()
  file.getByPath("/auth").then ->
    ###file.listdir().then (data) ->
        _.each data, (elm) ->
          console.log elm.get('name')
      , (err) ->
        console.log "error", err
    ###
    #file.createFile("zhong")
    file.mkdir('liu').then ->
        console.log "success build file "
      , (error) ->
        console.log "fail", error 

  send = (data) ->
    socket.emit "data",id, data
  
  ctl = (type, args...) ->
    params = args.join(',')
    if type == 'Resize'
      socket.emit "resize" , params
     
  ###term = new Terminal $('#wrapper')[0], send, ctl
    
  socket.emit "create", [term.cols, term.rows ], (err, data)->
    id = data["id"]
    socket.emit "data", id,"ls -l \n" 
  
    socket.on "data", (id, data)->
      #term.write data
      setTimeout ->
          term.write data
      , 1
  ###
  addEventListener 'beforeunload', ->
    if not quit
      'This will exit the terminal session'
  
  
  #addEventListener 'keydown', ->
  #  console.log "capture event "


