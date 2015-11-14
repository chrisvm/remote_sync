path = require('path')

Validation =
    arrayOfStrings: (mixed) ->
        if Array.isArray(mixed) and mixed.length != 0
            for item in mixed
                if typeof item != 'string'
                    return false
            return true
        return false

    arrayOfStringsOrString: (mixed) ->
        if Validation.arrayOfStrings mixed
            return true
        else
            if typeof mixed == 'string'
                return true
        return false

     hasRequired: (conf, requiredFields) ->
        keys = Object.keys(conf)
        if keys.length <= 0
            return false

        for field in requiredFields
            if field not in keys
                return false
        return true

module.exports = Validation
