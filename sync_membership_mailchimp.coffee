async = require 'async'
request = require 'request'
_ = require 'underscore'
fs = require 'fs'
mongoose = require('mongoose')
require './mongoose_schemas'
wardMembership = require './ward_membership'
config = require './config'
Mailchimp = require './mailchimp'

testList = config.testList
testList = new Mailchimp(testList)

# Store CSV file locally -- get either family email or head of household but prefer family if it exists
# Simplify / cleanup data
# store in mongodb as person
# If a person is removed, mark them not in the ward any longer. Pull list of names that are inWard. Remove each time iterate. Once done, any left mark as not inWard
# fetch white/black lists and store in mongodb
# write function to create master list -- i.e. those not on blacklist or are on whitelist and have needed information (email for everyone and sex to go on RS/EQ lists)
# write function which fetches people w/ missing info -- e.g. no email + no sex
# Refactor how things are organized + add config file + setup repo on Github
# write function to sync people with mailchimp -- pushes everyone to appropriate MailChimp lists

# Build backbone app for admin
# Just start with problem people view + ui for storing information sort by when added.
# write function which refreshes membership + lists and emails admin those people who have problems + links to ui for fixing them.
# Write unsubscribe text for the emails that get sent out.



# Generate a master list of people that need to be synced with MailChimp.
# This is everyone who's mailchimpSync date is earlier then their changed date
# and is still in the ward.
loadPeopleToSyncMailchimp = (callback) ->
  Person = mongoose.model 'Person'
  Person.find({ $where: "this.email != null && this.inWard && (this.mailchimpSynced == null | this.mailchimpSynced > this.changed)"}, (err, persons) ->
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
wardMembership.load (error, members) ->
  console.log members
#loadPeopleToSyncMailchimp((error, persons) -> console.log persons.length)
#loadPeopleMissingInformation((error, persons) -> console.log persons.length)
