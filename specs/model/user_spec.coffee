User = require('../../server/models').User
should = require('should')
support = require('../support/support')
mongoose = require "mongoose"

describe 'models/user', ->
  
  models = mongoose.connect('mongodb://localhost/local_mongoose_test')
  
  describe 'getUserByLoginName', ->
    it 'should ok',  (done) ->
      User.getUserByLoginName 'jacksontian', (err, user) ->
        should.not.exist(err)
        #TODO: check user
        done()

  describe 'getUserByMail',  ->
    it 'should ok', (done) ->
      User.getUserByMail 'shyvo1987@gmail.com', (err, user) ->
        should.not.exist(err)
        # TODO: check user
        done()

  describe 'getUsersByIds', ->
    user = null
    
    before (done) ->
      support.createUser (err, user1) ->
        should.not.exist(err)
        user = user1
        done()

    it 'should ok with empty list', (done) ->
      User.getUsersByIds [], (err, list) ->
        should.not.exist(err)
        list.should.have.length(0)
        done()

    it 'should ok', (done) ->
      User.getUsersByIds [user._id], (err, list) ->
        should.not.exist(err)
        list.should.have.length(1)
        user1 = list[0]
        user1.name.should.be.equal(user.name)
        done()

  describe 'getUserByQuery', ->
    user = null
    before (done) ->
      support.createUser (err, user1) ->
        should.not.exist(err)
        user = user1
        done()

    it 'should not exist', (done) ->
      User.getUserByQuery 'name', 'key', (err, user) ->
        should.not.exist(err)
        should.not.exist(user)
        done()

    it 'should exist', (done) ->
      User.getUserByQuery user.name, null, (err, user1) ->
        should.not.exist(err)
        should.exist(user1)
        user1.name.should.be.equal(user.name)
        done()
        
  describe "getUsersByQuery ", ->
    
    user = null
    
    before (done) ->
      User.newAndSave 'jackson', 'jackson', 'pass', 'jackson@domain.com', '', false,(err,user1) ->
        User.newAndSave 'tom', 'tom', 'pass', 'tom@domain.com','', false,( err, user2) ->
          done()

    it "should not exist ", (done) ->
      User.getUsersByQuery { '$or': [{'loginname': "lzz"}, {'email': "lzz@gmail.com"}]}, {}, (err, users) ->
        should.not.exist(err)
        users.should.be.instanceof(Array)
        users.should.empty
        done()
    
    it "name should exist ", (done) ->
      User.getUsersByQuery { '$or': [{'loginname': "tom"}, {'email': "lzz@gmail.com"}]}, {}, (err, users) ->
        should.not.exist(err)
        users.should.be.instanceof(Array)
        users.should.have.length(1)
        done()
        
    it "email should exist ", (done) ->
      User.getUsersByQuery { '$or': [{'loginname': "lzz"}, {'email': "jackson@domain.com"}]}, {}, (err, users) ->
        should.not.exist(err)
        users.should.be.instanceof(Array)
        users.should.have.length(1)
        done()
        
    it " should exist 2", (done) ->
      User.getUsersByQuery { '$or': [{'loginname': "tom"}, {'email': "jackson@domain.com"}]}, {}, (err, users) ->
        should.not.exist(err)
        users.should.be.instanceof(Array)
        users.should.have.length(2)
        done()
