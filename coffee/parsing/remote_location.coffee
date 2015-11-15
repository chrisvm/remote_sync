Parser = require('jison').Parser
path = require('path')
fs = require('fs')

bnf = fs.readFileSync(path.join(__dirname, 'remote_location.jison'), 'utf8')
parser = new Parser(bnf)

module.exports = parser
