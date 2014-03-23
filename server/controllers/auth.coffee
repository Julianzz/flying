passport = require('passport')
LocalStrategy = require('passport-local').Strategy

module.exports.setup = (app) ->
  
  Account = require('../models/account');
  passport.use new LocalStrategy(Account.authenticate())
  passport.serializeUser(Account.serializeUser())
  passport.deserializeUser(Account.deserializeUser())
  
  ###
  passport.use new LocalStrategy(
    function(username, password, done) {
      User.findOne({ username: username }, function(err, user) {
        if (err) { return done(err); }
        if (!user) {
          return done(null, false, { message: 'Incorrect username.' });
        }
        if (!user.validPassword(password)) {
          return done(null, false, { message: 'Incorrect password.' });
        }
        return done(null, user);
      });
    }
  ));
  ###
  
  app.get '/', (req, res) ->
    res.render('index', { user : req.user })
  
  app.get '/signup', (req, res) ->
    res.render('signup', { })
  
  app.post '/signup', (req, res) ->
    Account.register new Account({ username : req.body.username }), req.body.password,(err, account) ->
      return res.render('signup', { account : account }) if err?
      console.log err, account 
      passport.authenticate('local') req, res, ->
        console.log "inside auth"
        res.redirect('/home')

  
  app.get '/login', (req, res) ->
    res.render('login', { user : req.user }) 
      
  app.post '/login', passport.authenticate('local'), (req, res) ->
    res.redirect('/')

  app.get '/logout', (req, res) -> 
    req.logout()
    res.redirect('/')

  app.get '/ping', (req, res) ->
    res.send("pong!", 200)
