Mailgun = require './mailgun'
everyoneList = new Mailgun(config.everyoneList)
eqList = new Mailgun(config.eqList)
rsList = new Mailgun(config.rsList)

module.exports = (req, res) ->
  console.log req.body
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
      when 'X-Been-Here' then repeat = true

  # If the x-been-there header is set, this is it's second time through.
  if repeat
    return res.json 'ok'

  # TODO account for attachments
  # TODO check against email white list if the sender has permission.
  switch req.body['To']
    when "eq@stanford2.mailgun.org" then eqList.sendEmail(req.body.From, req.body.Subject, req.body['body-html'], message_id, in_reply_to, references)
    when "everyone@stanford2.mailgun.org" then eqList.sendEmail(req.body.from, req.body.subject, req.body['body-html'], message_id, in_reply_to, references)
    when "rs@stanford2.mailgun.org" then eqList.sendEmail(req.body.from, req.body.subject, req.body['body-html'], message_id, in_reply_to, references)

  # Tell Mailgun we received things ok.
  res.json 'ok'
