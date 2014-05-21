
# require 'flour'
spawn = require 'win-spawn'

doMochaTest = (watch=no) ->
    args = ['--compilers', 'coffee:coffee-script/register', '--recursive',
            '--reporter', 'dot']
    args.push '--watch' if watch
    spawn 'mocha', args, {stdio: 'inherit'}

task 'watch:test', 'test continuously with mocha', -> doMochaTest yes
task 'test', 'test with mocha', -> doMochaTest no
    
