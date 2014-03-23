Session = require './session'


module.exports = class TermServer
  
  constructor: (@conf, @io) ->
    
    @sessions = {}
    #console.log @conf
    
    @io.route "create", (req) =>
      [cols, rows] = req.data
      
      if @conf.syncSession and req.user
        id = req.user
        session = @sessions[id]
        if session?
          #Possibly do something like this instead:
          #if (!stale.socket.disconnected)
          #  return this.id += '~', sessions[this.id] = this;
          session.disconnect()
          session.socket = socket 
          session.sync()
          session.log 'Session \x1b[1m%s\x1b[m resumed.', session.id 
      else
        session = new Session(@, req.socket) if not @session? 
        session.handleCreate cols, rows, req.io.respond
        @sessions[ session.id] = session
      
      req.socket.on 'data', (id, data) =>
        return session.handleData id, data 
    
      req.socket.on 'kill', (id) =>
        console.log "kill", id
        return session.handleKill id
    
      req.socket.on 'resize', (id, cols, rows ) =>
        return session.handleResize id, cols, rows
    
      req.socket.on 'process', (id, func) =>
        return session.handleProcess id, func
    
      req.socket.on 'disconnect', =>
        console.log "discon"
        return session.handleDisconnect()
    
      req.socket.on 'request paste',(func) =>
        return session.handlePaste func
      