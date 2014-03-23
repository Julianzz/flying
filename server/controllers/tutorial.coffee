fs = require 'fs'

errors = require '../commons/errors'

module.exports.setup = (app) ->
  app.get '/tutorial', (req, res) ->
    res.render('tutorial')
    
    