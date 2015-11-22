parsers = require('../parsing/parsers')
validation = require('../config/validation')
recv_readdir = require('recursive-readdir')
path = require 'path'
fs = require 'fs'
ssh2 = require 'ssh2'
_ = require 'underscore'
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
                                finish = (all) ->
                                    _this.input_files.files = all
                                    callback()

                                conn.exec cmd, (err, stream) ->
                                    throw err if err?
                                    stream.on 'end', () ->
                                        sftp.end()
                                        conn.end()
                                    stream.pipe explode '\n', finish
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
            _this = this
            expanded_path = validation.expand_path(_this.src.path)
            _this.input_files =
                remote: false
                is_dir: false
                src_dir: expanded_path
                files: []
            fs.stat expanded_path, (err, stats) ->
                if err?
                    err_msg = "Error: Error opening file or dir #{expanded_path}"
                    console.log err_msg.red
                    process.exit()
                else
                    if stats.isDirectory()
                        # get all files in input dir
                        _this.input_files.is_dir = true
                        _this.input_files.src_dir = expanded_path
                        recv_readdir expanded_path, [_this.ignore_func], (err, files) ->
                            if err?
                                throw err
                            for file in files
                                _this.input_files.files.push path.relative expanded_path, file
                            callback()
                    else
                        # add single file
                        parsed = path.parse(expanded_path)
                        _this.input_files.src_dir = parsed.dir
                        _this.input_files.files.push(parsed.base)
                        callback()

    resolve_output: (callback) ->
        if @dest.remote
            # resolve remote dest
            ssh_u = new SSHUtils(@dest)
            ssh_u.process(this, callback)
        else
            # check if output dir exists
            _this = this
            out_path = validation.expand_path(_this.dest.path)
            validation.check_dir out_path, _this.verbose, () ->
                _this.output_dest =
                    remote: false,
                    is_dir: true,
                    dest: out_path
                callback()

    # run the sync job, sending files concurrently
    run: () ->
        # first resolve input files
        _this = this
        _this.resolve_input () ->
            _this.resolve_output (outconn, outsftp) ->
                count = _this.input_files.files.length
                # if input files are comming from remote location
                if _this.input_files.remote
                    inconn = new ssh2.Client()
                    insettings = SSHUtils.settings(_this.src)

                    # if output is a local destination
                    if not _this.output_dest.remote
                        host = _this.src.host.host
                        msg = "...Getting #{count} files from #{host}"
                        console.log msg.yellow

                        input_dir = _this.input_files.src_dir
                        output_dir = _this.output_dest.dest
                        f = (file) ->
                            rel = path.relative(input_dir, file)
                            return [file, path.join(output_dir, rel), rel]

                        inconn.on 'ready', () ->
                            inconn.sftp (err, insftp) ->
                                download_file = (inf, outf) ->
                                    rel_dir = path.parse(outf).dir
                                    validation.check_dir rel_dir, _this.verbose, () ->
                                        insftp.fastGet inf, outf, (err) ->
                                            if err?
                                                err_msg = err.toString()
                                                console.log err_msg.red
                                            else if _this.verbose
                                                console.log "...#{inf} -> #{outf}".yellow
                                            count -= 1
                                            if count is 0
                                                inconn.end()
                                if err?
                                    throw err
                                input_files = _.map _this.input_files.files, f
                                for file in input_files
                                    [input_file, output_file, relative] = file
                                    download_file input_file, output_file
                        inconn.connect insettings
                    else
                        # process the input files
                        input_dir = _this.input_files.src_dir
                        output_dir = _this.output_dest.dest
                        f = (file) ->
                            rel = path.relative(input_dir, file)
                            return [file, path.join(output_dir, rel), rel]
                        input_files = _.map _this.input_files.files, f

                        console.log "...Transfering #{input_files.length} files".yellow

                        inconn.on 'ready', () ->
                            inconn.sftp (err, insftp) ->
                                if err?
                                    throw err
                                insftp.on 'error', (err) ->
                                    if count is 0
                                        process.exit()
                                    else
                                        throw err
                                # create function for sending files
                                open_stream = (inf, outf) ->
                                    SSHUtils.check_dir outconn, outsftp, path.parse(outf).dir, _this.verbose, () ->
                                        instream = insftp.createReadStream inf
                                        outstream = outsftp.createWriteStream outf
                                        outstream.on 'finish', () ->
                                            count -= 1
                                            if _this.verbose
                                                msg = "...#{inf} -> #{outf}"
                                                console.log msg.yellow
                                            if count is 0
                                                f = () ->
                                                    inconn.end()
                                                    outconn.end()
                                                setTimeout f, 500
                                        instream.pipe outstream

                                for file in input_files
                                    [input_file, output_file, relative] = file
                                    open_stream(input_file, output_file)
                        inconn.connect insettings
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
                            SSHUtils.check_dir outconn, outsftp, path.parse(output).dir, _this.verbose, () ->
                                outsftp.fastPut input, output, (err) ->
                                    if err?
                                        throw err
                                        outconn.end()
                                    else
                                        if _this.verbose
                                            console.log "...Sent '#{output}'"
                                        count -= 1
                                        if count is 0
                                            outconn.end()
                    else
                        console.log "...Copying #{count} files"
                        # filter input files
                        input_dir = _this.input_files.src_dir
                        output_dir = _this.output_dest.dest
                        f = (file) ->
                            return [path.join(input_dir, file), path.join(output_dir, file), file]
                        input_files = _.map _this.input_files.files, f

                        # copy file abstraction
                        copy_files = (input_file, output_file, verbose) ->
                            validation.check_dir path.parse(output_file).dir, verbose, () ->
                                instream = fs.createReadStream input_file
                                outstream = fs.createWriteStream output_file
                                outstream.on 'finish', () ->
                                    count -= 1
                                    if verbose
                                        console.log "...#{input_file} -> #{output_file}".yellow
                                instream.pipe outstream

                        for file in input_files
                            [input_file, output_file, relative] = file
                            copy_files input_file, output_file, _this.verbose
module.exports = SyncDef
