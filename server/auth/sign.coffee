
config = require "../app"
utils = require '../commons/utils'
models = require '../models'
User = models.User
#private
gen_session = (user, res) ->
  
  auth_token = utils.encrypt(user._id + '\t' + user.name + '\t' + user.pass + '\t' + user.email, config.session_secret)
  #cookie 有效期30天
  expire_time = config.expire or 1000 * 60 * 60 * 24 * 30
  res.cookie(config.auth_cookie_name, auth_token, {path: '/', maxAge: expire_time  })
  
exports.gen_session = gen_session

getAvatarURL = (user,site_host) ->
  return user.avatar_url if user.avatar_url
  
  avatar_url = user.profile_image_url or user.avatar
  if not avatar_url 
    avatar_url = site_host + '/public/images/user_icon&48.png'
    
  return avatar_url

#sign up
exports.showSignup = (req, res) ->
  res.render('sign/signup')
  
exports.showLogin = (req, res) ->
  req.session._loginReferer = req.headers.referer
  res.render('sign/signin')
  
#sign out
exports.signout = (req, res, next) ->
  req.session.destroy() if req.session.destroy
  req.session = null
  res.clearCookie(config.auth_cookie_name, { path: '/' })
  res.redirect(req.headers.referer or 'home') 
  
#auth_user middleware
exports.auth_user = (req, res, next) ->
  
  if not req.session.user 
    cookie = req.cookies[config.auth_cookie_name]
    return next() if not cookie

    auth_token = utils.decrypt(cookie, config.session_secret)
    auth = auth_token.split('\t')
    user_id = auth[0]
    
    User.getUserById user_id, (err, user) ->
      return next(err) if err or not user
      req.session.user = user
      res.locals.current_user = req.session.user
      return next()
  else
    if not req.session.user.avatar_url 
      req.session.user.avatar_url = getAvatarURL(req.session.user, config.site_static_host)
    res.locals.current_user = req.session.user
    return next()