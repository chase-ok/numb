
require 'flour'
spawn = require 'win-spawn'

doMochaTest = (watch=no) ->
    args = ['--compilers', 'coffee:coffee-script/register', '--recursive',
            '--reporter', 'dot']
    args.push '--watch' if watch
    spawn 'mocha', args, {stdio: 'inherit'}

task 'test:watch', 'test continuously with mocha', -> doMochaTest yes
task 'test', 'test with mocha', -> doMochaTest no
    
parser = 'src/core/lang/parser.coffee'
task 'parser:build', -> spawn 'node_modules/.bin/coffee', [parser]
task 'parser:watch', -> watch parser, -> invoke 'parser:build'
