User = require('../../server/models').User

exports.createUser = (callback) ->
  key = new Date().getTime() + '_' + Math.random()
  User.newAndSave('jackson' + key, 'jackson' + key, 'pass', 'jackson' + key + '@domain.com', '', false, callback)
