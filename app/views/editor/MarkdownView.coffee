View = require "views/base/view"
FileView = require "views/editor/FileBaseView"
File = require "models/file"

module.exports = class MarkdownView extends View 

	constructor: ->
		super 
		default_files = ["readme.md"]
		file = new File()
		@readme_file = null 

		file.getByPath("/").then =>
			file.listdir().then (files) =>
				founded = _.find default_files, (name) =>
					for f in files
						if f.get("name") == name 
							@readme_file = f 
							return true
					return false

				@refresh() if founded?

		marked.setOptions 
			gfm: true
			tables: true
			pedantic: false
			sanitize: false
			smartLists: true
			smartypants: false
			langPrefix: 'lang-'

		@converter = marked
		#@editor = new EpicEditor().load()
	refresh: ->
		super 
		@render() 
		#@editor.reflow() 

	render: ->
		return if not @readme_file? 
		@readme_file.download().then (content) =>
			md = @converter(content)
			@$el.html('').html( md )
			#console.log content 


			 




		