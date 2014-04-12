
view = require "../base/view"
hub = require "core/codinghub"
FileBaseView = require "./FileBaseView"


class FilesTreeItemView extends FileBaseView 
	tagName: "li"
	className: "file-item"
	template : require "./templates/item"

	events:
		"click .name": "select"
		"dblclick .name": "open"

	constructor: ->
		super
		@subFiles = null
		@paddingLeft = @options.paddingLeft or 0

		#ContextMenu.add(this.$el, this.model.contextMenu());

		hub.on "file.active", (path) =>
			@$el.toggleClass "active", @model.path() == path 


	render: ->
		@subFiles.detach() if @subFiles?
		super 

	finish: ->
		#console.log "inside finish "
		@$el.toggleClass( "disabled", not @model.canOpen() )
		@$(">.name").css( "padding-left", @paddingLeft )
		@$el.toggleClass( "type-directory", @model.isDirectory() )

		@subFiles.$el.appendTo( @$(".files")) if @subFiles 

		super

	open: (e) ->
		if e?
			e.preventDefault()
			e.stopPropagation()
			
		if not @model.canOpen()
			return 

		if not @model.isDirectory()
			@model.open( { 'userChoice':false })
		else 
			@select()

	select: (e) ->
		if e?
			e.preventDefault()
			e.stopPropagation()
		if not @model.canOpen()
			return 

		if @model.isDirectory()
			if not @subFiles?
				#console.log "append subFiles", @model
				@subFiles = new FileTreeView 
					"codinghub": @codinghub
					"model": @model
					"paddingLeft": @paddingLeft + 15
				@subFiles.$el.appendTo( @$(".files") )
				@subFiles.update()

			@$el.toggleClass("open")

		else 
			@open()


module.exports = class FileTreeView extends FileBaseView

	tagName: "ul"
	className: "ch-files-tree"

	constructor: ->
		super 
		@countFiles = 0
		@ItemView = @options.Item or FilesTreeItemView

		@paddingLeft = @options.paddingLeft or 10 
		#panelSettings.user.change =>
		@update().then =>
			console.log "append", @$el, @$el.html()

	render: ->
		@$el.toggleClass "root", @model.isRoot()
		#ContextMenu.add( @$el, @model.contextMenu )
		#console.log @model

		@model.listdir().then (files) =>
			@clearComponents()
			@empty()
			@countFiles = 0
			_.each files , (file) =>
				if file.isHidden()
					return 
				item = new @ItemView 
					"codinghub": @codinghub
					"model": file 
					"paddingLeft": @paddingLeft
				item.update().then =>
					item.$el.appendTo( @$el )
				#@addComponent("file", item )
				@countFiles = @countFiles + 1

			@trigger( "count", @countFiles )

		@ready()

		