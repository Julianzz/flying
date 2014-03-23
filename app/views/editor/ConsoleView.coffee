View = require 'views/kinds/RootView'

module.exports = class ConsoleView extends View 
  el : $("console")
  constructor: (options) ->
    