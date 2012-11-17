async = require 'async'
config = require './config'
csv = require 'csv'
fs = require 'fs'
request = require 'request'
mongoose = require('mongoose')
require './mongoose_schemas'
_ = require 'underscore'

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


exports.save = (membership) ->
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

    # Try to find the person in the DB. We assume a person's name + phone will stay constant.
    Person.findOne({ name: person.name, phone: person.phone }, (err, mongoPerson) ->
      if _.isNull mongoPerson
        personModel = new Person(person)
        personModel.inWard = true
        personModel.save (err) ->
          if err then callback(err)
          callback(null)
          return
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
            return
        else
          callback(null)
          return
    )

  async.forEachSeries(membership, saveMember, (err) ->
    if err then console.log err else console.log "we're done!"
  )

  # Check if any members in the DB aren't there any more. If they're not,
  # mark that they're not in the ward any longer.
  exports.load (err, currentMembers) ->
    membersThatAreNoMore = _.filter(currentMembers, (cmember) -> if _.find(membership, (member) -> return member['Head Of House Name'] is cmember.name and member['Family Phone'] is cmember.phone)? then return false else return true)
    for member in membersThatAreNoMore
      member.inWard = false
      mongoPerson.changed = new Date()
      member.save()

# Load all current members (as marked by the inWard boolean).
exports.load = (callback) ->
  Person = mongoose.model 'Person'
  Person.find( { inWard: true }, (err, persons) ->
    callback(err, persons)
  )

exports.loadPeopleMissing = (callback) ->
  Person = mongoose.model 'Person'
  Person.find( $or: [{ sex: null }, { email: null }], (err, persons) ->
      if err then callback(err) else callback(null, persons)
  )
