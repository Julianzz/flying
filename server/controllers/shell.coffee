fs = require 'fs'

errors = require '../commons/errors'

module.exports.setup = (app) ->
  app.get '/shell', (req, res) ->
    res.render('shell')
    
    