mongoose = require('mongoose')

request = require('request')
Account = require "../../server/models/account"

mongoose.connect('mongodb://localhost/testdb')

describe "A suite", ->
  conn = null 
  
  beforeEach ->
    
  afterEach ->
    mongoose.connection.db.executeDbCommand ->
      dropDatabase: 1
    , (err, result) ->

  it "contains spec with an expectation", ->
    expect(true).toBe(true)

  it "expect create user", ->
    account  = new Account( { email: "lzz_1983@gmail.com"})
    Account.register account, "zhong", (err, user)->
      expect( user.email ).toBe("lzz_1983@gmail.com")
      Account.findByEmail "lzz_1983@gmail.com",(err, user) ->
        expect( not not err).toBe( false )
        expect( user.email).toBe("lzz_1983@gmail.com")
        user.authenticate "zhong", (err, user ) ->
          expect( not not err ).toBe( false)
          expect (user.email).toBe( "lzz_1983@gmail.com" )
          done()
          
  it "expect register duplicate user", ->
    account1  = new Account( { email: "lzz_1983@gmail.com"})
    Account.register account1, "zhong"
    account2  = new Account( { email: "lzz_1983@gmail.com"})
    Account.register account2, 
    
  
  
  it "should respond with hello world", (done) ->
    request "http://127.0.0.1:3000/hello", (error, response, body) ->
      #expect(not not error).toBe( true )
      expect( response.statusCode).toBe( 404 )
      done()
    