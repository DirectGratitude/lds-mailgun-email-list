config = require './config'
nodemailer = require 'nodemailer'

module.exports = (to, from, subject, body, message_id, in_reply_to = null, references = null, attachments = null) ->
  console.log 'inside sendEmail'

  unless message_id? then return false

  email =
      from: from
      to: to
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
  console.log email

  if attachments?
    email.attachments = []
    for attachment in attachments
      emailAttachment = { fileName: attachment.name, filePath: attachment.path, contentType: attachment.type }
      # Add cid if set for inline images.
      if attachment.cid?
        emailAttachment.cid = attachment.cid
      email.attachments.push emailAttachment

  smtpTransport = nodemailer.createTransport("SMTP",
    service: "Mailgun", # sets automatically host, port and connection security settings
    auth:
      user: config.mailgun_smtp_user
      pass: config.mailgun_smtp_pass
  )

  smtpTransport.sendMail email, (err, res) ->
    if err then console.log(err)
    console.log 'done', res
