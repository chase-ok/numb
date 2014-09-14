
_ = require 'underscore'
utils = require '../../utils'

exports.broadcast = (indexers...) ->
    {nd} = longest = _.max indexers, ({nd}) -> nd

    resultShape = longest.shape.slice 0
    broadcasted = for indexer in indexers
        offset = nd - indexer.nd

        for i in [indexer.nd-1..0] by -1
            a = indexer.shape[i]
            b = resultShape[i+offset]
            if b is 1
                resultShape[i+offset] = a
            else if a isnt 1 and a isnt b
                utils.throwWithData "Cannot broadcast shapes", {indexers}

        if offset is 0 then indexer
        else indexer.broaden offset

    {shape: resultShape, indexers: broadcasted}
