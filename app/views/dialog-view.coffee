View = require './base/view'
utils = require 'lib/utils'

module.exports = class DialogView extends View
  className: "component-dialog modal fade"
  events:
    "keydown": "keydown"
    "hidden.bs.modal": "hidden"
    "shown.bs.modal": "shown"
    "click .action-close": "close"
    "click .action-confirm": "actionConfirm"
    
  @current: null
  
  template: ->
    template = if @options.template? 
        require(@options.template) 
      else 
        require( "templates/dialog/"+ @options.dialog )
    return template( @options )
    
  constructor: (@options)->
    super @options
    @value = null
    @$el.addClass @options.className if @options?.className?
    $(document).bind("keydown", @keydownHandler) if @options.keyboard?
    return @
    
  open :->
    @constructor.current.close() if not @constructor.current == null
    @render()
    @$el.appendTo($("body"))
    @$el.modal('show')
    @constructor.current = @
    return @
  
  render: ->
    console.log "inside render "
    @$el.html(@template())
    return @
  
  close : (e)->
    e.preventDefault() if e?

    $(document).unbind("keydown", @keydownHandler)
    @$el.modal('hide');
    @constructor.current = null
    
  hidden: ->
    @trigger("close", @value)
    @$el.remove()
  
  shown: ->
    @$el.find("input").focus() if @options.autoFocus
  
  actionConfirm:(e)->
    e.preventDefault() if e
    @value = @_getValue()
    @close()
    
  _getValue: ->
    return @value
  
  keydown: (e) ->
    return if not @options.keyboard
    key = e.keyCode or e.which

    #Enter: valid
    if key == 13 and @options.keyboardEnter
      @actionConfirm(e)
    else if key == 27 
      @close(e)
    
    
  
    
    
    
    