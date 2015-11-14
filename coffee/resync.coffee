validate = require './config/validate'
config = require './config/config'


main = () ->
    # get config
    cnf = config.read(process.cwd())

main()
