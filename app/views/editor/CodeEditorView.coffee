FileBaseView = require './FileBaseView'
editorSettions = require "../settings/base"
FileSync =  require "core/filesync"
keyboard = require "lib/keyboard"

module.exports = class CodeEditor extends FileBaseView 

  scheme : "ace/theme/monokai"
  className: "common_editor"

  shortcuts:
    "ctrl+s": "saveFile"
    #"mod+r": "runFile"
    #"mod+f": "searchInfile"
    "ctrl+r" : "saveFile"

  constructor: ->

    super 

    @scheme =  if @options?.scheme? then @options.scheme else "ace/theme/chrome"
    
    #Create base ace editor instance and configure it
    #@ace_editor = $("<div>", {'class': "common_editor"})
    #this.editor = ace.edit(this.$editor.get(0));
    #var $doc = this.editor.session.doc;
    #@ace_editor = $("#editor")
    @ace_editor = @$el 

    @editor = ace.edit( @ace_editor.get(0))
    $doc = @editor.session.doc
    $doc.on 'change', (d) =>
      return if @_op_set
      @sync.updateContent(@editor.session.getValue())

    #@editor.setTheme( @scheme )
    @setEditor()
    @initEditor()
    @editor.renderer.setShowPrintMargin(false)
    @running = false


    @sync = new FileSync()

    @sync.on "update:env", (options) =>
      if options.reset
        @_op_set = true 
        @editor.setValue("")
        @_op_set = false 


    @sync.on "mode" , ->
    @sync.on "close", ->
    @sync.on "error", ->
    @sync.on "sync:modified", ->
    @sync.on "sync:loading", ->

    @sync.on "file:mode", (mode) =>
      @setMode(mode)

    @sync.on "content", (content, oldconent) =>
      $doc.setValue( content )

    @on "file:load", =>
      @sync.setFile @model, {} 

    @focus()

    $input = this.editor.textInput.getElement()

    handleKeyEvent = (e) ->
      return if not e.altKey and not e.ctrlKey and e.metaKey
      console.log "inside editor handle event ", e
      keyboard.handleKeyEvent(e)

    $input.addEventListener('keypress', handleKeyEvent, false);
    $input.addEventListener('keydown', handleKeyEvent, false);
    $input.addEventListener('keyup', handleKeyEvent, false);

  dispose: ->
    super 
    

  initEditor: ->
    @editor.commands.removeCommand 'gotoline'

    @editor.commands.addCommand
      name: 'runCode'
      bindKey: 
        win: 'Ctrl-Return'
        mac: 'Command-Return'
      exec: @runCode

  finish : ->
    #@$editor.appendTo( @$(".editor-inner"))
    @editor.resize()
    @editor.renderer.updateFull()

  focus : ->
    @editor.resize()
    @editor.renderer.updateFull()
    @editor.focus()

  setEditor:->

    @editor.session.setUseWorker(true)
    @editor.setOptions
      enableBasicAutocompletion: true
      enableSnippets: true

    #Force unix newline mode (for cursor position calcul)
    $doc = @editor.session.doc
    $doc.setNewLineMode("unix")
    @setOptions()

  setOptions: (opts)->

    @options = _.defaults opts or {} , 
      mode: "text"
      fontsize: "12"
      printmargincolumn: 80
      showprintmargin: false
      showinvisibles: false
      highlightactiveline: false
      wraplimitrange: 80
      enablesoftwrap: false
      keyboard: "textinput"
      enablesofttabs: true
      tabsize: 4

    @setMode(@options.mode)

    ace.config.loadModule ["keybinding", "ace/keyboard/"+@options.keyboard],(binding) =>
      @editor.setKeyboardHandler(binding.handler) if binding?.handler?


    #@editor.setTheme(themes.current().editor.theme or aceDefaultTheme)
    #@$editor.css("font-size", @options.fontsize+"px")
    @editor.setPrintMarginColumn(@options.printmargincolumn)
    @editor.setShowPrintMargin(@options.showprintmargin)
    @editor.setShowInvisibles(@options.showinvisibles)
    @editor.setHighlightActiveLine(@options.highlightactiveline)
    @editor.getSession().setUseWrapMode(@options.enablesoftwrap)
    @editor.getSession().setWrapLimitRange(@options.wraplimitrange, @options.wraplimitrange)
    @editor.getSession().setUseSoftTabs(@options.enablesofttabs)
    @editor.getSession().setTabSize(@options.tabsize)
    return @

  #Define mdoe option
  setMode: (lang) ->
    @options.mode = lang
    @editor.getSession().setMode("ace/mode/"+lang)

  #Get position (row, column) from index in file
  posFromIndex: (index) ->
    row = null
    lines = @editor.session.doc.getAllLines()
    for row in [0...lines.length]
      line = lines[row]
      break if index <= line.length
      index = index - (line.length + 1)
    
    results =  
      'row': row
      'column': index
    return results

  runCode: ->
    return if @running
    running = true
    
    output = []
    params = 
      id: id
      code: @editor.getValue()
      language: @lang

  saveFile: (e) ->
    console.log "inside save "
    e.preventDefault() if e 
    @sync.save()

  searchInfile: (e) ->
    e.preventDefault() if e 
    @editor.execCommand("find")



    
    
  
  
  