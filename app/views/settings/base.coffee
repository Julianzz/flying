
View = require "../base/view"


class SettingsPageview  extends View

  template: require "../templates/settings/base"
  defaults:
    'namespace': ""
    'title': ""
    'settings': {}
  events:
    "click button[data-settings-action]": "triggerFieldAction"

  initialize: (args...)->
    super(args...)
    user = require("core/user")

    @namespace = @options.namespace
    @title = @options.title || @namespace
    @fields = @options.fields || {}
    @defaults = @options.defaults or {}
    @user = user.settings(@namespace)

  setField: (fieldId, field) ->
    @fields[fieldId] = field
    @trigger("field:change", fieldId)
    return @

  templateContext: ->
    context =
      'fields': @fields
      'defaults': @defaults
      'namespace': @namespace
      'section': @section

  triggerFieldAction: (e) ->
    e.preventDefault()

    $btn = $(e.currentTarget)
    fieldId = $btn.data("settings-action")

    return if not @fields[fieldId]

    $btn.button("loading")
    @fields[fieldId].trigger(fieldId).fin ->
      $btn.button("reset")

  submit: ->
    data = {}

    selectors =
      'text': (el) -> return el.val()
      'password': (el)-> return el.val()
      'textarea': (el)-> return el.val()
      'number': (el)-> return el.val()
      'select': (el) ->return el.val()
      'checkbox': (el)-> return el.is(":checked")
      'action': (el) -> return null

    _.each @fields, (field, key) ->
      v = selectors[field.type](that.$("*[name='"+ @namespace+"_"+key+"']"))
      data[key] = v if v?

    return data;