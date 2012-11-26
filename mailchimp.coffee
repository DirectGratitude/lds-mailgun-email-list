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
  # TODO if someone is subscribed then unsubscribed then we try to subscribe them again,
  # Mailchimp won't let us. So we need to detect this and send the person an email.
  # The error code Mailchimp sends is 214. The error message includes the link needed
  # to re-signup so it should be easy to fashion an email to send to the person to
  # resign up.
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
          if _.isFunction callback then callback error
        else
          if _.isFunction callback then callback null, response
    # Else just add the single email.
    else
      # http://apidocs.mailchimp.com/api/1.3/listsubscribe.func.php
      @api.listSubscribe { id: @listId, email_address: emails, double_optin: false }, (error, response) ->
        if error
          if _.isFunction callback then callback error
        else
          if _.isFunction callback then callback null, response

  unsubscribe: (emails, callback) ->
    # We're sent an array of emails.
    if _.isArray emails
      # http://apidocs.mailchimp.com/api/rtfm/listbatchsubscribe.func.php
      @api.listBatchUnsubscribe { id: @listId, emails: emails }, (error, response) ->
        if error
          if _.isFunction callback then callback error
        else
          if _.isFunction callback then callback null, response
    # Else just remove the single email.
    else
      # http://apidocs.mailchimp.com/api/1.3/listsubscribe.func.php
      @api.listUnsubscribe { id: @listId, email_address: emails }, (error, response) ->
        if error
          if _.isFunction callback then callback error
        else
          if _.isFunction callback then callback null, response

  personInfo: (email, callback) ->
    email = [email]
    # http://apidocs.mailchimp.com/api/1.3/listmemberinfo.func.php
    @api.listMemberInfo { id: @listId, email_address: email }, (error, response) ->
      if error
        if _.isFunction callback then callback error
      else
        if _.isFunction callback then callback null, response

  changeEmail: (oldEmail, newEmail, callback) ->
    # http://apidocs.mailchimp.com/api/1.3/listupdatemember.func.php
    @api.listUpdateMember { id: @listId, email_address: oldEmail, merge_vars: { 'NEW-EMAIL': newEmail } }, (error, response) ->
      if error
        if _.isFunction callback then callback error
      else
        if _.isFunction callback then callback null, response

  inList: (email, callback) ->
    @personInfo(email, (err, response) ->
      if err then callback(err)
      else if response.success is 1 then callback null, true
      else if response.errors is 1 then callback null, false
    )
