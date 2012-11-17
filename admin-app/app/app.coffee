People = require 'collections/people'

# Application bootstrapper.
module.exports = Application =
  initialize: ->
    window.app = @
    HomeView = require('views/home_view')
    Router = require('router')
    @homeView = new HomeView()
    @router = new Router()

    @collections = {}
    @collections.people = new People
