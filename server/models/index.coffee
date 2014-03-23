require "./user"
mongoose = require 'mongoose'
module.exports.User = mongoose.model('User')
