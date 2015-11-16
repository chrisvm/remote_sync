path = require('path')
expandHomeDir = require('expand-home-dir')
fs = require('fs')


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

        not_found = []
        for field in requiredFields
            if field not in keys
                not_found.push(field)
        return not_found

    path_to_dir: (parsed_path) ->
        string_path = Validation.expand_path path.format parsed_path
        return fs.statSync(string_path).isDirectory()

    expand_path: (string_path) ->
        if string_path.indexOf('~') > -1
            string_path = expandHomeDir(string_path)
        return string_path


module.exports = Validation
