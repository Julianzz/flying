log = require 'winston'

controllers = [
      './auth/setup'
      './vfs/file',
      './controllers/shell',
      './controllers/todos',
      './controllers/tutorial',
      './controllers/home'
]

module.exports.setup = (app) ->
  for route in controllers
    do (route) ->
      module = require(route)
      module.setup app
      log.debug "route module #{route} setup"