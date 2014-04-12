
File = require "../models/file"
Collecton = require "./base"

module.exports = class Files extends Collecton
	model: File 

	constructor: ->
		super 