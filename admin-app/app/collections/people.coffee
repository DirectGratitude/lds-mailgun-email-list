Person = require 'models/person'

module.exports = class People extends Backbone.Collection

  model: Person

  initialize: ->
    $.getJSON('/people/missing', (people) =>
      console.log people
      @reset people
    )
