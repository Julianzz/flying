Url = require "lib/url"
Vfs = require "lib/vfs"
Languages = require "lib/languages"

module.exports = class File extends Chaplin.Model
  defaults: 
    "name": ""
    "size": 0
    "mtime": 0
    "mime": ""
    "href": ""
    "exists": true
    "offline": false
    "exportUrl": null

  idAttribute: "href"
    
  constructor: (@options, values ) ->
    super(values)

    @options = @options or {}
    @newFileContent = @options.newFileContent or ""

    @codinghub = @options.codinghub or require( "core/codinghub")

    @modified = false
    @_loading = false
    @_uniqueId = Date.now() + _.uniqueId("file")

    @read = @download
    
    ###
    @on "file:change:delete", ->
      @destroy()

    @on "file:change:create file:change:delete file:change:folder", ->
      @refresh()

    @listenTo @codinghub, "hub:watch:change" , (e) ->
      return if not @isValid()
      if e.data.path == @path 
        @trigger "file:change:#{e.data.change}", e.data
      if _contains(["create", "delete"], e.data.change) and @isChild( e.data.path )
        @trigger "file:change:#{e.data.change}" , e.data


    @listenTo @codinghub, "hub:watch:write", (e) ->
      if e.data.path == @path
        @trigger "file:write", e.data 
    
    ###
  syncEnvId: ->
    return if @isNewFile() then "temporary://" + @_uniqueId else "file://" + @path()

  modifiedState: (state) ->
    return if @modified == state 
    @modified = state
    @trigger "file:modified", @modified

  vfsRequest: (method, url, args ) ->
    return Vfs.execute method, args, {'url': url }

  isValid: ->
    return @get("href")?.length > 0

  vfsFullUrl: (args...) ->
    return @codinghub.baseUrl + @vfsUrl.apply(@, args)

  exportUrl: ->
    url = @get("exportUrl")
    return url if url 
    return @vfsFullUrl()

  vfsUrl: (path, force_directory) ->
    path = @path(path)
    url = @codinghub.get("vfsPrefix") + path 
    force_directory = @isDirectory if not force_directory?
    url = url + "/" if force_directory and not _.str.endsWith(url, "/")
    return url 

  path: (path) ->
    if not path?
      return null if @get("href").length == 0
      path = Url.parse( @get('href')).pathname.replace(@codinghub.get("vfsPrefix"), "") 

    if _.str.endsWith(path,"/")
      path = path.slice( 0, -1)
    if path.length == 0
      path = "/"
    if path[0] != "/"
      path = "/" + path
    return path 

  parentPath:(path) ->
    path = @path(path)
    return "/" if path == "/"
    return "/" + path.split("/").slice(0,-1).join("/")

  filename:(path) ->
    path = @path(path)
    return "/" if path == "/"
    return path.split("/").slice(-1).join("/")

  extension: ->
      return "."+this.get("name").split('.').pop()

  isDirectory: ->
    return true if @get("mime") == "inode/directory" 
    return true if @get("mime") == "inode/symlink"  and @get("linkStat.mine") == "inode/directory"
    return false

  isNewFile: ->
    return not @get( "exists")


  isChild: (path) ->
    parts1 = _.filter path.split("/"), (p) ->
      return p.length > 0
    parts2 = _.filter @path().split("/"), (p)->
      return p.length > 0

    return parts1.length == parts2.length +1

  isSublevel: (path) ->
    parts1 = _.filter path.split("/"), (p) ->
      return p.length > 0
    parts2 = _.filter @path().split("/"), (p)->
      return p.length > 0
    return parts1.length > parts2.length

  isHidden: ->
    return @get("name","").indexOf(".") == 0

  isRoot: ->
    return @path() == "/"

  icon: ->
    return "star"
    
  canOpen: ->
    return true

  paths: ->
    return _.map @path.split("/"), (name, i, parts) =>
      partialpath = parts.slice(0, i).join("/") +"/" +name
      results = 
        "path": partialpath
        "url": @codinghub.baseurl + partialpath
        "name": name 
    
  loading: (state) ->
    if Q.isPromise( state )
      @loading(true)
      state.fin =>
        @loading(false)
      return state

    return if @_loading == state 

    @_loading = state 
    @trigger "loading", @_loading

  getByPath: (path) ->

    path = @path(path)
    if path == "/"
      fileData =
        "name": this.codinghub.get("name")
        "size": 0
        "mtime": 0
        "mime": "inode/directory"
        "href": location.protocol+"//"+location.host+"/files/"
        "exists": true
      @set( fileData )

      return Q(fileData)

    parentPath = @parentPath( path )
    filename = @filename( path )

    loading = @loading( @vfsRequest("listdir", @vfsUrl(parentPath,true )) )

    loading.then (fileData) =>
      fileData = _.find fileData, (file) ->
        return file.name == filename
      if fileData?
        fileData.exists = true
        @set( fileData )
        return Q( fileData )
      else 
        return Q.reject( new Error( "can not find file "))


  getChild: (name) ->
    path = @path + "/" +name 
    f = new File
      "codinghub": @codinghub
    return f.getByPath(path).then ->
      return f
  
  refresh: ->
    @getByPath(@path()).then =>
      @trigger("refresh")

  write: (content, filename) ->
    @loading( @vfsRequest("write", @vfsUrl( filename, false) , content) ).then =>
      return @path(filename)

  listdir: (options) ->
    if not @isDirectory()
      return Q.reject(new Error("cant not list in not directory") ) 

    defaults = 
      order: "name"
      group: true

    options = _.defaults options or {} , defaults

    return @loading( @vfsRequest("listdir", @vfsUrl(null, true)) ).then (fileData) =>
        files = _.map fileData, (file) =>
          params = 
            "codinghub": @codinghub            
          return new File(params, file )

        files = _.sortBy files , (file) ->
          return file.get(options.order).toLowerCase()

        if options.group
          groups = _.groupBy files , (file) ->
            return if file.isDirectory  then "directory" else "file"
          files = [].concat(groups["directory"] or [] ).concat( groups["file"] or [])

        Q(files)
      , (err) =>
        Q.reject( new Error(err))

  isNewfile: ->
    return not @get("exists")

  mode: (file) ->
    return Languages.get_mode_byextension(@extension())

  getChildVfsPath: (filename, is_file ) ->
    path = @vfsUrl(null, true ) 
    path = path + filename 
    if not is_file
      path = path + "/"
    return path 

  open: (path, options) ->
    files = require "../core/files"
    if _.isObject(path)
      options = path
      path = @
    return files.open( path, options )

  createFile: (name) ->
    return @loading @vfsRequest('create', @getChildVfsPath(name, true )) 

  mkdir: (name) ->
    return @loading @vfsRequest('mkdir', @getChildVfsPath(name, false ) ) 

  remove: ->
    @loading @vfsRequest("remove", @vfsUrl(null)) 

  rename: ->
    parentPath = @parentPath()
    newPath = parentPath + "/" + name 
    return @loading @vfsRequest("special", @vfsUrl(newPath), { "renameFrom": @path } ) 

  copyTo: (to, newName ) ->
    newName = newName or @get("name")
    toPath = to + "/" + newName
    return @loading( @vfsRequest("special", @vfsUrl(toPath), { "copyFrom": @path() }) )

  copyFile: (from, newName) ->
    newName = newName or from.split("/").pop()
    toPath = @path() + "/" + newName
    return @loading( @vfsRequest( "special", @vfsUrl(toPath, false ), { "copyFrom": from }))

  download: (filename , options ) ->
    url = null
    d = null
    if _.isObject( filename )
      options = filename 
      filename = null 

    return Q( @newFileContent )  if @isNewFile() and not filename 

    options = _.defaults options or {}, 
      redirect: false

    if options.redirect
      window.open( @exportUrl(), "_blank") 
    else 
      @loading( @vfsRequest( "read", @vfsUrl(filename, false )) ).then (content)  =>
        return content 

  