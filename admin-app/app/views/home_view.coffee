HomeTemplate = require 'views/templates/home'
PersonEditView = require 'views/person_edit_view'

module.exports = class HomeView extends Backbone.View

  id: 'home-view'

  initialize: ->
    @bindTo app.collections.people, 'reset', @addAll

  events:
    'click .reload-spreadsheets': 'reloadSpreadsheets'

  # Render first people w/o sex then w/o email.
  render: ->
    @$el.html HomeTemplate()
    @

  addAll: (models, options) ->
    if app.collections.people.models.length > 0
      @$('table tbody').empty()
      for person in app.collections.people.models
        @addOne(person)
    else
      @$('table tbody').html '<tr><td>There are no people with missing information to add right now</tr></td>'

  addOne: (person) ->
    personEditView = @addChildView new PersonEditView model: person
    @$('table tbody').append personEditView.render().el

  reloadSpreadsheets: ->
    $.get '/refresh-spreadsheets', (res) ->
      console.log res
