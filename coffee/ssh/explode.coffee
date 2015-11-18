through2 = require 'through2'

explode = (char, done) ->
    buff = ''
    all = []
    sink = through2 (chunk, enc, callback) ->
        buff += chunk.toString()
        index = buff.indexOf(char)
        if index > -1
            splited = buff.split(char)
            buff = splited[splited.length - 1]
            splited = splited.slice(0, splited.length - 1)
            for string in splited
                if string isnt ''
                    this.push(string)
        callback()

    sink.on 'data', (data) ->
        all.push data.toString()

    sink.on 'end', () ->
        if buff isnt ''
            all.push buff
        done(all)
    return sink

module.exports = explode
