express = require('express')
app = express()
app.use(express.static(__dirname + '/admin-app/public'))
app.use(express.bodyParser())
wardMembership = require './ward_membership'
#require './sync_membership_mailchimp'
mailgun = require './mailgun_email_router'
spreadsheets = require './google_spreadsheet'

app.get '/people', (req, res) ->
  wardMembership.loadPeople (err, people) ->
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

app.get '/refresh-spreadsheets', (req, res) ->
  spreadsheets.fetchWhitelist()
  spreadsheets.fetchBlacklist()
  res.json 'ok'

app.post '/mailgun', mailgun

app.listen(8080)
console.log 'server listening on port 8080'
