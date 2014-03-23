mongoose = require('mongoose')
util = require('util')
crypto = require('crypto')
LocalStrategy = require('passport-local').Strategy
BadRequestError = require('passport-local').BadRequestError

Account = new mongoose.Schema
  username: { type:String, maxLength: 100 }
  email : { type:String , format: "email" }
  passpord: String 
  salt :String

errorInfos = 
  incorrectPasswordError: 'Incorrect password'
  incorrectUsernameError: 'Incorrect username'
  missingUsernameError: 'Field %s is not set'
  missingPasswordError: 'Password argument not set!'
  userExistsError: 'User already exists with name %s'
  noSaltValueStoredError: 'Authentication not possible. No salt value stored in mongodb collection!'

strategyOptions = {}

options = 
  saltLen: 32
  iterations : 25000
  keyLen: 512
  encoding: "hex"

Account.pre 'save', (next) ->
  next()

Account.methods.setPassword = (password, cb) ->
    return cb(new BadRequestError(errorInfos.missingPasswordError)) if not password
        
    crypto.randomBytes options.saltLen, (err, buf) ->
      return cb( err ) if err 
      salt = buf.toString( options.encoding) 
      crypto.pbkdf2 password, salt, options.iterations, options.keyLen, (err, hashRaw) =>
        return cb(err) if err
        
        @set( "passpord", new Buffer(hashRaw, 'binary').toString(options.encoding))
        @set( "salt", salt)
        cb(null, @)

Account.methods.authenticate = (password, cb) ->
  
  return cb( null, false, message: errorInfos.noSaltValueStoredError ) if not @get("salt")

  crypto.pbkdf2 password, @get("salt"), options.iterations, options.keyLen, (err, hashRaw) =>
    return cb(err) if err
    
    hash = new Buffer( hashRaw, "binary").toString( options.encoding )
    return if hash == @get("passpord") then cb( null, @) else cb(null, false, { message: errorInfos.incorrectPasswordError })

Account.statics.authenticate = ->
  return (username, password, cb) ->
    @findByEmail email, (err,user ) ->
      return cb( err ) if err
      return if user
          user.authenticate( password ) 
        else 
          cb( null, false, { message: errorInfos.incorrectUsernameError } )

Account.statics.serializeUser = ->
  return (user, cb) ->
    cb(null, user.get("email"))

Account.statics.deserializeUser = ->
  return (username, cb) ->
    @findByEmail(username, cb)
    
Account.statics.register = (user, password, cb) ->
  if not user instanceof @
    user = new @(user)
  return cb( new BadRequestError( errorInfos.missingUsernameError )) if not user.get("email")

  @findByEmail user.get("email"), (err, existingUser) ->
    return cb(err) if err
    return cb( new BadRequestError( errorInfos.userExistsError )) if existingUser
      
    user.setPassword password, (err, user) ->
      return cb(err) if err
      user.save (err) ->
        return cb(err) if err
        cb( null, user)

Account.statics.findByEmail = (username, cb) ->
  queryParameters = {}
  queryParameters["email"] = username
  
  query = @findOne(queryParameters)
  query.select(options.selectFields) if options.selectFields
  query.populate(options.populateFields) if options.populateFields
  
  if cb 
    query.exec(cb)
  else
    return query

Account.statics.createStrategy = ->
  return new LocalStrategy(strategyOptions, @authenticate())

module.exports = mongoose.model('Account', Account)
