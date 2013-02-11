config = require './config'
Mailgun = require './mailgun'
everyoneList = new Mailgun(config.everyoneList)
eqList = new Mailgun(config.eqList)
rsList = new Mailgun(config.rsList)
spreadsheets = require './google_spreadsheet'
_ = require 'underscore'

inBlacklist = (email) ->
  result = _.find spreadsheets.blacklist, (person) -> return person.Email is email
  if result?
    return true
  else
    return false

exports.subscribe = (email, callback) ->
  unless inBlacklist(email)
    everyoneList.subscribe(email, callback)
  else
    callback(null)

# Unsubscribe from the main list and from sub-lists.
exports.unsubscribe = (email, callback) ->
  everyoneList.unsubscribe(email, callback)

  # Check if they're on other lists and unsubscribe them there as well.
  eqList.inList email, (err, inList) ->
    if inList
      eqList.unsubscribe email
  rsList.inList email, (err, inList) ->
    if inList
      rsList.unsubscribe email

exports.changeEmail = (oldEmail, newEmail) ->
  console.log 'updating email in mailchimp from ' + oldEmail + ' to ' + newEmail
  # Check if email is on main list. If not, subscribe them.
  everyoneList.inList oldEmail, (err, inList) ->
    if err
      console.log err
    else
      if inList
        everyoneList.changeEmail(oldEmail, newEmail)
      else
        everyoneList.subscribe(newEmail)

      # Change in EQ/RS lists if member there.
      eqList.inList oldEmail, (err, inList) ->
        if inList
          eqList.changeEmail(oldEmail, newEmail)
      rsList.inList oldEmail, (err, inList) ->
        if inList
          rsList.changeEmail(oldEmail, newEmail)

exports.changeSex = (person) ->
  if person.sex is 'f'
    eqList.inList person.email, (err, inList) ->
      if inList
        eqList.unsubscribe person.email
    rsList.inList person.email, (err, inList) ->
      unless inList
        console.log 'subscribing person to rsList'
        rsList.subscribe person.email
  else
    rsList.inList person.email, (err, inList) ->
      if inList
        rsList.unsubscribe person.email
    eqList.inList person.email, (err, inList) ->
      unless inList
        console.log 'subscribing person to eqList'
        eqList.subscribe person.email
