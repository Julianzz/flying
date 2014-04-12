View = require "../base/view"

module.exports = class BasePanelView extends View
	defaults: 
    title: ""
  events: {}

	constructor: (options) ->
		super
		@panelId = @options.panel
		@manager = @parent

  open: ->
  	@manager.open( @panelId )

  close: ->
  	@manager.close(@panelId)

  isActive: ->
  	return @manager.isActive(@panelId)

  toggle: (cb) ->
  	cb = not @isActive() if not cb?
  	if not cb
  		@close()
  	else
  		@open()

  connectCommand: (command) ->
    command.set "action", ->
     	@toggle()
    @parent.panelsCommand.menu.add(command);

