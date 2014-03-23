check = require('validator').check
sanitize = require('validator').sanitize

crypto = require('crypto')
config = require('../app')

User = require('../models').User
#Message = require('../proxy').Message
mail = require('../mail/mail')
utils = require( '../commons/utils')
sign = require( './sign' )

exports.signup = (req, res, next) ->
      
  name = sanitize(req.body.name).trim()
  name = sanitize(name).xss()
  loginname = name.toLowerCase()
  pass = sanitize(req.body.pass).trim()
  pass = sanitize(pass).xss()
  email = sanitize(req.body.email).trim()
  email = email.toLowerCase()
  email = sanitize(email).xss()
  re_pass = sanitize(req.body.re_pass).trim();
  re_pass = sanitize(re_pass).xss();

  try
    if name == '' or pass == '' or re_pass == '' or email == ''
      throw new Error( '信息不完整。')
    if name.length < 5 
      throw new Error( '用户名至少需要5个字符。' )
      
    check(name, '用户名只能使用0-9，a-z，A-Z。').isAlphanumeric()
    if not pass == re_pass 
      throw new Error( '两次密码输入不一致。' )
  
    check(email, '不正确的电子邮箱。').isEmail()
        
  catch error
    res.render 'sign/signup',
      error: error.message
      name: name
      email: email
    return


  User.getUsersByQuery { '$or': [{'loginname': loginname}, {'email': email}]}, {}, (err, users) ->
    return next(err) if err

    if users.length > 0 
      res.render('sign/signup', {error: '用户名或邮箱已被使用。', name: name, email: email});
      return

    #md5 the pass
    pass = utils.md5(pass)
    
    #create gavatar
    avatar_url = 'http://www.gravatar.com/avatar/' + utils.md5(email.toLowerCase()) + '?size=48'

    User.newAndSave name, loginname, pass, email, avatar_url, not config.need_email_active, (err,user) ->
      return next(err) if err
      
      #发送激活邮件
      if config.need_email_active
        mail.sendActiveMail email, utils.md5(email + config.session_secret), name
        res.render 'sign/signup',
          success: '欢迎加入 ' + config.name + '！我们已给您的注册邮箱发送了一封邮件，请点击里面的链接来激活您的帐号。'
      else
        res.redirect "signin" 

notJump = [
  '/active_account' #active page
  '/reset_pass'     #reset password page, avoid to reset twice
  '/signup'         #regist page
  '/search_pass'    #serch pass page
  #'/signin'
]

exports.login = (req, res, next) ->
  
  loginname = sanitize(req.body.name).trim().toLowerCase()
  pass = sanitize(req.body.pass).trim()

  if not loginname or not pass 
    return res.render 'sign/signin', { error: '信息不完整。' }

  User.getUserByLoginName loginname, (err, user) ->
    return next(err) if  err
    if not user 
      return res.render('sign/signin', { error: '这个用户不存在。' })
      
    pass = utils.md5(pass)
    if not pass == user.pass 
      return res.render('sign/signin', { error: '密码错误。' })
      
    if not user.active
      
      #从新发送激活邮件
      mail.sendActiveMail(user.email, utils.md5(user.email + config.session_secret), user.name);
      return res.render('sign/signin', { error: '此帐号还没有被激活，激活链接已发送到 ' + user.email + ' 邮箱，请查收。' })
      
    #store session cookie
    sign.gen_session(user, res)
    
    #check at some page just jump to home page
    refer = req.session._loginReferer or'home';
    for item in notJump
      if refer.indexOf(item) >= 0
        refer = 'home'
        break
    res.redirect(refer)

exports.active_account = (req, res, next) ->
  key = req.query.key
  name = req.query.name

  User.getUserByName name, (err, user) ->
    return next(err) if err
    
    if not user or utils.md5(user.email + config.session_secret) != key
      return res.render('notify/notify', {error: '信息有误，帐号无法被激活。'})
      
    if user.active
      return res.render('notify/notify', {error: '帐号已经是激活状态。'})
      
    user.active = true
    user.save  (err) ->
      return next(err) if err
      res.render('notify/notify', {success: '帐号已被激活，请登录'})
      
exports.showSearchPass = (req, res) ->
  res.render('sign/search_pass')
  
exports.updateSearchPass = (req, res, next) ->
  email = req.body.email.toLowerCase()

  try
    check(email, '不正确的电子邮箱。').isEmail()
  catch e
    res.render('sign/search_pass', {error: e.message, email: email})
    return

  #动态生成retrive_key和timestamp到users collection,之后重置密码进行验证
  retrieveKey = randomString(15)
  retrieveTime = new Date().getTime()
  User.getUserByMail email, (err, user) ->
    if not user 
      res.render('sign/search_pass', {error: '没有这个电子邮箱。', email: email})
      return
      
    user.retrieve_key = retrieveKey
    user.retrieve_time = retrieveTime
    user.save (err) ->
      return next(err) if err
      
      #发送重置密码邮件
      mail.sendResetPassMail(email, retrieveKey, user.name)
      res.render('notify/notify', { success: '我们已给您填写的电子邮箱发送了一封邮件，请在24小时内点击里面的链接来重置密码。'})

exports.reset_pass = (req, res, next) ->
  key = req.query.key
  name = req.query.name
  
  User.getUserByQuery name, key, (err, user) ->
    if not user 
      return res.render('notify/notify', {error: '信息有误，密码无法重置。'})
      
    now = new Date().getTime()
    oneDay = 1000 * 60 * 60 * 24
    if not user.retrieve_time or now - user.retrieve_time > oneDay 
      return res.render('notify/notify', {error : '该链接已过期，请重新申请。'})
      
    return res.render('sign/reset', {name : name, key : key})

exports.update_pass = (req, res, next) ->
  psw = req.body.psw or ''
  repsw = req.body.repsw or ''
  key = req.body.key or ''
  name = req.body.name or ''
  
  if not psw == repsw 
    return res.render('sign/reset', {name : name, key : key, error : '两次密码输入不一致。'}) 
    
  User.getUserByQuery name, key, (err, user) ->
    return next(err) if err
    if not user
      return res.render('notify/notify', {error : '错误的激活链接'})
      
    user.pass = utils.md5(psw)
    user.retrieve_key = null
    user.retrieve_time = null
    user.active = true;  #用户激活
    user.save  (err) ->
      return next(err) if err
      return res.render('notify/notify', {success: '你的密码已重置。'})

    