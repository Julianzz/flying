View = require "views/base/view"

File = require "models/file"

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
		hub.on "file.active", (path) =>
			@$el.toggleClass "active", @model.path() == path 

	finish: ->
		#console.log "inside finish "
		@$el.toggleClass( "disabled", not @model.canOpen() )
		@$(">.name").css( "padding-left", @paddingLeft )
		@$el.toggleClass( "type-directory", @model.isDirectory() )

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
			hub.trigger( "directory:visit", @model )
		else 
			@open()


class FileTreeView extends FileBaseView

	tagName: "ul"
	className: "ch-files-tree"

	constructor: ->
		super 
		@ItemView = @options.Item or FilesTreeItemView
		@paddingLeft = @options.paddingLeft or 10 
		@update()

	refresh :->
		@empty()
		@update() 

	render: ->
		@model.listdir().then (files) =>
			_.each files , (file) =>
				if file.isHidden()
					return 
				item = new @ItemView 
					"codinghub": @codinghub
					"model": file 
					"paddingLeft": @paddingLeft

				item.update().then =>
					item.$el.appendTo( @$el )


		@ready()


module.exports = class FileManagerView extends View
	
	template: require "./templates/filelist"
	className: "file-manager-container"

	events:
		"click .action-create-folder" : "createFolder"
		"keyup .new-folder-name" : "newFolder"
		"click .action-to-parent" : "visitParent"
		"click .action-add-new-file": "showNewFile"
		"keyup .new-file-name": "addNewFile"
	newFileItem: require "./templates/new_file_item"

	constructor: ->
		super
		@current_path = new File()

		@update().then =>

			@file_list_item = @$(".list-group")
			@file_list_item.append(  $( @newFileItem() ) )
			@new_file_item = @$(".new-file-name").hide()

			@current_path.getByPath("/").then =>
				console.log "inside visit "
			
				@createFileList()
				@el_create_folder = @$(".action-new-folder-name")
				@el_new_folder_name = @$(".action-new-folder-name")
				@el_folder_name = @$('.action-new-folder-name input')
				@el_new_folder_name.hide()

		hub.on "directory:visit" , (model) =>
			console.log "visit",model, model.path()
			return if not model?
			return if model.path() == @current_path.path()
			console.log model.path()
			@current_path = model 
			@createFileList()
			console.log "receive visit message "

	createFileList: ->
		if @filelist
			@filelist.$el.detach()
			@filelist.dispose()

		@filelist = new FileTreeView
			model: @current_path

		@file_list_item.append( @filelist.$el )

	visitParent: (e) ->
		return if @current_path.isRoot() or not @current_path.isDirectory()
		parent_path = @current_path.parentPath()
		@current_path = new File()
		@current_path.getByPath( parent_path ).then =>
			@createFileList()

	newFolder: (e) ->
		e.preventDefault() if e?
		@el_new_folder_name.toggle() if e.keyCode == 13
				
	showNewFile: (e) ->
		@new_file_item.toggle()
		@$(".action-add-new-file").toggle()

	addNewFile: ( e ) ->
		if e.keyCode == 13
			#console.log _.string.trim
			new_file_name = _.string.trim( @new_file_item.val() )
			if new_file_name == ""
				@new_file_item.toggle()
				@$(".action-add-new-file").toggle()
				return 

			console.log "begin to list dir"
			@current_path.listdir().then (files) =>
				for file in files
					name = file.get('name')
					console.log file.get('name'), new_file_name, file.get('name') == new_file_name
					if name == new_file_name
						console.log "error file name" 
						return  

				@current_path.createFile( new_file_name ).then =>
					console.log "inside create "
					@filelist.refresh() if @filelist
					@new_file_item.toggle()
					@$(".action-add-new-file").toggle()
				.fail (error) =>
					console.log error ,"nnn "
	createFolder: (e)->
		@el_new_folder_name.toggle()
		console.log "inside create folder"





