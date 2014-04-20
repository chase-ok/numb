should = require('chai').should()
utils = require '../src/utils'

integers =
    positive: [1, 2, 100, 234, 34567]
    negative: [-1, -2, -32, -8723489]

reals =
    positive: [1e-50, 0.578, 54.23, 345.234234, 1e50]
    negative: [-1e-50, -0.234, -23.975, -190238.234, -1e-51]

numberChecks = 'isInteger isFloat isNumber isPositive isZero isNatural
                isNaN isInfinite'

numberSets =
    '0':
        matches: 'isInteger isFloat isNumber isZero isNatural'
        values: [0]
    'NaN': {matches: 'isNaN', values: [NaN]}
    '+infinity':
        matches: 'isInfinite isNumber isPositive'
        values: [Infinity]
    '-infinity':
        matches: 'isInfinite isNumber isNegative'
        values: [-Infinity]
    'positive integers':
        matches:  'isInteger isFloat isNumber isNatural isPositive'
        values: [1...10].concat [234234, 53449, 2**31-1]
    'negative integers':
        matches: 'isInteger isFloat isNumber isNegative'
        values: [-1...-10].concat [-893567, -2**31]
    'positive reals':
        matches: 'isFloat isNumber isPositive'
        values: [1e-300, 0.234, 1.345, 382978.32458, 1e300]
    'negative reals':
        matches: 'isFloat isNumber isNegative'
        values: [-1e-300, -0.234, -45.3245, -8975.34545, -1e300]

for check in numberChecks.split ' '
    do (check) -> describe check, ->
        for set, {matches, values} of numberSets
            do (set, matches, values) ->
                expected = check in matches.split ' '
                it "returns #{expected} for #{set}", ->
                    utils[check](x).should.equal expected for x in values

describe 'csFunction', ->
    {csFunction} = utils
    it 'returns a function', ->
        csFunction('a', '1 + a**2').should.be.an.instanceof Function
    it 'takes a comma-separated string or array of arguments', ->
        argLengths =
            '': 0
            'a': 1
            'a,b': 2
            'a,b,c,d,e,f': 6
        for args, length of argLengths
            csFunction(args, '').length.should.equal length
            csFunction(args.split(','), '').length.should.equal length
    it 'compiles the coffeescript body into correct javascript', ->
        func = (a, b, c) ->
            {x, y} = {x: a/b, y: 4*c}
            z = "#{b}"
            return a*b**c + Math.max((x*3 for x in [0...10])...)
        funcString = ''' 
            {x, y} = {x: a/b, y: 4*c}
            z = "#{b}"
            return a*b**c + Math.max((x*3 for x in [0...10])...)
        '''
        args = [1.2, 1.3, 9.4]
        func(args...).should.equal csFunction('a,b,c', funcString)(args...)
    it 'compiles the coffeescript body WITHOUT an implicit return!', ->
        should.not.exist csFunction('', '1')()
        should.exist csFunction('', 'return 1')()

describe 'throwWithData(message, data)', ->
   {throwWithData} = utils
   it 'throws an Error', ->
       should.throw -> throwWithData 'A message'
       should.throw -> throwWithData 'A message', {data:1}
       (-> throwWithData 'Message').should.throw Error
    it 'throws an error where @data=data', ->
        data = {foo: 'bar'}
        try throwWithData '', data
        catch error then error.data.should.be.equal data
    it 'throws an error where @message=message', ->
        message = 'a message'
        try throwWithData message, {x: 1}
        catch error then error.message.should.be.equal message
