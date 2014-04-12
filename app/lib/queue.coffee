
module.exports = class Queue
  constructor: ->
    _.extend @, Backbone.Events
    @tasks = []
    @empty = true
    return @

  defer: (task, args) ->
    d = Q.defer()
    @tasks.push 
      "task": task
      "args": args
      "result": d
    if @empty 
      @startNext()
    return d.promise

  startTask: (task) ->
    Q( task.task( task.args )).then ->
        task.result.resolve.apply( task.result, arguments )
      , ->
        task.result.reject.apply(task.result, arguments )
      .fin( _.bind( @startNext, @ ))

  startNext: ->
    if _.size( @tasks) > 0 
      @empty = false
      task = @tasks.shift()
      @startTask( task )
      @trigger("tasks:next")
    else
      @empty = true
      @trigger("tasks:finish")
  size: ->
    return _.size( @tasks )
  isComplete: ->
    return @empty == true
