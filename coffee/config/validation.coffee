path = require('path')

Validation =
    requiredFields: [
        'input_dir'
        'output_dir'
    ]
    
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

     hasRequired: (conf) ->
        keys = Object.keys(conf)
        if keys.length <= 0
            return false

        for field in Validation.requiredFields
            if field not in keys
                return false
        return true

Module.exports = Validation
