ssh2 = require 'ssh2'
fs = require 'fs'
path = require 'path'
validation = require '../config/validation'


class SSHUtils
    constructor: (options) ->
        @dest = options
        @host = options.host
        @user = options.user
        @path = options.path
        @connect_settings = SSHUtils.settings(@options)

    @settings: (options) ->
        ret =
            host: options.host.host
            port: 22
            username: options.user.user
            privateKey: fs.readFileSync validation.expand_path '~/.ssh/id_rsa'
        return ret

    @transfer_dir: (conn, remotePath, localPath, compression, callback) ->
        cmd = "tar cf - \"#{remotePath}\" 2>/dev/null"
        if typeof compression is 'function'
            callback = compression
        else if compression is true
            compression = 6

        if typeof compression is 'number' and compression >= 1 && compression <= 9
            cmd += ' | gzip -' + compression + 'c 2>/dev/null';
        else
            compression = undefined

        conn.exec cmd, (err, stream) ->
            if err?
                return callback(err)

            tarStream = tar.extract localPath
            tarStream.on 'finish', () ->
                callback exitErr

            stream.on 'exit', (code, signal) ->
                if typeof code is 'number' and code isnt 0
                    exitErr = new Error "Remote process exited with code #{code}"
                else if signal?
                    exitErr = new Error "Remote process killed with signal #{signal}"
            .stderr.resume()

            if compression?
                stream = stream.pipe zlib.createGunzip()

            stream.pipe tarStream

    process: (def, finish) ->
        _this = this
        conn = new ssh2.Client()
        conn.on 'ready', () ->
            conn.exec "echo #{_this.path.path}", (err, stream) ->
                throw err if err?
                stream.on 'data', (data) ->
                    abs_path = data.toString().slice(0, -1)
                    conn.sftp (err, sftp) ->
                        throw err if err?
                        sftp.stat abs_path, (err, stats) ->
                            next = (sts) ->
                                if not sts.isDirectory()
                                    if def.input_files.files.length > 1
                                        err_msg = "Error: more input files than possible in dest"
                                        console.log(err_msg.red)
                                        conn.end()
                                        return
                                def.output_dest =
                                    remote: true
                                    is_dir: sts.isDirectory()
                                    dest: abs_path
                                finish(conn, sftp)
                            if err?
                                sftp.mkdir abs_path, (err) ->
                                    throw err if err?
                                    sftp.stat abs_path, (err, s) ->
                                        next(s)
                            else
                                next(stats)
        conn.connect @connect_settings

module.exports = SSHUtils
