View = require "views/base/view"
FileView = require "views/editor/FileBaseView"

module.exports = class MarkdownView extends View 

	constructor: ->
		super 
		@editor = new EpicEditor().load()
	refresh: ->
		super 
		@editor.reflow() 

		