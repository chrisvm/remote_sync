parsers = require('../parsing/parsers')
validation = require('../config/validation')
recv_readdir = require('recursive-readdir')
path = require 'path'


class SyncDef
    constructor: (options) ->
        @options = options
        @name = options.name
        @input_files = []
        delete(options.name)
        this.parse()

    parse: () ->
        missing = validation.hasRequired(@options, ['src', 'dest'])
        if missing.length > 0
            throw "Error: #{@name}: missing required fields #{missing}"
        this.src = this.parse_field(@options.src)
        this.dest = this.parse_field(@options.dest)

        # set ignore function
        if @options.ignore? && @options.ignore.length > 0
            # for each ignore param, create an ignore function
            ign_funcs = []
            for to_ignore in @options.ignore
                to_ignore = path.parse(to_ignore)
                ign_funcs.push (file, stats) ->
                    parsed = path.parse file
                    if parsed.base is to_ignore.base
                        return true
                    return false
            # the real ignore function iterates through all ignore funcs
            @ignore_func = (file, stats) ->
                for f in ign_funcs
                    if f file, stats is true
                        return true
                return false
        else
            @ignore_func = (file, stats) -> return false

    parse_field: (field) ->
        parsed = parsers.RemoteLocation.parse(field)
        parsed?.remote = true
        if not parsed?
            parsed = parsers.Path.parse(field)
            parsed.remote = false
        return parsed

    resolve_input: (callback) ->
        if @src.remote
            @src.path = parsers.Path.parse(@src.path)
            console.log(@src)
        else
            # check if single file or dir
            try
                single_file = not validation.path_to_dir(@src)
            catch error
                err_msg = "Error: Error opening file #{@src.path}"
                console.log(err_msg.red)
                return

            if single_file
                @input_files.push(validation.expand_path(@src.path))
                callback()
            else
                expanded_path = validation.expand_path(@src.path)
                recv_readdir expanded_path, [@ignore_func], (err, files) ->
                    if err?
                        throw err
                    @input_files = files
                    callback()
    run: () ->
        this.resolve_input () ->
            console.log(this.input_files)
module.exports = SyncDef
