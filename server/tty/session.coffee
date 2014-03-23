_ = require "underscore"
pty = require 'pty.js'
utils = require '../commons/utils'


module.exports = class Session 
  
  @uid: 0
  
  constructor: (@server, @socket) ->
    @terms = {};
    @req = socket.handshake
    
    conf = @server.conf
    sessions = @server.sessions
    req = @socket.handshake

    @user = req.user
    @id = req.user or @uid()

    @log 'Session \x1b[1m%s\x1b[m created.', @id
  
  uid: -> 
    if @server.conf.syncSession
      req = @req
      return req.address.addres + '|' + req.address.port + '|' + req.headers['user-agent']
    @constructor.uid++ 
    return @constructor.uid + ''

  disconnect: ->
    try
      @socket._events = {}
      @socket.$emit = ->
      @socket.disconnect() 
    catch error
      "And the error is ... #{error}"
      
    @clearTimeout()
  
  log: (args...) ->
    return @_log 'log', args

  error: (args...) ->
    return @_log 'error', args

  warning: (args...) ->
    return @_log 'warning', args 
  
  _log: (level, args ) ->
    console.log level,args

  sync: =>
    terms = {}
    queue = []

    for key, term of @terms
      terms[key] = 
        id: term.pty
        pty: term.pty
        cols: term.cols
        rows: term.rows
        process: utils.sanitize(term.process)
        
    for key, term of @terms
      cols = term.cols
      rows = term.rows

      #A tricky way to get processes to redraw.
      #Some programs won't redraw unless the
      #terminal has actually been resized.
      term.resize cols + 1, rows + 1
      queue.push ->
        term.resize cols, rows 

      #Send SIGWINCH to our processes, and hopefully
      #they will redraw for our resumed session.
      #self.terms[key].kill('SIGWINCH');

    setTimeout ->
      for item in queue 
        item()
    , 30

    @socket.emit 'sync', terms
   
  handleCreate : (cols, rows, func) ->

    terms = @terms
    conf = @server.conf
    socket = @socket

    len = _.keys(terms).length

    if len >= conf.limitPerUser or pty.total >= conf.limitGlobal 
      @warning 'Terminal limit reached.' 
      return func { error: 'Terminal limit.' } 

    shell =  if _.isFunction(conf.shell ) then conf.shell(@) else conf.shell
    shellArgs = if _.isFunction( conf.shellArgs) then conf.shellArgs(@) else conf.shellArgs
    
    env = process.env
    env["TERM"] = "xterm-256color"
    env["COLORTERM"] = "butterfly"
    env["LC_ALL"] = "zh_CN.utf-8"
    
    #console.log env 
    term = pty.fork shell, shellArgs, 
      name: conf.termName
      cols: cols
      rows: rows 
      cwd: conf.cwd || process.env.HOME
      env: env 

    id = term.pty
    terms[id] = term

    term.on 'data', (data) =>
      @socket.emit 'data', id, data 
      
    term.on 'close', =>
      #Make sure it closes
      #on the clientside.
      @socket.emit 'kill', id 
      #Ensure removal.
      delete terms[id] if terms[id]
      @log 'Closed pty (%s): %d.', term.pty, term.fd

    @log 'Created pty (id: %s, master: %d, pid: %d).', id, term.fd, term.pid 

    return func null,
      id: id
      pty: term.pty
      process: utils.sanitize(conf.shell)
      
  handleData: (id, data) =>
    terms = @terms
    if not terms[id] 
      @warning '' + 'Client attempting to' + ' write to a non-existent terminal.' + ' (id: %s)', id
      return

    terms[id].write(data)
  
  handleKill: (id) =>
    terms = @terms
    return if not terms[id]
    
    terms[id].destroy()
    delete terms[id]

  handleResize: (id, cols, rows) =>
    terms = @terms
    return if not terms[id] 
    
    terms[id].resize cols, rows 
  
  handleProcess: (id, func) =>
    terms = @terms;
    return if not terms[id]
    
    name = terms[id].process
    return func null, utils.sanitize(name) 
     
  handleDisconnect: =>
    terms = @terms
    sessions = @server.sessions
    conf = @server.conf

    #XXX Possibly create a second/different
    #destroy function to accompany the one
    #above?
    
    destroy = -> 
      for key, term of terms
        delete terms[key]
        term.destroy()
      delete sessions[@id] if sessions[@id] 
      @log 'Killing all pty\'s.' 

    @log 'Client disconnected.' 

    return destroy() if conf.syncSession 

    if conf.sessionTimeout <= 0 or conf.sessionTimeout == Infinity 
      return @log('Preserving session forever.')

    #XXX This could be done differently.
    @setTimeout conf.sessionTimeout, destroy 
    this.log 'Preserving session for %d minutes.', conf.sessionTimeout / 1000 / 60 | 0 

  handlePaste: (func) =>
    execFile = require('child_process').execFile
    exec = (args...) =>
      file = args.shift()
      return execFile file, args, (err, stdout, stderr) =>
        return func(err) if err
        return func(new Error(stderr)) if stderr and not stdout
        return func(null, stdout) 

    #X11:
    return exec ['xsel', '-o', '-p'],(err, text) =>
      return func(null, text) if not err  
      return exec ['xclip', '-o', '-selection', 'primary'], (err, text) =>
        return func(null, text) if not err
        #Mac:
        return exec ['pbpaste'], (err, text) =>
          return func(null, text) if not err
          #Windows:
          #return exec(['sfk', 'fromclip'], function(err, text) {
          return func(new Error('Failed to get clipboard contents.')) 
      
      
  setTimeout: (time, func) ->
    @clearTimeout()
    @timeout = setTimeout func.bind(@), time
  
  clearTimeout: ->
    return if not @timeout 
    clearTimeout(@timeout)
    delete @timeout
    