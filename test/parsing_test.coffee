require 'coffee-script/register'

should = require 'should'
path = require 'path'

parsing_dir = '../coffee/parsing'

describe "Parsing", () ->
    Parsers = require path.join parsing_dir, 'parsers'

    describe 'Parsers.RemoteLocation', () ->
        parser = Parsers.RemoteLocation
        it 'should correctly parse a remote location', () ->
            test_loc = "someuser@127.0.0.1:/"

            parsed = parser.parse(test_loc)
            parsed.host.host.should.equal('127.0.0.1')
            parsed.user.user.should.equal('someuser')
            parsed.path.path.should.equal('/')

        it 'should correctly parse a remote location with password', () ->
            test_loc = "someuser:somepass@127.0.0.1:/"

            parsed = parser.parse(test_loc)
            parsed.host.host.should.equal('127.0.0.1')
            parsed.user.user.should.equal('someuser')
            parsed.user.password.should.equal('somepass')
            parsed.path.path.should.equal('/')

        it 'should return null on wrong string', () ->
            test_loc = 'asdafadsfasf'
            parsed = parser.parse(test_loc)
            should.not.exist(parsed)
