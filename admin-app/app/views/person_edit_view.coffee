PersonEditTemplate = require 'views/templates/person_edit'

module.exports = class PersonEditView extends Backbone.View

  tagName: 'tr'

  events:
    'focusout input': 'leaveInput'
    'focusin input': 'enterInput'

  initialize: ->
    @bindTo @model, 'noerror', ->
      @$('.messages').html ''
      @$('td').last().removeClass('error')

  render: ->
    @$el.html PersonEditTemplate(
      name: @model.get('name')
      email: @model.get('email')
      sex: @model.get('sex')
    )
    @

  enterInput: ->
    @rowActive = true

  leaveInput: (e) ->
    @rowActive = false
    # Delay so we know that the person has in fact left the row not just moved
    # between inputs within a row.
    _.delay(( =>
      unless @rowActive
        sex = @$('input.sex').val()
        email = @$('input.email').val()
        data = {}
        unless _.isUndefined sex
          if sex isnt "" then data.sex = sex
        unless _.isUndefined email
          if email isnt "" then data.email = email
        # If there's no new data, don't save.
        unless _.isEmpty data
          @model.save(data,
            success: (model, response) =>
              @$('td').last().removeClass('error')
              @$('.messages').html 'saved!'
            # If there's an error, show the message.
            error: (model, xhr, options) =>
              @$('td').last().addClass('error')
              # If the error is from our client-side validation it'll just be
              # a string.
              if _.isString xhr
                @$('.messages').html xhr
              # Else, it'll be within the response object from the server.
              else
                @$('.messages').html xhr.status + " " + xhr.responseText
          )
      ), 100
    )
