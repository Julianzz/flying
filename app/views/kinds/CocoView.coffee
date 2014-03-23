
module.exports = class CocoView extends Backbone.View
  startsLoading: false
  cache: true # signals to the router to keep this view around
  template: -> ''
  events:{}

  subscriptions: {}
  shortcuts: {}
