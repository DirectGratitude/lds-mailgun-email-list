express = require('express')
app = express()
app.use(express.static(__dirname + '/admin-app/public'))
app.use(express.bodyParser())
wardMembership = require './ward_membership'

app.get '/people/missing', (req, res) ->
  wardMembership.loadPeopleMissingInformation (err, people) ->
    unless err
      for person in people
        person.setValue('id', person.getValue('_id'))
      res.json people

app.put '/people/:id', (req, res) ->
  wardMembership.saveMemberMongo(req.body, (error) ->
    if error
      res.status 500
      res.json error
    else
      res.json 'ok'
  )

app.listen(3333)
console.log 'server listening on port 3333'
