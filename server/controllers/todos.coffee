fs = require 'fs'
request = require 'request'

errors = require '../commons/errors'


module.exports.setup = (app) ->
  app.all '/todos', (req, res) ->
    results = {}
    res.json(results)