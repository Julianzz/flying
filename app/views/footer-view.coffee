View = require './base/view'
utils = require 'lib/utils'

module.exports = class FooterView extends View
  autoRender: true
  el: '#footer'
  events:
    'click #clear-completed': 'clearCompleted'
  listen:
    'todos:filter mediator': 'updateFilterer'
    'all collection': 'renderCounter'
  template: require './templates/footer'

  render: ->
    super
    @renderCounter()

  updateFilterer: (filterer) ->
    filterer = '' if filterer is 'all'
    selector = "[href='#/#{filterer}']"
    cls = 'selected'
    @$('#filters a').each (index,link) =>
      $(link).removeClass cls
      #$(link).addClass cls if Backbone.utils.matchesSelector link, selector

  renderCounter: ->
    total = @collection.length
    active = @collection.getActive().length
    completed = @collection.getCompleted().length

    @$('#todo-count > strong').textContent = active
    countDescription = (if active is 1 then 'item' else 'items')
    @$('.todo-count-title').textContent = countDescription

    @$('#completed-count').textContent = "(#{completed})"
    utils.toggle @$('#clear-completed'), completed > 0
    utils.toggle @el, total > 0

  clearCompleted: ->
    @publishEvent 'todos:clear'
