parsers = require('../parsing/parsers')
validation = require('../config/validation')
recv_readdir = require('recursive-readdir')
path = require 'path'
fs = require 'fs'
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
            # TODO: implement resolve remote input
            # get remote input files
            @input_files.remote = true
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
                remote: false
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
            ssh_u.process(this, callback)
        else
            # TODO: implement resolve local output dest

    # run the sync job, sending files concurrently
    run: () ->
        # first resolve input files
        _this = this
        _this.resolve_input () ->
            _this.resolve_output (conn, sftp) ->
                if _this.input_files.remote
                    # TODO: implement when input files are remote
                else
                    count = _this.input_files.files.length
                    if _this.output_dest.remote
                        _this.input_files.files.forEach (input_file) ->
                            input = path.join _this.input_files.src_dir, input_file
                            if _this.output_dest.is_dir
                                output = path.join _this.output_dest.dest, input_file
                            else
                                output = _this.output_dest.dest
                            console.log "...Sending '#{input}' -> '#{output}'"
                            sftp.fastPut input, output, (err) ->
                                throw err;conn.end() if err?
                                console.log "...Sent '#{output}'"

                    else
                        # TODO: implement when dest is local
module.exports = SyncDef
