express = require 'express.io'
path = require 'path'
authentication = require 'passport'
useragent = require 'express-useragent'
fs = require 'graceful-fs'
mongoose = require('mongoose')

#database = require './server/commons/database'
baseRoute = require './server/routes'
#user = require './server/users/user_handler'
logging = require './server/commons/logging'

config = require './server_config'

Term = require './server/tty/term'
termConfig = require './server/tty/conf'

module.exports.setupTerm = (app) ->
  filename = "term.json"
  conf = termConfig.loadConfig filename
  term = new Term( conf, app.io )  

###Middleware setup functions implementation###
setupRequestTimeoutMiddleware = (app) ->
  app.use (req, res, next) ->
    req.setTimeout 15000, ->
      console.log 'timed out!'
      req.abort()
      self.emit('pass',message)
    next()

setupExpressMiddleware = (app) ->
  setupRequestTimeoutMiddleware app
  app.use(express.logger('dev'))
  app.use(express.static(path.join(__dirname, 'public')))
  app.use(useragent.express())

  app.use(express.favicon())
  app.use(express.cookieParser(config.cookie_secret))
  app.use(express.session( { secret: config.session_secret }))
  
  # file access module should not use  body parser
  app.use (req, rep, next ) ->
    bodyParser = express.bodyParser()
    #console.log req.path 
    return next() if /^(\/files)(\/.*)$/.test( req.path )
    return bodyParser(req, rep, next )

  app.use(express.methodOverride())

  #app.use(express.cookieSession({secret:'defenestrate'}))

  app.use(require('./server/auth/sign').auth_user)
  ###app.use (req, res, next) ->
    csrf = express.csrf()
    #ignore upload image
    return next() if req.body? and req.body.user_action == 'upload_image'
    csrf(req, res, next)
  
  app.use (req, res, next) ->
    res.locals.csrf = req.csrfToken()
    next()
  ###
  #app.set('view cache', true)

setupPassportMiddleware = (app) ->
  app.use(authentication.initialize())
  app.use(authentication.session())

setupOneSecondDelayMiddlware = (app) ->
  if config.slow_down 
    app.use (req, res, next) -> 
      setTimeout((-> next()), 1000)

exports.setupMiddleware = (app) ->
  setupExpressMiddleware app
  setupPassportMiddleware app
  setupOneSecondDelayMiddlware app

###Routing function implementations###

setupFallbackRouteToIndex = (app) ->
  app.get '*', (req, res) ->
    res.sendfile path.join(__dirname, 'public', 'index.html')

exports.setupRoutes = (app) ->
  app.use app.router
  baseRoute.setup app
  #setupFallbackRouteToIndex app

###Miscellaneous configuration functions###

exports.setupLogging = ->
  logging.setup()

exports.connectToDatabase = ->
  mongoose.connect('mongodb://localhost/passport_local_mongoose');
  #database.connect()

exports.setupMailchimp = ->
  #mcapi = require 'mailchimp-api'
  #mc = new mcapi.Mailchimp(config.mail.mailchimpAPIKey)
  #GLOBAL.mc = mc

exports.setExpressConfigurationOptions = (app) ->
  app.set('port', config.port)
  app.set('views', __dirname + '/views')
  app.set('view engine', 'jade')
  app.set('view options', { layout: false })

exports.configErrorHandler = (app)=>
  app.configure 'development',->
    app.use express.errorHandler 
      dumpExceptions: true
      showStack: true
        
  app.configure 'production', ->
    app.use express.errorHandler()


