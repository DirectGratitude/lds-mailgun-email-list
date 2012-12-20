request = require 'request'
csv = require 'csv'
mongoose = require('mongoose')
require './mongoose_schemas'
cronJob = require('cron').CronJob
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
exports.fetchBlacklist = fetchWhiteBlackLists = ->
  exports.download(config.blacklist, (err, data) ->
    exports.blacklist = data
  )

exports.fetchWhitelist = fetchSendingWhitelist = ->
  exports.download(config.sendingWhitelist, (err, data) ->
    exports.sendingWhitelist = data
  )

fetchWhiteBlackListsJob = new cronJob('* * * * * */1', (-> fetchWhiteBlackLists()), true)
fetchSendingWhiteListJob = new cronJob('* * * * * */1', (-> fetchSendingWhiteListJob()), true)

# Run immediately on startup.
fetchWhiteBlackLists()
fetchSendingWhitelist()
