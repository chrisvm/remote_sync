chokidar = require 'chokidar'
validation = require '../config/validation'


watch = (sync_run) ->
    # Initialize watcher.
    watcher = chokidar.watch 'file, dir',
        ignored: /[\/\\]\./
        persistent: true

    # set events
    watcher
        .on 'change', (path) ->
            console.log "File #{path} changed"

    # watch files
    def = sync_run.config.sync[0]
    def = sync_run.get_def def
    if def.src.remote
        err_msg = "Error: only local files can be watched"
        console.log err_msg.red
        process.exit()
    else
        input_dir = validation.expand_path def.src.path
        if sync_run.config.verbose
            console.log "...Watching #{input_dir}"
        watcher.add input_dir
        console.log def

module.exports = watch
