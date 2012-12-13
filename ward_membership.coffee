async = require 'async'
config = require './config'
csv = require 'csv'
fs = require 'fs'
request = require 'request'
cronJob = require('cron').CronJob
mongoose = require('mongoose')
require './mongoose_schemas'
_ = require 'underscore'
manageLists = require './manage_lists'

exports.download = (callback) ->
  #request.post({ url: 'https://www.lds.org/login.html', form: { username: config.ldsUsername, password: config.ldsPassword }}, (error, response, body) ->
    #console.log error
    #console.log response.statusCode
    #console.log body

    #request("https://lds.org/directory/services/ludrs/unit/member-list/#{ config.ldsUnitId }/csv", (error, response, body) ->
      #console.log error
      #console.log response.statusCode
      #console.log body
  #fs.writeFile("ward.csv", body)
  body = fs.readFileSync('ward2.csv', 'utf-8')
  #console.log body
  members = []
  csv()
    .from(body, { columns: true })
    .transform( (data, index) ->
      members.push data
    )
    .on('end', ->
      callback null, members
    )
    .on('error', (error) ->
      callback error
    )
    #)
  #)


exports.save = (members) ->
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
      return
    person.address = member['Family Address']
    person.phone = member['Family Phone']

    # Try the two places the person's email could be.
    if member['Family Email']?
      person.email = member['Family Email']
    else if member['Head Of House Email']?
      person.email = member['Head Of House Email']
    else
      person.email = null

    exports.saveMemberMongo(person, callback)


  # Loop through downloaded members serially.
  async.forEachSeries members, saveMember, (err) ->
    if err then console.log err else console.log "we're done!"

    # Check if any members in the DB aren't there any more. If they're not,
    # unsubscribe them from their lists and mark that they're not in the ward any longer.
    exports.load (err, currentMembers) ->
      membersThatAreNoMore = _.filter(currentMembers, (cmember) -> if _.find(members, (member) -> return member['Head Of House Name'] is cmember.name and member['Family Phone'] is cmember.phone)? then return false else return true)
      console.log 'membersnomore', membersThatAreNoMore
      for member in membersThatAreNoMore
        # Save that they're no longer in the ward.
        member.inWard = false
        member.changed = new Date()
        member.mailchimpSynced = new Date()
        member.save( (err) -> if err then console.log err)

        # Unsubscribe from email lists.
        manageLists.unsubscribe member.email, (err, result) ->
          console.log 'unsubscribed someone from mailchimp'
          console.log result
          if err then console.log err

# Save or update ward member to MongoDB and to Mailchimp.
exports.saveMemberMongo = (person, callback) ->
  Person = mongoose.model 'Person'

  # Try to find the person in the DB. We assume a person's name + phone will stay constant.
  Person.findOne({ name: person.name, phone: person.phone }, (err, mongoPerson) ->
    if _.isNull mongoPerson
      console.log 'saving new member', person
      personModel = new Person(person)
      personModel.inWard = true
      personModel.mailchimpSynced = new Date()
      personModel.changed = new Date()
      personModel.created = new Date()
      personModel.save (err, mongoPerson) ->
        if err then callback(err)
        # Subscribe new person to list(s)
        if mongoPerson.email?
          return manageLists.subscribe(mongoPerson.email, callback)
        else
          return callback(null, mongoPerson)
    else
      # Check whether sex or email is changed.
      # If one is, we'll tell our list manager to update things.
      if person.email? and person.inWard
        if mongoPerson.email isnt person.email
          manageLists.changeEmail(mongoPerson.email, person.email)
          mongoPerson.mailchimpSynced = new Date()
        if mongoPerson.sex isnt person.sex
          manageLists.changeSex(person)
          mongoPerson.mailchimpSynced = new Date()

      # Check if any information has changed.
      if mongoPerson.email isnt person.email or mongoPerson.address isnt person.address or mongoPerson.phone isnt person.phone or mongoPerson.sex isnt person.sex or mongoPerson.inWard is false
        # Copy over new values.
        mongoPerson.email = person.email
        mongoPerson.address = person.address
        mongoPerson.phone = person.phone
        mongoPerson.sex = person.sex
        mongoPerson.inWard = true
        mongoPerson.changed = new Date()

        # Save updated person model to Mongo.
        mongoPerson.save (err, mongoPerson) ->
          if err then return callback(err) else return callback(null, mongoPerson)
      else
        console.log 'nothing needed updating'
        return callback(null, mongoPerson)
  )

# Load all current ward members (as marked by the inWard boolean).
exports.load = (callback) ->
  Person = mongoose.model 'Person'
  Person.find( { inWard: true }, (err, persons) ->
    callback(err, persons)
  )

exports.loadPeopleMissingInformation = (callback) ->
  Person = mongoose.model 'Person'
  Person.find( $or: [{ sex: null }, { email: null }], (err, persons) ->
    if err then callback(err) else callback(null, persons)
  )

syncFromMembershipList = ->
  exports.download (err, members) ->
    exports.save(members)

# Pull new members every Wednesday.
syncMembershipListJob = new cronJob('* * * * * wed', (-> syncFromMembershipList()), true)
syncFromMembershipList()
