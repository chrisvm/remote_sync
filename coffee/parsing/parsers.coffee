jison = require 'jison'
fs = require 'fs'
path = require 'path'

get_parsers = (dir) ->
    ret = {}
    contents = fs.readdirSync(dir)
    jison_file = /^.+\.jison$/
    for file in contents
        if file.match jison_file
            ret[file.split('.')[0]] = create_parser(dir, file)
    external_parsers(ret)
    return ret

create_parser = (dir, filename) ->
    bnf = fs.readFileSync(path.join(dir, filename), 'utf8')
    parser = jison.Parser(bnf)
    parser._parse = parser.parse
    parser.parse = (string) ->
        try
            ret = parser._parse(string)
        catch e
            ret = null
        return ret
    return parser

external_parsers = (parsers) ->
    parsers.Path = parse: (to_parse) ->
        ret = path.parse to_parse
        ret.path = to_parse
        return ret

module.exports = get_parsers(__dirname)
