_ = require 'underscore'
config = require './config'
url = require 'url'
request = require 'request'
querystring = require 'querystring'
nodemailer = require 'nodemailer'

module.exports = class Mailchimp

  apiKey: config.mailgunApiKey

  constructor: (@address) ->
    console.log 'new list address ' + @address

  subscribe: (emails, callback) ->
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
          console.log response.statusCode
          console.log body
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
      console.log emails

  unsubscribe: (email, callback) ->
    mailgun_uri = url.parse("https://api.mailgun.net/v2/lists/#{ @address }/members/#{ email }")
    mailgun_uri.auth = config.mailgunAPI
    request(
      url: mailgun_uri
      method: 'DELETE'
      (error, response, body) ->
        console.log response.statusCode
        console.log body
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
        console.log response.statusCode
        console.log body
        if _.isFunction callback
          callback null, body, response.statusCode
    )

  changeEmail: (oldEmail, newEmail, callback) ->
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
    console.log 'inside sendEmail for', @address

    unless message_id? then return false

    email =
        from: from
        to: @address
        subject: subject
        html: body
        messageId: message_id
        headers: {}

    if in_reply_to?
      email.headers['In-Reply-To'] = in_reply_to
    if references?
      email.headers['References'] = references

    # Add a custom header, X-Been-There, to prevent resending the same email.
    email.headers['X-Been-There'] = 'true'


    smtpTransport = nodemailer.createTransport("SMTP",
      service: "Mailgun", # sets automatically host, port and connection security settings
      auth:
        user: config.mailgun_smtp_user
        pass: config.mailgun_smtp_pass
    )

    smtpTransport.sendMail email, (err, res) ->
      if err then console.log(err)
      console.log 'done', res
