
View = require "../base/view"
File = require "../../models/file"

codinghub = require "../../core/codinghub"

module.exports = class FilesBaseView extends View
  defaults:
    'path': null
    'base': "/"
    'edition': true
    'notifications': true

  events: {}
  shortcuts: {}

  constructor: ->
  	super

  	@model =  new File({"codinghub": codinghub }) if not @model

  	@listenTo( @model , "refesh set" , @update )
    
  	@load( @options.path) if @options.path 

  getTemplateData: ->
    context = 
      'options': @options
      'file': @model
      'view': @

  render: ->
  	return if not @model.path()
  	super
  	return @

  finish: ->
    super 
   
  load: (path) ->
    @model.getByPath(path).then =>
      	@trigger("file:load")
    	, =>
        @trigger("file:error")