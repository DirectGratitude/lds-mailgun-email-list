mongoose = require('mongoose')
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

WhiteBlackListSchema = new Schema (
  email: { type: String, required: true }
  type: { type: String, required: true }
)

Person = mongoose.model 'Person', PersonSchema
WhiteBlackList = mongoose.model 'whiteblacklist', WhiteBlackListSchema
