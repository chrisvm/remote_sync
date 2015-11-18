parsers = require('../parsing/parsers')
validation = require('../config/validation')
recv_readdir = require('recursive-readdir')
path = require 'path'
fs = require 'fs'
ssh2 = require 'ssh2'
SSHUtils = require('../ssh/ssh_utils')
explode = require '../ssh/explode'


class SyncDef
    constructor: (options) ->
        @options = options
        @name = options.name
        @input_files = null
        @verbose = false
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
            _this = this
            settings = SSHUtils.settings(@src)
            conn = new ssh2.Client()
            conn.on 'ready', () ->
                next = () ->
                    _this.input_files =
                        remote: true
                        files: []
                        is_dir: false
                        src_dir: _this.src.path.path

                    conn.sftp (err, sftp) ->
                        throw err if err?
                        sftp.stat _this.src.path.path, (err, stats) ->
                            if err?
                                err_msg = "Error: error opening remote file or dir #{_this.src.path.path}"
                                console.log err_msg.red
                                process.exit 1

                            if stats.isDirectory()
                                _this.input_files.is_dir = true
                                # get all files
                                cmd = "find \"#{_this.src.path.path}\" -type f"
                                next = (all) ->
                                    _this.input_files.files = all
                                    callback()

                                conn.exec cmd, (err, stream) ->
                                    throw err if err?
                                    stream.on 'end', () -> conn.end()
                                    stream.pipe explode '\n', next
                            else
                                _this.input_files.files.push _this.input_files.src_dir

                path_string = _this.src.path.path
                if path_string.indexOf('~') > -1
                    conn.exec "echo #{path_string};", (err, stream) ->
                        throw err if err?
                        stream.on 'data', (data) ->
                            abs_path = data.toString().slice(0, -1)
                            ret = path.parse(abs_path)
                            ret.path = abs_path
                            _this.src.path = ret
                            next()
                else
                    next()
            conn.connect settings
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
            expanded_path = validation.expand_path(@src.path)
            @input_files =
                remote: false
                is_dir: false
                src_dir: expanded_path
                files: []
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
            console.log this.input_files.files

    verify_dir: (dir_path, sftp, callback) ->
        if @verbose
            console.log "...Verifying '#{dir_path}'"
        sftp.stat dir_path, (err, stats) ->
            if err? or not stats.isDirectory()
                sftp.mkdir dir_path, (err) ->
                    if err?
                        err_msg = "ERROR: error making dir '#{dir_path}'"
                        console.log(err_msg.red)
                        process.exit(1)
                    callback()
            else
                callback()

    # run the sync job, sending files concurrently
    run: () ->
        # first resolve input files
        _this = this
        _this.resolve_input () ->
            _this.resolve_output (conn, sftp) ->
                count = _this.input_files.files.length
                if _this.input_files.remote
                    # TODO: implement when input files are remote

                else

                    if not _this.verbose
                        console.log "...Sending #{count} file(s) in sync '#{_this.name}'"
                    if _this.output_dest.remote
                        _this.input_files.files.forEach (input_file) ->
                            input = path.join _this.input_files.src_dir, input_file
                            if _this.output_dest.is_dir
                                output = path.join _this.output_dest.dest, input_file
                            else
                                output = _this.output_dest.dest
                            if _this.verbose
                                console.log "...Sending '#{input}' -> '#{output}'"
                            _this.verify_dir path.parse(output).dir, sftp, () ->
                                sftp.fastPut input, output, (err) ->
                                    if err?
                                        throw err
                                        conn.end()
                                    else
                                        if _this.verbose
                                            console.log "...Sent '#{output}'"
                                        count -= 1
                                        if count is 0
                                            conn.end()
                    else
                        # TODO: implement when dest is local

module.exports = SyncDef
