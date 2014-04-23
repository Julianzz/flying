
View = require "../base/view"
FileBaseView = require "./FileBaseView"

class EditorTab extends FileBaseView
	
	template: require "./templates/editor_tab"
	constructor: ->
		super 

	render: ->
		
		
module.exports = class EditorPannels extends view 
	
	template: require "./templates/editor_panel"

	constructor: ->
		super
		@pannels = []
		@active_pannel = null

	render: ->
		super 

		#for panel in @panels 




