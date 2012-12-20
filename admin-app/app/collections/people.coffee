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

  getWithoutSex: ->
    return @filter (person) -> return person.get('email') isnt null and person.get('sex') is null

  getWithoutSexAndEmail: ->
    return @filter (person) -> return person.get('email') is null
