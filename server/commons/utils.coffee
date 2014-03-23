path = require "path"
fs = require "fs"
_  = require "underscore"

crypto = require "crypto"

tryRequire = (args...) ->
  try
    return require(path.resolve.apply(path, args))
  catch error

tryResolve = (args...) ->
  file = path.resolve.apply(path, args)
  return file if exists(file)
  
tryRead = (args...) ->
  try
    file = path.resolve.apply(path, args)
    return fs.readFileSync(file, 'utf8')
  catch error
    
exists = (file) ->
  try
    fs.statSync(file)
    return true
  catch error
    return false

merge = (i, o) ->
  for key,item of o
    i[key] = item
  return i

ensure = (i,o)->
  for key, item of o
    i[key] = o[key] if i[key]?
  return i

sanitize = (file) ->
  return '' if not file 
  file = file.split(' ')[0] ? ''
  return path.basename(file) ? ''


tryResolve = (args...) ->
  file = path.resolve.apply(path, args)
  return file if exists(file )
    
module.exports.sanitize = sanitize
module.exports.ensure = ensure
module.exports.merge = merge
module.exports.exists = exists
module.exports.tryResolve = tryResolve
module.exports.tryRead = tryRead
module.exports.tryRequire = tryRequire

exports.md5 = (str) ->
  md5sum = crypto.createHash('md5')
  md5sum.update(str)
  str = md5sum.digest('hex')
  return str
  
exports.encrypt = (str, secret) ->
  cipher = crypto.createCipher('aes192', secret)
  enc = cipher.update(str, 'utf8', 'hex')
  enc += cipher.final('hex')
  return enc

exports.decrypt = (str, secret) ->
  decipher = crypto.createDecipher('aes192', secret)
  dec = decipher.update(str, 'hex', 'utf8')
  dec += decipher.final('utf8')
  return dec

exports.randomString = (size) ->
  size = size or 6
  code_string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
  max_num = code_string.length + 1
  new_pass = ''
  while size > 0
    new_pass += code_string.charAt(Math.floor(Math.random() * max_num))
    size--
  return new_pass
