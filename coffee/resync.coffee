validate = require './config/validation'
config = require './config/config'


main = () ->
    # get config
    cnf = config.read(process.cwd())

    console.log('Config:', cnf);
main()
