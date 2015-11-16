parsers = require('../parsing/parsers')
validation = require('../config/validation')
recv_readdir = require('recursive-readdir')
path = require 'path'
SSHUtils = require('../ssh/ssh_utils')


class SyncDef
    constructor: (options) ->
        @options = options
        @name = options.name
        @input_files = null
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
            for to_ignore, i in @options.ignore
                ign_funcs.push @create_ign_function(to_ignore)
            # the real ignore function iterates through all ignore funcs
            @ignore_func = (file, stats) ->
                for f in ign_funcs
                    if f.func(file, stats) is true
                        return true
                return false
        else
            @ignore_func = (file, stats) -> return false

    create_ign_function: (ignore_rule) ->
        t =
            source: ignore_rule
            func: (file, stats) ->
                if path.parse(file).base is path.parse(t.source).base
                    return true
                return false
        return t

    parse_field: (field) ->
        parsed = parsers.RemoteLocation.parse(field)
        if not parsed?
            parsed = parsers.Path.parse(field)
            parsed.remote = false
        else
            parsed.remote = true
            parsed_path = path.parse parsed.path.path
            parsed_path.path = parsed.path.path
            parsed.path = parsed_path
        return parsed

    # resolve input files from remote or
    resolve_input: (callback) ->
        if @src.remote
            # TODO: implement remote file listing
            # get remote input files
            @input_files.src_type = 'remote'
            console.log(@src)
        else
            # get local input files
            # check if single file or dir
            try
                single_file = not validation.path_to_dir(@src)
            catch error
                err_msg = "Error: Error opening file or dir #{@src.path}"
                console.log(err_msg.red)
                return

            # if single file
            @input_files =
                src_type: 'local'
                is_dir: false
                src_dir: expanded_path
                files: []
            expanded_path = validation.expand_path(@src.path)
            if single_file
                # add single file
                parsed = path.parse(expanded_path)
                @input_files.src_dir = parsed.dir
                @input_files.files.push(parsed.base)
                callback()
            else
                # get all files in input dir
                _this = this
                _this.input_files.is_dir = true
                _this.input_files.src_dir = expanded_path
                recv_readdir expanded_path, [@ignore_func], (err, files) ->
                    if err?
                        throw err
                    for file in files
                        _this.input_files.files.push path.relative expanded_path, file
                    callback()

    resolve_output: (callback) ->
        if @dest.remote
            # resolve remote dest
            ssh_u = new SSHUtils(@dest)
            
        callback()
    # run the sync job, sending files concurrently
    run: () ->
        # first resolve input files
        _this = this
        _this.resolve_input () ->
            _this.resolve_output () ->
                console.log _this


module.exports = SyncDef
