
File = require "../models/file"
Files = require "../collections/files"
codinghub = require "./codinghub"
CodeEditor = require "views/editor/CodeEditorView"


module.exports.open = ->

# Recent files
recentFiles = new Files()

recentFiles.on "add", ->
	console.log "recent files:", recentFiles 
	#Limit collection size
	recentFiles.shift() if recentFiles.size() > 20

#Active files
activeFiles = new Files()

#Files handlers map
handlers = {}

codeEditor = null 

addHandler = (handlerId, handler) ->
	throw "Invalid files handler format" if not( handlerId? and handler?.name? and handler?.valid? ) 
	throw "Invalid files handler format" if not handler?.openFile?

	handler = _.defaults handler, 
		'setActive': false
		'fallback': false
		'position': 10

	handler.id = handlerId
	if handler.openFile 
		openFile = handler.openFile
		handler.open = (file) ->
			path = file.path()
			uniqueId = handler.id + ":" +file.syncEnvId()
			#Add files as open
			activeFiles.add(file) if handler.setActive
			openFile( file )
	else 
		console.error "register handler error,please provide openFile "
		return null 

	#Register handler
	handlers[handlerId] = handler
	return handlers[handlerId]


#Get handler for a file
getHandlers = (file) ->
	chain = _.chain(handlers).filter (handler) ->
		#return userSettings.get(handler.id, true) and handler.valid(file)
		return handler.valid(file)

	chain.sortBy (handler) ->
		return handler.position or 10
	
	return chain.value()

#get fallback handlers for a file
getFallbacks = (file) ->
	return _.filter handlers, (handler) ->
  		return userSettings.get(handler.id, true) and  handler.fallback == true

openFileHandler = (handler, file) ->
	recentFiles.add(file) if not file.isNewfile() 
	return Q(handler.open(file)).then ->
		codinghub.setActiveFile(file)


openFileWith = (file) ->
	choices = {}
	_.each handlers, (handler) ->
		choices[handler.id] = handler.name
	
	if _.size(choices) == 0
		return Q.reject(new Error("No handlers for this file"))
	
	return dialogs.select("Can't open this file", "Sorry, No handler has been found to open this file. Try to find and install an add-on to manage this file or select one of the following handlers:", choices).then (value) ->
  		handler = handlers[value] 
  		return Q(openFileHandler(handler, file))

openFile = (file, options) ->
	options = _.defaults {}, options or {},
		'userChoice': false
		'useFallback': true

	if _.isString(file)
		nfile = new File { 'codinghub': codinghub }
		return nfile.getByPath(file).then ->
			return openFile(nfile, options)

	possibleHandlers = getHandlers(file)

	if _.size(possibleHandlers) == 0 and  options.useFallback 
		possibleHandlers = getFallbacks()

	if _.size(possibleHandlers) == 0
		return openFileWith(file)

	if _.size(possibleHandlers) == 1 or options.userChoice != true 
		return Q(openFileHandler(_.first(possibleHandlers), file)) 

	choices = {}
	_.each possibleHandlers, (handler) ->
		choices[handler.id] = handler.name

	if _.size(choices) == 0 
		return Q.reject(new Error("No handlers for this file")) 

	return dialogs.select("Open with...", "Select one of the following handlers to open this file:", choices).then (value) ->
		handler = handlers[value]
		return Q(openFileHandler(handler, file))

openNew = (name, content) ->
	name = name or "untitled"
	file_info = 
		'name': name,
		'size': 0,
		'mtime': 0,
		'mime': "text/plain",
		'href': location.protocol+"//"+location.host+"/files/"+name,
		'exists': false
	
	f = new File
		'newFileContent': content or  ""
		'codinghub': codinghub
	return f

module.exports = 
	'addHandler': addHandler
	'getHandlers': getHandlers
	'open': openFile
	'openNew': openNew
	'recent': recentFiles
	'active': activeFiles
    