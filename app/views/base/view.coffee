Queue = require "../../lib/queue"
Keyboard = require "lib/keyboard"


module.exports = class View extends Chaplin.View
  # Precompiled templates function initializer.
  defaults: {}

  shortcuts: {} 

  constructor:(@options,parent) ->
    @cid = _.uniqueId("backbone.shortcuts")

    super 
    @initialize.apply(@, arguments)

    _.extend @, Backbone.Events
    @options = _.defaults @options or {} , @defaults or {}
    @components = {}
    @countComponents = 0
    @parent = parent or @
    @is_ready = false
    @renderQueue = new Queue()
    @setShortcuts(@shortcuts)

    #@delegateShortcuts()

  dispose: ->
    super
    #remove listening
    @stopListening()


  delegateShortcuts: ->
    return unless @shortcuts
    for shortcut, callback of @shortcuts
      method = @[callback] unless _.isFunction(callback)
      throw new Error("Method #{callback} does not exist") unless method
      match = shortcut.match(/^(\S+)\s*(.*)$/)
      shortcutKey = match[1]
      scope = if match[2] == "" then "all" else match[2]
      method = _.bind(method, @)
      key(shortcutKey, scope, method)

  setShortcuts: ( navigations,container ) ->
    navs = {}
    container = container or @

    for key,method of navigations
      navs[key] = =>
        if not _.isFunction(method) 
          method = container[method]
        console.log "method: apply:" , method 
        method.apply( container, arguments)

    Keyboard.binds(navs,null, @ )

  getTemplateFunction: ->
    @template

  finish: ->
    #console.log "inside upper finish"
    @trigger( "render")
    return @

  refresh: ->

    
  ready: ->
    #@delegateEvents()
    #console.log @finish
    @finish()
    if not @is_ready
      @trigger("ready")
      @is_ready = true
    return @

  empty: ->
    @eachComponent (component) =>
      component.$el.detach()
    @$el.empty()
    return @

  update: ->
    render = _.bind(@render, @ )
    return @renderQueue.defer(render)

  render: ->
    super 
    @ready()

  defer: (cb) ->
    d = Q.defer()
    d.promise.done(callback) if _.isFunction( cb ) 
    @on "ready", =>
      d.resolve(@)

    d.resolve(@) if @.is_ready 

    return d.promise 

  addComponent: (name, view) ->
    view.parent = @
    if @components[name]?
      @components[name] = [ @components[name] ] if not _.isArray(@components[name]) 
    else 
      @components[name] = view 

    @countComponents = @countComponents + 1

  clearComponents: ->
    @countComponents = 0
    @components = {}
    @trigger( "components:clear")

  renderComponents: ->
    if _.size( @components ) == 0
      @ready()
      return @
    n_components = 0
    
    componentRendered = =>
      n_components = n_components + 1
      if n_components >= @countComponents
        @ready()

    addComponent = (component) =>
    @$("component[data-component= #{component.cid} ]").replaceWith(component.$el)
    component.defer(_.once(componentRendered))
    promise = Q.try ->
      component.update()
    promise.fail (err) ->
      console.log "error in render component"
    return promise

    _.each @components, (value, cid ) =>
      if _.isArray(value)
        _.each value,addComponent
      else 
        addComponent value 

    @trigger("components:render")

  eachComponent: (cb) ->
    _.each @components , (value, cid ) =>
      if _.isArray( value )
        _.each(value, cb) 
      else 
        cb( value )
    return @
