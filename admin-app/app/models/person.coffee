module.exports = class Person extends Backbone.Model

  defaults:
    sex: null
    email: null
    address: null
    name: null

  # Validate that the sex is set correctly.
  # Coffee-script always returns something so we need to explicitly
  # return null so the validation doesn't fail.
  validate: (attrs) ->
    unless _.isNull attrs.sex
      unless _.include ['m', 'M', 'F', 'f'], attrs.sex
        return "Sex must be set as either 'm' or 'f'"
      else
        @trigger 'noerror'
        return null
    else
      return null
