passport = require('passport')
GitHubStrategy = require('passport-github').Strategy
github = require "./github"
local = require "./local"
sign = require "./sign"
conf = require "../app"

module.exports.setup = (app) ->
  #github oauth
  passport.serializeUser (user, done) ->
    done(null, user)
  passport.deserializeUser (user, done) ->
    done(null, user)
    
  passport.use new GitHubStrategy conf.GITHUB_OAUTH, (accessToken, refreshToken, profile, done) ->
    profile.accessToken = accessToken
    done(null, profile)
    
  #github oauth
  
  github_middle = (req, res, next) ->
    if conf.GITHUB_OAUTH.clientID == 'your GITHUB_CLIENT_ID'
      return res.send('call the admin to set github oauth.')
    next()
  
  #github
  app.get '/auth/github', github_middle , passport.authenticate('github')
  app.get '/auth/github/callback', passport.authenticate('github', { failureRedirect: '/signin' })
    ,github.callback
  app.get('/auth/github/new', github.new)
  app.post('/auth/github/create', github.create)
  
  #sign up, login, logout
  if conf.allow_sign_up 
    app.get('/signup', sign.showSignup)
    app.post('/signup', local.signup)
  else 
    app.get('/signup', github_middle, passport.authenticate('github'))
    
  app.get('/active_account', local.active_account)
  
  app.get('/signin', sign.showLogin)
  app.get('/signout', sign.signout)
  app.post('/signin', local.login)
