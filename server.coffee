http = require 'http'
log = require 'winston'

express = require 'express.io'
serverSetup = require './server_setup'
conf = require './server_config'

startServer = (app)->
  #http.createServer(app).listen(app.get('port'))
  app.http().io()
  #log.info "app info ", app.io
  serverSetup.setupTerm app

  app.listen app.get('port'), ->
    console.log('Server listening on port 3000')
    #log.info("Express SSL server listening on port " + app.get('port'))
  return app
  
createAndConfigureApp = ->
  serverSetup.setupLogging()
  serverSetup.connectToDatabase()
  #serverSetup.setupMailchimp()

  app = express()
  
  app.configure 'development', ->
    edt = require('express-debug')(app, {})
  
  #app.conf = conf
  serverSetup.setExpressConfigurationOptions app
  serverSetup.setupMiddleware app
  serverSetup.setupRoutes app
  
  serverSetup.configErrorHandler app
  #log.info app.routes 
  app
  #app = startServer(app)

app = createAndConfigureApp()

module.exports = app
module.exports.startServer = startServer

