_ = require 'underscore'
config = require './config'
url = require 'url'
request = require 'request'
querystring = require 'querystring'
sendEmail = require './send_email'

module.exports = class Mailchimp

  apiKey: config.mailgunApiKey

  constructor: (@address) ->
    switch @address
      when "eq@stanford2.mailgun.org" then @subject = "[2NDWARD EQ]"
      when "everyone@stanford2.mailgun.org" then @subject = "[2NDWARD]"
      when "rs@stanford2.mailgun.org" then @subject = "[2NDWARD RS]"

  subscribe: (emails, callback) ->
    console.log "subscribed #{ emails } to #{ @address }"
    mailgun_uri = url.parse("https://api.mailgun.net/v2/lists/#{ @address }/members")
    mailgun_uri.auth = config.mailgunAPI
    apiSubscribe = (email_address) ->
      body = querystring.stringify(address: email_address)
      request(
        url: mailgun_uri
        method: 'POST'
        headers:
          'content-type': 'application/x-www-form-urlencoded'
        body: body
        (error, response, body) ->
          if _.isFunction callback
            callback null, body, response.statusCode
      )

    # We're sent an array of emails -- munge them into the format Mailchimp wants and
    # send off.
    if _.isArray emails
      for email in emails
        apiSubscribe(email)
    # Else just add the single email.
    else
      apiSubscribe(emails)

  unsubscribe: (email, callback) ->
    console.log "unsubscribed #{ email } from #{ @address }"
    mailgun_uri = url.parse("https://api.mailgun.net/v2/lists/#{ @address }/members/#{ email }")
    mailgun_uri.auth = config.mailgunAPI
    request(
      url: mailgun_uri
      method: 'DELETE'
      (error, response, body) ->
        if _.isFunction callback
          callback null, body, response.statusCode
    )


  # GET /lists/<address>/members/<member_address>
  personInfo: (email, callback) ->
    mailgun_uri = url.parse("https://api.mailgun.net/v2/lists/#{ @address }/members/#{ email }")
    mailgun_uri.auth = config.mailgunAPI
    request(
      url: mailgun_uri
      method: 'GET'
      (error, response, body) ->
        if _.isFunction callback
          callback null, body, response.statusCode
    )

  changeEmail: (oldEmail, newEmail, callback) ->
    console.log "Changed #{ oldEmail } to #{ newEmail }"
    @subscribe(newEmail)
    @unsubscribe(oldEmail)

  inList: (email, callback) ->
    @personInfo(email, (err, response, statusCode) ->
      unless _.isFunction callback then return
      if err then callback(err)
      else if statusCode is 200 then callback null, true
      else if statusCode is 404 then callback null, false
    )

  sendEmail: (from, subject, body, message_id, in_reply_to = null, references = null, attachments = null) ->
    subject = @subject + " " + subject
    sendEmail(@address, from, subject, body, message_id, in_reply_to, references, attachments)
