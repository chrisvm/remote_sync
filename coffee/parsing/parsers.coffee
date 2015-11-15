jison = require 'jison'
fs = require 'fs'
path = require 'path'

get_parsers = (dir) ->
    ret = {}
    contents = fs.readdirSync(dir)
    jison_file = /^.+\.jison$/
    for file in contents
        if file.match jison_file
            bnf = fs.readFileSync(path.join(dir, file), 'utf8')
            file = file.split('.')[0]
            ret[file] = jison.Parser(bnf)
    return ret

create_parser = (filename) ->


module.exports = get_parsers(__dirname)
