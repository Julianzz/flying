helloWorld = ->
  return "Hello world!"

describe "Hello world", ->
  it "says hello", ->
    expect(helloWorld()).toEqual("Hello world!")