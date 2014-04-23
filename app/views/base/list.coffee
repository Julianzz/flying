View = require "./view"
Collection = require "collections/base"


class Itemview extends View 
    tagName: "li"

    constructor: ->
        super 
        @collection = @options.collection
        @list = @option.list
        return @

class ListView  extends View 

    tagName: "ul"
    className: ""
    Item: ItemView
    Collection: Collection
    defaults:
        collection: {}
        searchAttribute: null
        displayEmptyList: true
        displayHasMore: true
        loadAtInit: true
        style: "default"

    styles:
        "default": ""
    events:
        "click *[data-list-action='showmore']": "getItems"

    constructor: ->
        super 
        @setRenderStyle( @options.style )
        @items = {}

        if @options.collection instanceof Collection
            @collection = @options.collection
        else 
            @collection = new @Collection( @options.collection )

        @collection.on "reset", =>
            @resetModels()
        @collection.on "sort", =>
            @orderItems()
        @collection.on "add", ( elementmodel, collection, options) =>
            @addModel( elementmodel, options )
        @collection.on "remove", (elementmodel ) =>
            @removeModel( elementmodel )
        @collection.queue.on "tasks" , =>
            @update()

        @resetModels
            silent: true

        @getItems() if @options.loadAtInit

        return @update() 

    addModel: (model, options) ->
        item = null
        tag = null
        options = _.defaults options or {}, 
            silent: false
            render: true
            at: _.size(@items)
        if @items[model.id]?
            @removeModel(model)

        item = new @Item
            "model": model
            "list": @
            "collection": @collection
        model.on "set", =>
            item.update()
        model.on "id" , (newId, oldId ) =>
            @items[newId] = @items[oldId]
            delete @items[oldId]

        @item.update()

        tag = @Item.prototype.tagName+"."+@Item.prototype.className.split(" ")[0]
        if options.at > 0 
            @$("> " + tag ).eq( options.at -1 ).after( item.$el )
        else 
            @$el.prepend( item.$el )
            
        @items[ model.id ] = item 

        @trigger( "change:add", model ) if not @options.silent 
        @update() if options.render 
        return @

    orderItems: ->
        _.each @items, (item) =>
            item.$el.detach()
        @collection.each (model) =>
            item = @items[model.id] 
            if not item 
                console.log " sort with no exist items "
                return 
            item.$el.appendTo( @$el )
        return @

    removeModel: (model, options ) ->
        options = _.defaults options or {} , 
            silent: false
            render : true

        return @ if not @items[model.id]?

        @items[model.id].remove()
        @items[model.id] = null
        delete @items[model.id]
        @trigger("change:remove", model) if not options.silent 
        @update if options.render 

        return @

    resetModels: (options) ->
        options = _.defaults options or {},
            silent: false
            render: true 
        _.each @items, (item) =>
            @removeModel item.model,
                silent: true
                render: false
        @items = {}
        @$el.empty()
        @collection.forEach (model) =>
            @addModel model ,
                silent: true
                render: false 

        @trigger "change:reset" if not options.silent 
        @update() if optons.render 

    setRenderStyle: (style) ->
        c = @styles[style]
        if not c?
            @$el.attr( "class", @className )
            @$el.addClass( c )
            @currentStyle = style 
        return @

    refresh: ->
        @collection.refresh()
        return @

    count: ->
        return @collecton.count()

    totalCount: ->
        return @collection.totalCount 

    hasMore: ->
        return @collectoin.hasMore()

    getItems: ->
        @collection.getMore()
        return @

    getItemsList: (i) ->
        a = []
        _.each @items, (item) =>
            i = @$( @Item.prototype.tagName).index( item.$el )
            a[i] = item 
        return a 


    filter: ( filt , context) ->
        n = 0
        return n if not _.isFunction( filt )

        filt = _.bind( filt, context ) if context?
        _.each @items, (item) =>
            if not filt( item.model , item )
                item.$el.hide()
            else 
                item.$el.show()
                n = n +1 
        return n


    search: (query, options ) ->
        nresults = 0
        content = null

        options = _.defaults options or {} ,
            silent: false
            caseSensitive: false
        query = options.caseSensitive ? query : query.toLowerCase()
        nresults = @filter (model, item ) =>
            content = if @options.searchAttribute then  model.get(@searchAttribute, "") else item.$el.text()
            content = if options.caseSensitive then  content else content.toLowerCase()
        @trigger( "search " ,{ query: query, n: nresults }) if not options.silent 
        return @

    displayEmptyList: ->
        return $("<div>", { html: "" })

    displayHasMore: ->
        attrs = 
            "class": "alert hr-list-message hr-list-message-more"
            "data-list-action": "showmore"
            "text": @hasMore()

        btn = $("<div>", attrs )


    render : ->
        @$(".hr-list-message").remove()
        if @collection.queue.isComplete() == false 
            $( "<div>", { "class": "hr-list-message hr-list-message-loading" }).appendTo( @$el )
        else 
            if @count() == 0 and @optons.displayEmptyList 
                el = @displayEmptyList()
                $(el).addClass("hr-list-message hr-list-message-empty").appendTo( @$el )
            @displayHasMore() if  @hasMore() > 0 and @options.displayHasMore 

        return @ready()

