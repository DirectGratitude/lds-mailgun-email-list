request = require 'request'
csv = require 'csv'
mongoose = require('mongoose')
require './mongoose_schemas'
config = require './config'

exports.download = (spreadsheetUrl, callback) ->
  # Request google.com first to get a Google cookie.
  request('http://google.com', (err, response, body) ->
    request(spreadsheetUrl, (err, response, body) ->
      if err
        callback err
      else
        csvArray = []
        csv()
          .from(body, { columns: true })
          .transform( (data, index) ->
            csvArray.push data
          )
          .on('end', ->
            callback null, csvArray
          )
          .on('error', (err) ->
            callback err
          )
    )
  )

# White list
fetchWhiteBlackLists = ->
  WhiteBlackList = mongoose.model 'whiteblacklist'

  # Remove everything in this collection in MongoDB.
  WhiteBlackList.remove (err) ->
    unless err
      exports.download(config.whitelist, (err, data) ->
        console.log data
        for datum in data
          if datum.Email?
            model = new WhiteBlackList( { email: datum.Email, type: 'white' } )
            model.save()
      )
      exports.download(config.blacklist, (err, data) ->
        console.log data
        for datum in data
          if datum.Email?
            model = new WhiteBlackList( { email: datum.Email, type: 'black' } )
            model.save()
      )

fetchSendingWhitelist = ->
  exports.download(config.sendingWhitelist, (err, data) ->
    exports.sendingWhitelist = data
  )

fetchWhiteBlackLists()
fetchSendingWhitelist()
