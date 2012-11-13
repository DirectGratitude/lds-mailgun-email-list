async = require 'async'
request = require 'request'
csv = require 'csv'
_ = require 'underscore'
fs = require 'fs'
mongoose = require('mongoose')
require './mongoose_schemas'

# Store CSV file locally -- get either family email or head of household but prefer family if it exists
# Simplify / cleanup data
# store in mongodb as person
# If a person is removed, mark them not in the ward any longer. Pull list of names that are inWard. Remove each time iterate. Once done, any left mark as not inWard
# fetch white/black lists and store in mongodb
# write function to create master list -- i.e. those not on blacklist or are on whitelist and have needed information (email for everyone and sex to go on RS/EQ lists)

# write function which fetches people w/ missing info -- e.g. no email + no sex
# Refactor how things are organized
# Build backbone app for admin
# Just start with problem people view + ui for storing information sort by when added.
# write function which refreshes membership + lists and emails admin those people who have problems + links to ui for fixing them.
# write function to sync people with mailchimp -- pushes everyone to appropriate MailChimp lists
fetchMembershipList = (callback) ->
  #request.post({ url: 'https://www.lds.org/login.html', form: { username: 'xXxXxXxXxXx', password: 'xXxXxXxXxXx' }}, (error, response, body) ->
    #console.log error
    #console.log response.statusCode
    #console.log body

    #request('https://lds.org/directory/services/ludrs/unit/member-list/412031/csv', (error, response, body) ->
      #console.log error
      #console.log response.statusCode
      #console.log body
  #fs.writeFile("ward.csv", body)
  body = fs.readFileSync('ward.csv', 'utf-8')
  #console.log body
  membership = []
  csv()
    .from(body, { columns: true })
    .transform( (data, index) ->
      membership.push data
    )
    .on('end', ->
      callback null, membership
    )
    .on('error', (error) ->
      callback error
    )
    #)
  #)

saveMembershipListToMongo = (error, membership) ->
  Person = mongoose.model 'Person'

  # Function to save / update a person model.
  saveMember = (member, callback) ->
    # Pull out the relevant data into a person object.
    person = {}
    # They have to have a name.
    if member['Head Of House Name']?
      person.name = member['Head Of House Name']
    else
      callback(null)
    person.address = member['Family Address']
    person.phone = member['Family Phone']

    # Try the two places the person's email could be.
    if member['Family Email']?
      person.email = member['Family Email']
    else if member['Head Of House Email']?
      person.email = member['Head Of House Email']
    else
      person.email = null

    # Try to find the person in the DB. We assume a person's name + phone will stay constant.
    Person.findOne({ name: person.name, phone: person.phone }, (err, mongoPerson) ->
      if _.isNull mongoPerson
        personModel = new Person(person)
        personModel.inWard = true
        personModel.save (err) ->
          if err then callback(err)
          callback(null)
      else
        # Check if any information has changed.
        if mongoPerson.email isnt person.email or mongoPerson.address isnt person.address or mongoPerson.phone isnt person.phone or mongoPerson.inWard is false
          # Copy over new values.
          mongoPerson.email = person.email
          mongoPerson.address = person.address
          mongoPerson.phone = person.phone
          mongoPerson.inWard = true
          mongoPerson.changed = new Date()

          # Save updated person model
          mongoPerson.save (err) ->
            if err then callback(err) else callback(null)
        else
          callback(null)
    )

  async.forEachSeries(membership, saveMember, (err) ->
    if err then console.log err else console.log "we're done!"
  )

  # Check if any members in the DB aren't there any more. If they're not,
  # mark that they're not in the ward any longer.
  loadAllCurrentWardMembers (currentMembers) ->
    membersThatAreNoMore = _.filter(currentMembers, (cmember) -> if _.find(membership, (member) -> return member['Head Of House Name'] is cmember.name and member['Family Phone'] is cmember.phone)? then return false else return true)
    for member in membersThatAreNoMore
      member.inWard = false
      mongoPerson.changed = new Date()
      member.save()

# Load all current members (as marked by the inWard boolean).
loadAllCurrentWardMembers = (callback) ->
  Person = mongoose.model 'Person'
  Person.find( { inWard: true }, (err, persons) ->
    callback(persons)
  )

# Generate a master list of people that need to be synced with MailChimp.
# This is everyone who's mailchimpSync date is earlier then their changed date
# and is still in the ward.
loadPeopleToSyncMailchimp = (callback) ->
  Person = mongoose.model 'Person'
  Person.find({ $where: "this.inWard && (this.mailchimpSynced == null | this.mailchimpSynced > this.changed)"}, (err, persons) ->
    if err then callback(err) else callback(null, persons)
  )

# Return list of people missing either an email address or their sex hasn't been
# assigned yet.
loadPeopleMissingInformation = (callback) ->
  Person = mongoose.model 'Person'
  Person.find()
    .where( 'sex', null )
    .where( 'email', null )
    .exec( (err, persons) ->
      if err then callback(err) else callback(null, persons)
    )

# Kick things off.
#fetchMembershipList(saveMembershipListToMongo)
#loadPeopleToSyncMailchimp((error, persons) -> console.log persons.length)
loadPeopleMissingInformation((error, persons) -> console.log persons.length)
