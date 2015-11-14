program = require 'commander'

opts_parse = () ->
  program
    .version('0.0.1')
    .usage('[options]')
    .option('-v, --verbose', 'if to output verbose error messages')
    .option('-d, --dir [conf_dir]', 'the location of the config file')
    .parse(process.argv)
  return program

module.exports =
  opts_parse: opts_parse
