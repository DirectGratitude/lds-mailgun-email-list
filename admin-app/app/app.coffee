People = require 'collections/people'

# Application bootstrapper.
module.exports = Application =
  initialize: (callback) ->
    window.app = @
    Router = require('router')
    @router = new Router()

    @collections = {}
    @collections.people = new People
    callback()
