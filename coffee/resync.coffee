validate = require './config/validation'
config = require './config/config'
cli = require './config/cli'
path = require 'path'
colors = require 'colors'


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
        err_msg = "Error: Config file not found in '" + cwd + "'"
        console.log(err_msg.red)
        return

    required_fields = ['sync']
    not_found = validate.hasRequired(opts, required_fields)
    if not_found.length > 0
        for missing in not_found
            err_msg = "Error: Config missing required field '" + missing + "'"
            console.log(err_msg.red)
        return

main()
