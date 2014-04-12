Terminal = require "lib/term"

View = require 'views/base/view'
codinghub = require "core/codinghub"


module.exports = class ConsoleView extends View 

  constructor: ->
    super

    @codinghub = @options.codinghub or codinghub 

    #@main_area = $("<div>", {'class': ".wrapper"})
    @main_area = @container or $(".ch-console")
    
    #console = $(".ch-console")
    @id  = null 
  #send = (data) ->
  #  socket.emit "data",id, data

    send = (data) =>
      @codinghub.socket.emit "data", @id , data 
    end = (data) ->
      @codinghub.socket.emit "data",@id, data
    ctl = (type, args...) =>
      params = args.join(',')
      if type == 'Resize'
        @codinghub.socket.emit "resize" , params
     
    @term = new Terminal @main_area[0], send, ctl

    codinghub.socket.emit "create", [@term.cols, @term.rows ], (err, data) =>
      @id = data["id"]
      @codinghub.socket.emit "data", @id, "ls -l \n" 
      @codinghub.socket.on "data", (id, data) =>
        #term.write data
        setTimeout =>
          @term.write data
        , 1

    #@main_area.appendTo( @$el )
  refresh: ->
    super 
    @term.resize()
