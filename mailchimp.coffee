MailChimpAPI = require('mailchimp').MailChimpAPI
_ = require 'underscore'
config = require './config'

module.exports = class Mailchimp

  apiKey: config.mailChimpApiKey

  constructor: (@listId) ->
    try
      @api = new MailChimpAPI(@apiKey, { version : '1.3', secure : false })
    catch error
      console.log(error.message);

  # Subscribe people to a mailchimp list. Send either single email or an array of emails.
  subscribe: (emails, callback) ->
    # We're sent an array of emails -- munge them into the format Mailchimp wants and
    # send off.
    if _.isArray emails
      batch = []
      for email in emails
        batch.push { EMAIL: email }
      # http://apidocs.mailchimp.com/api/rtfm/listbatchsubscribe.func.php
      @api.listBatchSubscribe { id: @listId, batch: batch, double_optin: false }, (error, response) ->
        if error
          callback error
        else
          callback null, response
    # Else just add the single email.
    else
      # http://apidocs.mailchimp.com/api/1.3/listsubscribe.func.php
      @api.listSubscribe { id: @listId, email_address: emails, double_optin: false }, (error, response) ->
        if error
          callback error
        else
          callback null, response

  unsubscribe: (emails, callback) ->
    # We're sent an array of emails.
    if _.isArray emails
      # http://apidocs.mailchimp.com/api/rtfm/listbatchsubscribe.func.php
      @api.listBatchUnsubscribe { id: @listId, emails: emails }, (error, response) ->
        if error
          callback error
        else
          callback null, response
    # Else just remove the single email.
    else
      # http://apidocs.mailchimp.com/api/1.3/listsubscribe.func.php
      @api.listUnsubscribe { id: @listId, email_address: emails }, (error, response) ->
        if error
          callback error
        else
          callback null, response

testList = config.testList
testList = new module.exports(testList)

testList.unsubscribe ['fair-child@blue.com'], (err, response) ->
  console.log err
  console.log response
