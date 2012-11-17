express = require('express')
app = express()
app.use(express.static(__dirname + '/admin-app/public'))
wardMembership = require './ward_membership'

app.get '/people/missing', (req, res) ->
  wardMembership.loadPeopleMissing (err, people) ->
    unless err
      res.json people

app.listen(3333)
console.log 'server listening on port 3333'
