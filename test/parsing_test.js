var parsing_dir, path, should;

require('coffee-script/register');

should = require('should');

path = require('path');

parsing_dir = '../coffee/parsing';

describe("Parsing", function() {
  var Parsers;
  Parsers = require(path.join(parsing_dir, 'parsers'));
  return describe('Parsers.RemoteLocation', function() {
    var parser;
    parser = Parsers.RemoteLocation;
    it('should correctly parse a remote location', function() {
      var parsed, test_loc;
      test_loc = "someuser@127.0.0.1:/";
      parsed = parser.parse(test_loc);
      parsed.host.host.should.equal('127.0.0.1');
      parsed.user.user.should.equal('someuser');
      return parsed.path.path.should.equal('/');
    });
    return it('should correctly parse a remote location with password', function() {
      var parsed, test_loc;
      test_loc = "someuser:somepass@127.0.0.1:/";
      parsed = parser.parse(test_loc);
      parsed.host.host.should.equal('127.0.0.1');
      parsed.user.user.should.equal('someuser');
      parsed.user.password.should.equal('somepass');
      return parsed.path.path.should.equal('/');
    });
  });
});
