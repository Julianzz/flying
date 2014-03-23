View = require 'views/kinds/RootView'

module.exports = class CodeEditor extends View 
  #el : $("editor")
  scheme : "ace/theme/monokai"
  
  constructor: (options) -> 
    @editor =  ace.edit("editor")
    @scheme =  if options?.scheme? then options.scheme else "ace/theme/chrome"
    
    @editor.setTheme( @scheme )
    @editor.renderer.setShowPrintMargin(false)
    @running = false
    @lang = "c"
  
  runCode: =>
    return if @running
    running = true
    
    output = []
    params = 
      id: id
      code: @editor.getValue()
      language: @lang
          
  
  initEditor: ->
    @editor.commands.removeCommand 'gotoline'

    @editor.commands.addCommand
      name: 'runCode'
      bindKey: 
        win: 'Ctrl-Return'
        mac: 'Command-Return'
      exec: @runCode


    
    
  
  
  