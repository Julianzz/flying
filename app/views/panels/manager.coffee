View = require "../base/view"
PanelBaseView = require './base'
TabsManager = require '../tabs/manager'

module.exports = class PanelsView extends View

	className: "ch-panels"
	defaults: {}
	events: {}

	constructor: (options)->
		super
		@tabs = new TabsManager
	    lsayout: 1
	    layouts:
	       "Columns: 1": 1
	    tabMenu: false
	    newTab: false
	    draggable: false
	    keyboardShortcuts: false
	    maxTabsPerSection: 1

	  @tabs.$el.appendTo( @tabs.$el )

	  @activePanel = null
	  @previousPanel = null
	  @panelsCommand = new Command {}, { 'type':'menu', 'title': 'panels' }
	  @panels = {}

	  return @

	register: (panelId, PanelView, options) ->
		options = options or {}
		options = _.defaults options, 
			'title': panelId
		options = _.extend options, 
			'panel': panelId

		view = new PanelView( options, @ )
		@panels[panelId] = view 
		view.update()
		return view	

	open : (panelId) ->
		opened = false
		if panelId? and @panels[panelId]?
			opened = true
			tab = @tabs.add TabsManager.Panel, {},
        'title': @panels[panelId].options.title,
        'uniqueId': panelId
      if tab.$el.is(':empty')
      	tab.once "tab:close", =>
      		@panels[panelId].trigger("tab:close")
      		@panels[panelId].$el.detach()
      	@panels[panelId].$el.appendTo(tab.$el)
      	@panels[panelId].$el.update()

    @previousPanel = @activePanel or @previousPanel
    @activePanel = panelId

    if opened 
    	@trigger( "open", panelId)
    else
    	@trigger("close")

    return @

   isActive: (panelId) ->
   	t = @tabs.getById( panelId )
   	return t? and t.isActive()

   close: ->
   	@open(null)

   show: ->
   	return @open( @activePanel or @previousPanel or _.first(_.keys( @panels )))

