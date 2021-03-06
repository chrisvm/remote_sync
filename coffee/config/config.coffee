path = require('path')
fs = require('fs')
YAML = require('yamljs')
validation = require './validation'


Config =
    read_json_or_yaml: (dir, config_file) ->
        # get the contents of dir
        contents = fs.readdirSync(dir)

        # create alternante filenames
        yaml_file = config_file + '.yml'
        json_file = config_file + '.json'

        if yaml_file in contents
            abs_path = path.join(dir, yaml_file)
            config_content = fs.readFileSync(abs_path, 'utf8')
            config_content = YAML.parse(config_content)
        else if json_file in contents
            config_content = require(path.join(dir, json_file))
        else
            return null
        return config_content

    get_array: (opt) ->
        if validation.arrayOfStringsOrString(opt)
            if not validation.arrayOfStrings(opt)
                return [opt]
            return opt

    get_config: (opts) ->
        # get config
        if opts.parent.dir?
            cwd = path.resolve(opts.parent.dir)
        else
            cwd = process.cwd()

        cnf = Config.read_json_or_yaml(cwd, 'resync')
        cnf?.verbose = opts.parent.verbose
        cnf?.cwd = cwd
        if not cnf?
            err_msg = "Error: Config file not found in '#{cwd}'"
            console.log(err_msg.red)
            process.exit()
        return cnf
        
module.exports = Config
