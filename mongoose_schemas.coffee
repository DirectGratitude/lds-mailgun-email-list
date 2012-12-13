mongoose = require 'mongoose'
config = require './config'

if process.env.NODE_ENV is 'production'
  mongoose.connect(config.dotcloud_mongo)
else
  mongoose.connect('mongodb://localhost/stanford2lists')

# Setup MongoDB schemas.
Schema = mongoose.Schema

PersonSchema = new Schema (
  name: { type: String, required: true }
  address: { type: String }
  phone: { type: String }
  email: { type: String }
  sex: { type: String }
  created: { type: Date, default: Date.now }
  changed: { type: Date, default: Date.now }
  mailchimpSynced: Date
  inWard: Boolean
)

Person = mongoose.model 'Person', PersonSchema
