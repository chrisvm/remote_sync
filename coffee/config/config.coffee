path = require('path')
fs = require('fs')
YAML = require('yamljs')

Config =
    read: (dir, config_file='resync') ->
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
