
File = require "./file"

module.exports = class CodingHub extends Chaplin.Model
	defaults:
		'name' : ""
		'vfsPrefix': '/files'
		'status': null
		'name': null
		'uptime': 0
		'mtime': 0
		'auth': false

	constructor: ->
		super()
		@user  = null
		options = 
			'codinghub': @

		@root = new File( options )
		@root.getByPath( "/" )

		@on "hub:change:name", ->
			@root.set("name", @get("name"))

		@activeFile = "/"

