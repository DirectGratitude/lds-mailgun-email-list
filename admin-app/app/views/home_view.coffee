HomeTemplate = require 'views/templates/home'
PersonEditView = require 'views/person_edit_view'

module.exports = class HomeView extends Backbone.View

  id: 'home-view'

  initialize: ->
    @bindTo app.collections.people, 'reset', @render

  render: ->
    @$el.html HomeTemplate()
    @addAll()
    @

  addAll: ->
    for person in app.collections.people.models
      @addOne(person)

  addOne: (person) ->
    personEditView = @addChildView new PersonEditView model: person
    @$('table tbody').append personEditView.render().el
