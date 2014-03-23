request = require("lib/request")

helloWorld = ->

	return "Hello world!"

describe "Hello world", ->
  it "says hello", (done)->
    expect(helloWorld()).to.equal "Hello world!"
  it "say good by", (done) ->
  	expect("time").to.not.equal "zhong"

	  request.get('http://127.0.0.1:3000/files/').then (data) ->
				console.log "tine",data
				done()

			.catch (err) ->
				console.log err 
				done()
				
			.done ->
				console.log "here" 
				done()
