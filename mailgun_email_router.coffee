Mailgun = require './mailgun'
config = require './config'
everyoneList = new Mailgun(config.everyoneList)
eqList = new Mailgun(config.eqList)
rsList = new Mailgun(config.rsList)
spreadsheets = require './google_spreadsheet'
_ = require 'underscore'
sendEmail = require './send_email'
mimelib = require 'mimelib'

checkSenderPermission = (list, from) ->
  # Map list email to column name on sending whitelist.
  switch list
    when "eq@stanford2.mailgun.org" then list = "eq_list"
    when "everyone@stanford2.mailgun.org" then list = "everyone"
    when "rs@stanford2.mailgun.org" then list = "rs_list"

  # Get actual email.
  from = mimelib.parseAddresses(from)[0]

  # Check the sending email is both on the list and that they have permission.
  result = _.find spreadsheets.sendingWhitelist, (sender) -> sender.email is from.address and sender[list] is "1"
  if result? then return true else return false

module.exports = (req, res) ->
  try
    headers = JSON.parse req.body['message-headers']
  catch error
    console.log error
  message_id = ""
  references = ""
  in_reply_to = ""
  subject = ""
  for header in headers
    switch header[0]
      when 'Message-Id' then message_id = header[1]
      when 'In-Reply-To' then in_reply_to = header[1]
      when 'References' then references = header[1]
      when 'Subject' then subject = header[1]
      when 'X-Been-There' then repeat = true

  # If the x-been-there header is set, this is it's second time through.
  if repeat
    return res.json 'ok'

  attachments = []
  for name, attachment of req.files
    for cid, attachment_name of JSON.parse(req.body['content-id-map'])
      if attachment_name is name
        attachment['cid'] = cid.slice(1, -1)
    attachments.push attachment

  # Check against email sending white list if the sender has permission to post
  # this list.
  unless checkSenderPermission(req.body.To, req.body.From)
    console.log 'Sender rejected:', req.body.From
    sendEmail(req.body.From, config.email_admin, 'Re: ' + req.body.Subject, "Your email wasn't sent as you don't have permission to send emails to this list. If you believe you should be able to send emails to this list, reply to this email and ask me [the current ward email admin] to give you permission.<br>--------------------<br><br>" + req.body['body-html'], '', message_id)
    return res.json 'ok'


  switch req.body['To']
    when "eq@stanford2.mailgun.org" then eqList.sendEmail(req.body.From, req.body.Subject, req.body['body-html'], message_id, in_reply_to, references, attachments)
    when "everyone@stanford2.mailgun.org" then eqList.sendEmail(req.body.from, req.body.subject, req.body['body-html'], message_id, in_reply_to, references, attachments)
    when "rs@stanford2.mailgun.org" then eqList.sendEmail(req.body.from, req.body.subject, req.body['body-html'], message_id, in_reply_to, references, attachments)

  # Tell Mailgun we received things ok.
  res.json 'ok'
