crypto = require 'crypto'


Models = require '../models'
utils = require '../commons/utils'
sign = require './sign'

User = Models.User

module.exports.callback = (req, res, next) ->
  profile = req.user
  
  User.findOne { githubId: profile.id }, (err, user) ->
    return next( err ) if (err)
    
    if user
      user.name = profile.username
      user.githubUsername = profile.username
      user.loginname = profile.username
      user.email = profile.emails?[0].value
      user.avatar = profile._json?.avatar_url
      user.save (err) ->
        return next(err) if (err) 
        sign.gen_session(user, res)
        return res.redirect('/')
    else
      req.session.profile = profile;
      return res.redirect('/auth/github/new')
      

module.exports.new =  (req, res, next)->
  res.render 'sign/new_oauth', 
    actionPath: '/auth/github/create'

module.exports.create = (req, res, next) ->
  profile = req.session.profile
  return res.redirect('/signup') if not profile
  
  delete req.session.profile
  
  #注册新账号
  if req.body.isnew 
    user = new User
      name: profile.username
      loginname: profile.username
      pass: profile.accessToken
      email: profile.emails[0].value
      avatar: profile._json.avatar_url
      githubId: profile.id
      githubUsername: profile.username
      
    user.save (err) ->
      if not err
        sign.gen_session(user, res)
        res.redirect('/')
      else
        if err.err.indexOf('duplicate key error') != -1
          if err.err.indexOf('users.$email') != -1
            res.status(500)
            return res.send('您 GitHub 账号的 Email 与之前在 CNodejs 注册的 Email 重复了，也可能是您的 GitHub 没有提供公开的 Email 导致注册失败。');
    
          if err.err.indexOf('users.$loginname') != -1
              res.status(500)
              return res.send('您 GitHub 账号的用户名与之前在 CNodejs 注册的用户名重复了')
        return next(err)

  else
    req.body.name = req.body.name.toLowerCase()
    User.findOne {loginname: req.body.name, pass: utils.md5(req.body.pass)}, (err,user) ->
      return next(err) if err
      return res.render('sign/signin', { error: '账号名或密码错误。' }) if not user
      
      user.githubId = profile.id
      user.save  (err) ->
        return next(err) if (err)
        
        sign.gen_session(user, res)
        res.redirect('/')
