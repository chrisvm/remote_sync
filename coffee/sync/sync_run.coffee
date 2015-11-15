SyncDef = require './sync_def'


class SyncRun
    constructor: (conf) ->
        @config = conf
        @verbose = conf.verbose

    run: () ->
        for sync_def in @config.sync
            if @verbose
                console.log("Starting sync '#{sync_def}'".yellow)
                console.log("Looking for def '#{def_name}''".yellow)

            def = @get_def(sync_def)
            if not def?
                console.log("Error: sync definition '#{sync_def}' not found")
                return
            else if @verbose
                console.log("Found def '#{sync_def}'".yellow)
                console.log("Executing '#{sync_def}'".yellow)
            def.run()

    get_def: (def_name) ->
        if not def_name of @config
            return null
        else
            return new SyncDef(@config[def_name])

module.exports = SyncRun
