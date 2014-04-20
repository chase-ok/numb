
exports.isInteger = isInteger = (x) -> isNumber(x) and x is (x|0)
exports.isFloat = isFloat = (x) -> isNumber(x) and not isNaN(x) and isFinite(x)
exports.isNumber = isNumber = (x) -> x is +x
exports.isPositive = isPositive = (x) -> isNumber(x) and x > 0
exports.isNegative = (x) -> isNumber(x) and x < 0
exports.isZero = (x) -> x is 0
exports.isNatural = (x) -> isInteger(x) and x >= 0
exports.isNaN = isNaN
exports.isInfinite = (x) -> not isFinite(x) and not isNaN(x)


coffee = require 'coffee-script'
compileCoffee = (code) -> coffee.compile code, {bare: yes}

sentinel = '$$$'
wrapper = compileCoffee sentinel
sentinelIndex = wrapper.indexOf sentinel
header = wrapper[...sentinelIndex]
footer = wrapper[sentinelIndex+sentinel.length...]

exports.csFunction = (args, body) ->
    wrapped = compileCoffee body
    code = wrapped[header.length...wrapped.length-footer.length+1]
    new Function args, code


class ErrorWithData extends Error
    constructor: (@message, @data) ->

exports.throwWithData = throwWithData = (message='', data={}) ->
    error = new ErrorWithData message, data
    Error.captureStackTrace? error, throwWithData
    throw error

