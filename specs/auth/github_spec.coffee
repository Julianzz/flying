mm = require('mm')
passport = require('passport')
path = require('path')
github = require('../../server/auth/github')
Models = require('../../server/models')
app = require('../../server')
should = require('should')

request = require('supertest')(app)
assert = require("assert")

User = Models.User
config = require ('../../server/app')

describe 'controllers/github.js', ->
  
  beforeEach (done)->
    app.get '/auth/github/test_callback'
      ,(req, res, next) ->
        req.user = {id: 'notexists'}
        next()
      ,github.callback
    app.post '/auth/github/test_create', (req, res, next)->
      req.session.profile = 
        displayName: 'alsotang' + new Date()
        username: 'alsotang' + new Date()
        accessToken: 'a3l24j23lk5jtl35tkjglfdsf'
        emails: [{value: 'alsotang@gmail.com' + new Date()}]
        _json: {avatar_url: 'http://avatar_url.com/1.jpg'}
        id: 22
      next()
    , github.create
    done()
    
      
  afterEach ->
    mm.restore()

  it 'should 302 when get /auth/github', (done) ->
    _clientID = config.GITHUB_OAUTH.clientID
    config.GITHUB_OAUTH.clientID = 'aldskfjo2i34j2o3'
    
    request.get('/auth/github').expect 302, (err, res)->

      done(err) if err
      res.headers.should.have.property('location')
        .with.startWith('https://github.com/login/oauth/authorize?')
      config.GITHUB_OAUTH.clientID = _clientID
      done()
  

  it 'should redirect to /auth/github/new when the github id not in database',(done) ->
    request.get('/auth/github/test_callback?code=123456').expect 302, (err, res) ->
      return done(err) if err
      res.headers.should.have.property('location').with.endWith('/auth/github/new')
      done()
      
  it 'should redirect to / when the user is registed',(done) ->
    mm.data User, 'findOne',
      save: (callback) ->
        process.nextTick(callback)

    request.get('/auth/github/test_callback?code=123456')
      .expect 302,  (err, res) ->
        return done if err
        res.headers.should.have.property('location').with.endWith('/')
        done()

  it 'should 200', (done) ->
    request.get('/auth/github/new').expect 200, (err, res) ->
        return done(err) if err
        res.text.should.include('/auth/github/create')
        done()

  it 'should create a new user', (done)->
    userCount = null
    User.count  (err, count) ->
      userCount = count
      request.post('/auth/github/test_create').send({isnew: '1'}).expect 302,  (err, res) ->
        return done(err) if err
        
        res.headers.should.have.property('location').with.endWith('/')
        User.count (err, count) ->
          count.should.equal(userCount + 1)
          done()

  it 'should not create a new user when loginname or email conflict',(done) ->
    request.post('/auth/github/test_create')
      .send({isnew: '1'})
      .expect 500, (err, res) ->
        return done(err) if err
        res.text.should.match(/您 GitHub 账号的.*与之前在 CNodejs 注册的.*重复了/)
        done()


  it 'should link a old user', (done)->
    username = 'Alsotang'
    pass = 'hehe'
    mm User, 'findOne', (loginInfo, callback) ->
      loginInfo.loginname.should.equal(username.toLowerCase())
      callback null,
        save: ->
          done()
          
    request.post('/auth/github/test_create').send({name: username, pass: pass})
      .end()
      

