

#负责寄送和其他ajax的请求调用
module.exports = class Requests  

  @defaults: 
    url: null
    method: "GET"
    params: {}
    dataType: "text"
    options: {}
    
  constructor: (options)->
    _.extend(@, Backbone.Events)
    @options = _.clone(@constructor.defaults)
    _.extend( @options, options )
    
  execute: ->
    params = 
      "type": @options.method
      "url" : @options.url
      "data": @options.params 
      "dataType": @options.dataType
      "context": @
    
    @xhr = $.ajax( params )

    @xhr.done (data) ->
      @trigger("done", data)

    @xhr.fail (xhr, textStatus, errorThrown) ->
      params = 
        'textStatus': textStatus
        'error': errorThrown
        'content': xhr.responseText
        'xhr': xhr
      @trigger "error", params
  
  @_execute: (url, options, defaults) ->

    d = Q.defer()
    options = options or {}
    defaults = defaults or {}
    
    options = _.extend options, defaults,
      "url": url
      
    r = new Requests(options)
    r.on "done", (content) ->
      d.resolve(content)
        
    r.on "error", (err) ->
      e = new Error(err.textStatus+": "+err.content)
      e.textStatus = err.textStatus
      e.httpRes = err.content
      d.reject(e)

    r.execute()
    return d.promise
    
  @get: (url, args, options) =>
    params = 
      method: "GET"
      params: args
    return @_execute url, options, params


  @getJSON: (url, args, options) =>
    params = 
      method: "GET"
      params: args
      dataType: "json"
    return @_execute url, options, params 


  @post: (url, args, options) =>
    params = 
      method: "POST"
      params: args
    return @_execute url, options, params


  @put: (url, args, options) =>
    params = 
      method: "PUT"
      params: args

    return @_execute url, options, params


  @delete: (url, args, options) =>
    params = 
      method: "DELETE" 
      params: args
    return @_execute url, options, params

  @head: (url, args, options) =>
    params = 
      method: "HEAD"
      params: args
    return @_execute url, options, params
