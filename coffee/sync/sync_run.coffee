SyncDef = require './sync_def'
_ = require 'underscore'

class SyncRun
    constructor: (conf) ->
        @config = conf
        @verbose = conf.verbose
        @running = {}
        @on_end = []

    get_def: (def_name) ->
        options = @config[def_name]
        if not options?
            return null
        options.name = def_name
        options.cwd = @config.cwd
        return new SyncDef(options)

    end: (callback) ->
        @on_end.push callback

    check_end: () ->
        _this = this
        t = (r) -> r
        if _.every _.keys(_this.running), t
            _.each _this.on_end, (cb) ->
                cb()

    run: (cnf_name) ->
        sync_defs = if cnf_name? then [cnf_name] else @config.sync
        _this = this
        _.each sync_defs, (sd) ->
            _this.running[sd] = true

        _run = (index) ->
            sync_def = sync_defs[index]
            if _this.verbose
                console.log("Starting sync '#{sync_def}'".yellow)
                console.log("...Looking for def '#{sync_def}''".yellow)
            try
                def = _this.get_def(sync_def)
                if not def?
                    err_msg = "Error: sync definition '#{sync_def}' not found in config"
                    console.log(err_msg.red)
                    return
                else if @verbose
                    console.log("...Found def '#{sync_def}'".yellow)
                    console.log("...Executing '#{sync_def}'".yellow)
                def.verbose = _this.verbose
                _this.running[sync_def] = true
                def.run () ->
                    _this.running[sync_def] = false
                    index += 1
                    if index < sync_defs.length
                        _run(index)
                    else
                        _this.check_end()
            catch error
                console.log(error.toString().red)
        _run(0)

module.exports = SyncRun
