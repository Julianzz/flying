View = require "views/base/view"
CodeEditor = require "views/editor/CodeEditorView"
ConsoleEditor = require "views/editor/ConsoleView"
CodeFileList = require "views/editor/CodeFileList"
MarkdownView = require "views/editor/MarkdownView"

FileManagerView = require "views/editor/FileManagerView"

files = require "core/files"

FileEditorView = require "views/editor/CodeEditorView"

module.exports = class WorkingShopView extends View

	defaults:
		#reference only - these options are NOT required because 'true' is the default
		closable:			    	true	# pane can open & close
		#resizable:					true	# when open, pane can be resized 
		#slidable:					true	# when closed, pane can 'slide' open over other panes - closes on mouse-out
		#livePaneResizing:			true

		#some resizing/toggling settings
		###north__slidable:			false	# OVERRIDE the pane-default of 'slidable=true'
		north__togglerLength_closed: '100%'	# toggle-button is full-width of resizer-bar
		north__spacing_closed:		20		# big resizer-bar when open (zero height)
		north__minSize: 			200
		north__size:				300			
		###

		south__size: 100
		south__minSize: 100
		#south__resizable:			false	# OVERRIDE the pane-default of 'resizable=true'
		#south__spacing_open:		0		# no resizer-bar when open (zero height)
		#south__spacing_closed:		20		# big resizer-bar when open (zero height)

		#some pane-size settings
		west__minSize:				100
		east__size:					300
		east__minSize:				200
		east__maxSize:				.5 #50% of layout width
		center__minWidth:			100

		#some pane animation settings
		west__animatePaneSizing:	false
		west__fxSpeed_size:			"fast"	# 'fast' animation when resizing west-pane
		west__fxSpeed_open:			1000	# 1-second animation when opening west-pane
		west__fxSettings_open:		{ easing: "easeOutBounce" } # 'bounce' effect when opening
		west__fxName_close:			"none"	#NO animation when closing west-pane


		#enable showOverflow on west-pane so CSS popups will overlap north pane
		west__showOverflowOnHover:	true

		#enable state management
		stateManagement__enabled:	true #automatic cookie load & save enabled by default

		showDebugMessages:			true # log and/or display messages from debugging & testing code

	shortcuts:
		"ctrl+s": "testKeyboard"
		#"mod+r": "runFile"
		#"mod+f": "searchInfile"
		#"ctrl+r" : "testKeyboard"

	testKeyboard: ->
		console.log "inside keyboard"

	constructor:  ->
		super 

		@layoutSettings = _.defaults @options.layout or {} , @defaults

		@layoutSettings.onresize = =>
			@refresh()

		$(document).ready =>
			myLayout = $('#ch-main-working').layout @layoutSettings
			#next time process
			setTimeout =>
				@main_container = $("#ch-main-working")

				@current_path = @options.path ? "/"
				@current_file = null 

				@console = new ConsoleEditor()
				#@filelist = new CodeFileList( { path:"/"})
				@filelist = new FileManagerView()
				
				listDom = @main_container.find(".ch-file-lists")
				listDom.append( @filelist.$el )

				@registerHander()

				newFile = files.openNew()
				@openFile( newFile )

				@markdown = new MarkdownView()

				markdownview = @main_container.find("#epiceditor-preview")
				markdownview.append(@markdown.$el)

	refresh: ->
		$("body").trigger("resize")
		
		@console.refresh()
		@markdown.refresh()
		@filelist.refresh() 
		@codeEditor.refresh() if @codeEditor?

	openFile: (file) ->

		options = 
			"path": file.path()

		if @codeEditor?
			@codeEditor.$el.detach()
			@codeEditor.dispose()
			@codeEditor = null

		@codeEditor = new CodeEditor(options) 
		body = @main_container.find(".ch-codeeditor")
		body.append( @codeEditor.$el )

	registerHander: ->
				#Add files handler
		files.addHandler "ace",
			'name': "Edit"
			'fallback': true
			'setActive': true
			'position': 1
			'valid': (file) ->
				return not file.isDirectory()
			'openFile': _.bind(@openFile, @ )

