Person = require 'models/person'

module.exports = class People extends Backbone.Collection

  model: Person
  url: '/people'

  # TODO load everyone and create a missing person function to filter out
  # those.
  initialize: ->
    $.getJSON('/people/missing', (people) =>
      @reset people
    )

  comparator: (person) ->
    return person.get('name')
