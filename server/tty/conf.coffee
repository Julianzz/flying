_ = require "underscore"
path = require "path"
fs = require "fs"
utils = require "../commons/utils"


options = {}

configFile = (file) ->
  home = process.env.HOME

  filename = file ? file : options.config
  if filename?
    file = path.resolve process.cwd(),filename
    dir = path.dirname(file)
    json = file 
  else 
    dir = process.env.TTYJS_PATH || path.join(home, '.tty.js') 
    json = path.join(dir, 'config.json') 
  
  return [dir, json]

readConfig = (file) ->
  [ dir, json ] = configFile(file)
  conf = {}
  
  if fs.existsSync(dir) and fs.existsSync(json)
    conf = JSON.parse fs.readFileSync(json, 'utf8')
  
  if not utils.exists(dir) 
    fs.mkdirSync dir, 0o700
    fs.writeFileSync(json, JSON.stringify(conf, null, 2))
    fs.chmodSync(json, 0o600)

  conf.dir = dir
  conf.json = json
  conf.__read = true
  
  return loadConfig(conf)


loadConfig = (conf) ->
  
  return readConfig( conf ) if _.isString( conf )
  
  conf =  if conf? then _.clone(conf ) else {}

  if conf.config?
    file = conf.config
    delete conf.config
    _.extend conf, readConfig(file) 
    
  return conf if conf.__check? and conf.__check is on 
   
  conf.__check = true
  
  utils.merge(conf, options.conf);

  #directory and config file
  conf.dir = conf.dir or ''
  conf.json = conf.json or ''

  #users
  conf.users = conf.users or {}


  #shell, process name
  if conf.shell and not conf.shell.indexOf('/')
    conf.shell = path.resolve(conf.dir, conf.shell)
    conf.shell = conf.shell or process.env.SHELL or 'sh'

    #arguments to shell, if they exist
    conf.shellArgs = conf.shellArgs or []

  #limits
  conf.limitPerUser = conf.limitPerUser or Infinity
  conf.limitGlobal = conf.limitGlobal or Infinity

  #sync session
  conf.syncSession = false #

  #session timeout
  conf.sessionTimeout = 10 * 60 * 1000 if _.isNumber(conf.sessionTimeout) 
  
  #log
  conf.log #log

  #cwd
  if conf.cwd?
    conf.cwd = path.resolve(conf.dir, conf.cwd) 

  #socket.io
  conf.io #

  #term
  conf.term = conf.term or {}
  conf.termName = conf.termName or conf.term.termName or terminfo()
  conf.term.termName = conf.termName

  conf.term.termName    #'xterm'
  conf.term.geometry    #[80, 24]
  conf.term.visualBell  #false
  conf.term.popOnBell   #false
  conf.term.cursorBlink #true
  conf.term.scrollback  #1000
  conf.term.screenKeys  #false
  conf.term.colors      #[]
  conf.term.programFeatures #false

  return conf
    
module.exports.loadConfig = loadConfig
    
    