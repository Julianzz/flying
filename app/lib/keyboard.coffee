
class Keyboard 

    constructor: ->
        @bindings = {}

    enableKeyEvent: (e) ->
        e.mousetrap = true

    handleKeyEvent: (e) ->
        e.mousetrap = true
        return Mousetrap.handleKeyEvent(e)

    bind__: (key, callback, context ) ->

        if not @bindings[key]?
            object = {}
            _.extend(object, Backbone.Events)

            @bindings[key] = object
            Mousetrap.bind keys, (e) =>
                @bindings[key].trigger("action", e )

        @bindings[key].on( "action", callback, context ) 

    bind_ : (key, callback, context) ->
        
        object = @bindings[key]
        if not @bindings[key]?
            object = {}
            @bindings[key] = object
            
            _.extend( object, Backbone.Events )
            Mousetrap.bind key, (e) =>
                @bindings[key].trigger("action", e )

        ##convient to undelete 
        context.listenTo( object, "action", callback, context )

        @bindings[key].on "action", (e) =>
            console.log callback
            #callback()
            console.log "continue to listen ", e 


    binds: ( keys, callback, context) ->

        if _.isArray( keys )
            _.each keys, (key) =>
                @bind_( key, callback,context )
            return 

        if _.isObject(keys)
            _.each keys, (method, key) =>
                @bind_(key, method,context)
            return 


    toText: (shortcut) ->
        if _.isArray( shortcut ) 
            shortcut = _.first( shortcut )
        return null if not shortcut?

        isMac = /Mac|iPod|iPhone|iPad/.test(navigator.platform)

        shortcut = shortcut.replace "mod", if isMac then "&#8984" else "ctrl"

        shortcut = shortcut.replace("ctrl", "^" )

        shortcut = shortcut.replace("shift", "⇧")
        
        if isMac
            shortcut = shortcut.replace("alt", "⌥")
        else
            shortcut = shortcut.replace("alt", "⎇")

        shortcut = shortcut.replace(/\+/g, " ")

module.exports = new Keyboard() 
