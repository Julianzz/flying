mongoose = require('mongoose')

Schema = mongoose.Schema

config = require('../app').conf


UserSchema = new Schema
  name: { type: String ,index: true }
  loginname: { type: String ,unique: true }
  pass: { type: String }
  email: { type: String, unique: true }
  url: { type: String }
  profile_image_url: {type: String}
  location: { type: String }
  signature: { type: String }
  profile: { type: String }
  weibo: { type: String }
  avatar: { type: String }
  githubId: { type: String, index: true }
  githubUsername: {type: String}
  is_block: {type: Boolean, default: false}

  create_at: { type: Date ,default: Date.now }
  update_at: { type: Date ,default: Date.now }
  is_star: { type: Boolean }
  level: { type: String }
  active: { type: Boolean ,default: true }

  receive_reply_mail: {type: Boolean ,default: false }
  receive_at_mail: { type: Boolean ,default: false }
  from_wp: { type: Boolean }

  retrieve_time : {type: Number}
  retrieve_key : {type: String}

UserSchema.virtual('avatar_url').get ->
  url = this.profile_image_url or this.avatar or config.site_static_host + '/public/images/user_icon&48.png'
  return url.replace('http://www.gravatar.com/','http://cnodegravatar.u.qiniudn.com/')

UserSchema.statics.getUsersByNames = (names, callback) ->
  return callback( null, []) if names.length == 0
  @find({ name: { $in: names } }, callback)
  
UserSchema.statics.getUserByLoginName = (loginName, callback) ->
  @findOne({'loginname': loginName}, callback)

UserSchema.statics.getUserById = (id, callback) ->
  @findOne({_id: id}, callback)
  
UserSchema.statics.getUserByName = (name, callback) ->
  @findOne({name: name}, callback)
  
UserSchema.statics.getUserByMail =  (email, callback) ->
  @findOne({email: email}, callback)

UserSchema.statics.getUsersByIds = (ids, callback) ->
  @find({'_id': {'$in': ids}}, callback)

UserSchema.statics.getUsersByQuery = (query, opt, callback) ->
  @find(query, null, opt, callback)

UserSchema.statics.getUserByQuery = (name, key, callback) ->
  @findOne({name: name, retrieve_key: key}, callback)
  
UserSchema.statics.newAndSave = (name, loginname, pass, email, avatar_url, active, callback) ->
  User = mongoose.model("User")
  user = new User()
  user.name = name
  user.loginname = loginname
  user.pass = pass
  user.email = email
  user.avatar = avatar_url
  user.active = active
  user.save(callback)

mongoose.model('User', UserSchema)