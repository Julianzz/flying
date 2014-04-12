
module.exports = class FileSync 

	modes:
		ASYNC: "async"
		SYNC: "sync"
		READONLY: "readonly"

	constructor: (@options)->
		_.extend @, Backbone.Events
		@synced = false
		@file = null
		@setFile( @options.file) if @options?.file? 

	setMode: (mode) ->
		@mode = mode;
		@trigger( "mode", mode )

	getMode: ->
		return @mode 

	setContent: (content) ->
		console.log( "update content ")
		oldmode_sync = @sync 
		@sync = false
		oldcontent = @content_value_t0

		@content_value_t1 = content 
		@trigger "content", content, oldcontent

		@sync = oldmode_sync 

		return @


	setFile: (file, options) ->
		options = _.defaults {} , options or {}, 
			sync: false
			reset: true
			autoload: true

		#console.log "-----", file.attributes
		if not file.isValid() 
			console.log "invalid file for sync " ,file 
			return @

		@file  = file 

		if file?
			@file.on("change", _.bind( @setFile, @, @file, options ) )  
			@file.on("modified", _.bind( @trigger, @ , "sync:modified")) 
			@file.on("loading", _.bind( @trigger, @, "sync:loading")) 

			@trigger "file:mode", @file.mode()

			if options.autoload 
				@on "file:path", (path) =>
					@file.getByPath(path)

			@updateEnv @file.syncEnvId(), options
		return @

	updateEnv: (envId, options ) ->
		options = _.defaults {} , options or {} ,
			sync: false
			reset: false

		return @ if not envId 

		options.sync = false if @file.isNewfile() 
		@envOptions = options 
		@envId = envId

		@content_value_t1 = @content_value_t1 or ""
		if options.reset 
			@content_value_t1 = ""

		@trigger "update:env", options 

		if not options.sync 
			@setMode( @modes.READONLY )
			@file.download().then (content) =>
					#console.log "donwload content:", content
					@file.modifiedState( false )
					@setContent( content )
					@setMode( @modes.ASYNC )
				, (err) =>
					console.log "Error for open file ", err 
					@trigger "close"
		else 
			@setMode( @modes.ASYNC )
			@setContent( @content_value_t1 or "" )

		return @

	isReadonly: ->
		return @getMode() == @modes.READONLY

	updateContent: (value) ->
		return if not value or @isReadonly() 

		@content_value_t1 = value 
		@timeOfLastLocalChange = Date.now()
		@file.modifiedState(true)

	save: ->
		doSave = (args) ->
			return Q()

		if @getMode() ==  @modes.ASYNC 
			doSave = (args) =>
				console.log "update contente:", @content_value_t1
				return @file.write( @content_value_t1, args.path ).then (newPath) =>
						@file.modifiedState( false ) 
						if not newPath == @file.path()
							@trigger "file:path", newPath 
					, (err) =>
						@trigger "error"

		
		if @file.isNewfile()
			return dialogs.prompt("Save As", "", @file.filename()).then (name) =>
				return doSave( { path:name} )
		else
			return doSave {}

	dispose : ->
		#clearInterval( @timer )
		@file.modifiedState(false) 
