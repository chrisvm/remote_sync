validate = require './config/validation'
config = require './config/config'
cli = require './config/cli'
path = require 'path'
colors = require 'colors'
SyncRun = require './sync/sync_run'


main = () ->

    # get opts
    opts = cli.opts_parse()

    # get config
    if opts.dir?
        cwd = path.resolve(opts.dir)
    else
        cwd = process.cwd()

    cnf = config.read_json_or_yaml(cwd, 'resync')
    if not cnf?
        err_msg = "Error: Config file not found in '#{cwd}'"
        console.log(err_msg.red)
        return

    # check config has required fields
    required_fields = ['sync']
    not_found = validate.hasRequired(cnf, required_fields)
    if not_found.length > 0
        for missing in not_found
            err_msg = "Error: Config missing required field '#{missing}'"
            console.log(err_msg.red)
        return

    # check for correct sync opt
    cnf.sync = config.get_array(cnf.sync)
    cnf.verbose = opts.verbose
    if not cnf.sync?
        err_msg = "Error: sync parameters not a string or array of strings"
        return

    # for all sync config, run them sequentually
    sync_run = new SyncRun(cnf)
    sync_run.run()

main()
