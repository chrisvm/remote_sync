validate = require './config/validation'
config = require './config/config'
program = require 'commander'
path = require 'path'
colors = require 'colors'
SyncRun = require './sync/sync_run'


main = () ->
    # run program
    program
        .version('0.0.1')
        .usage('[options] <command>')
        .option('-v, --verbose', 'if to output verbose error messages')
        .option('-d, --dir [conf_dir]', 'the location of the config file')

    program
        .command('sync [config_name]')
        .description('sync all configs, or a single config [config_name]')
        .action (cnf_name, opts) ->
            # get config
            if opts.parent.dir?
                cwd = path.resolve(opts.parent.dir)
            else
                cwd = process.cwd()

            cnf = config.read_json_or_yaml(cwd, 'resync')
            cnf?.verbose = opts.parent.verbose
            cnf?.cwd = cwd
            if not cnf?
                err_msg = "Error: Config file not found in '#{cwd}'"
                console.log(err_msg.red)
                return

            # if given def_name, dont look for sync field in config
            if cnf_name?
                sync_run = new SyncRun(cnf)
                sync_run.run(cnf_name)
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
            if not cnf.sync?
                err_msg = "Error: sync parameters not a string or array of strings"
                return

            # for all sync config, run them sequentually
            sync_run = new SyncRun(cnf)
            sync_run.run()

    program.parse(process.argv)
    if program.args.length is 0
        program.help()
main()
