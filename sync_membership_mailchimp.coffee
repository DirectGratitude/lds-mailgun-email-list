async = require 'async'
request = require 'request'
_ = require 'underscore'
fs = require 'fs'
mongoose = require('mongoose')
require './mongoose_schemas'
wardMembership = require './ward_membership'
config = require './config'

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
# Just start with problem people view
# write function which refreshes membership + lists
# # Able to send email to list and it gets sent on
# # google spreadsheet white lists for who (and why) can send emails to the various lists
# # cron (and on startup) for fetching the ward list csv

# Whitelist == add them manually to mailgun
# Blacklist == block them from being added but perhaps have to remove them manually from mailgun.
# Add whiters + remove blackers when sending to everyone and always remove blackers
# # Doc page w/ documentation and usernames/passwords/etc for all of this.
#
# Improve sync function so it emails admin when there's new people that need information added.
# Add ability to edit person view (add little edit button to right of row which shows up on hover and turns all of the fields into inputs)
# Add ui for showing people sorted by when added + what lists they're on.

# Kick things off.
syncFromMembershipList = ->
  wardMembership.download (err, members) ->
    wardMembership.save(members)


syncFromMembershipList()
