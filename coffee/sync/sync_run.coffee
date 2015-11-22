SyncDef = require './sync_def'


class SyncRun
    constructor: (conf) ->
        @config = conf
        @verbose = conf.verbose

    get_def: (def_name) ->
        options = @config[def_name]
        if not options?
            return null
        options.name = def_name
        options.cwd = @config.cwd
        return new SyncDef(options)


    run: (cnf_name) ->
        sync_defs = if cnf_name? then [cnf_name] else @config.sync
        for sync_def in sync_defs
            if @verbose
                console.log("Starting sync '#{sync_def}'".yellow)
                console.log("...Looking for def '#{sync_def}''".yellow)
            try
                def = @get_def(sync_def)
                if not def?
                    err_msg = "Error: sync definition '#{sync_def}' not found in config"
                    console.log(err_msg.red)
                    return
                else if @verbose
                    console.log("...Found def '#{sync_def}'".yellow)
                    console.log("...Executing '#{sync_def}'".yellow)
                def.verbose = @verbose
                def.run()
            catch error
                console.log(error.toString().red)

module.exports = SyncRun
