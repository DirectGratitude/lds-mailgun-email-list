application = require('app');
HomeView = require('views/home_view')

module.exports = class Router extends Backbone.Router

  routes:
    '': 'home'

  home: ->
    $('body').html new HomeView().render().el
