config = require './config'
Mailchimp = require './mailchimp'
testList = new Mailchimp(config.testList)

exports.subscribe = (email, callback) ->
  testList.subscribe(email, callback)

# Unsubscribe from the main list and from sub-lists.
exports.unsubscribe = (email, callback) ->
  console.log email
  testList.unsubscribe(email, callback)
  # TODO check if they're on other lists and unsubscribe them as well.

exports.changeEmail = (oldEmail, newEmail) ->
  console.log 'updating email in mailchimp'
  # Check if email is on main list. If not, subscribe them.
  testList.inList oldEmail, (err, inList) ->
    if err
      console.log err
    else
      if inList
        testList.changeEmail(oldEmail, newEmail)
      else
        testList.subscribe(newEmail)

  # TODO check for both
  # rs and eq lists if the person is in that list and if they are, change their
  # email.

exports.changeSex = (person) ->
  console.log 'person in changeSex', person
  # TODO check if
  # check each list -- if already on correct list, don't subscribe, otherwise do
  # if on wrong list, unsubscribe.
