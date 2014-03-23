
module.exports.setup = (app) ->
  app.get '/', (req, res) ->
    res.redirect "/home"
    
  app.get '/home', (req, res) ->
    if not req.session.user
      res.redirect "/signin" 
    else 
      res.render('home')
    
    