
CodeEditor = require "views/editor/CodeEditorView"
ConsoleEditor = require "views/editor/ConsoleView"
DialogView = require "views/dialog-view"

Todos = require 'models/todos'
routes = require 'routes'

mediator = require 'mediator'

# The application object
module.exports = class Application extends Chaplin.Application
  # Set your application name here so the document title is set to
  # “Controller title – Site title” (see Layout#adjustTitle)
  title: 'Chaplin • TodoMVC'

  initialize: (args...)->
    super args...
    #editor = new CodeEditor()
    #mconsole = new ConsoleEditor()
    options = 
      message: "hello world"
      dialog: "alert"
      keyboard: true
      
    #dialog = new DialogView(options)
    #dialog.open()
    
  # Create additional mediator properties
  # -------------------------------------
  initMediator: ->
    # Add additional application-specific properties and methods
    mediator.todos = new Todos()
    # Seal the mediator
    super

  start: ->
    # If todos are fetched from server, we will need to wait for them.
    mediator.todos.fetch()
    super

window.application = Application