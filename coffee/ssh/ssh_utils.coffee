ssh2 = require 'ssh2'
fs = require 'fs'


class SSHUtils
    constructor: (options) ->
        @options = options
        @user = options.user
        @path = options.path
        @normalize_path()

    normalize_path: () ->
        if @path.path.indexOf('~') > -1
            conn = new ssh2.Client()
            conn.on 'ready', () ->
                conn.exec 'cd;pwd', (err, stream) ->
                    if err? throw err
                    stream.on 'close', (code, signal) ->
                        conn.end()
                    stream.in 'data', (data) ->
                        console.log data
            connect_settings =
                host: @options.host.host
                port: 22
                username: @user.user
                privateKey: fs.readFileSync('~/.ssh/id_rsa')
            conn.connect connect_settings
module.exports = SSHUtils
