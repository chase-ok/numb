
_ = require 'underscore'
utils = require '../../utils'
{ceil} = Math
looping = require './looping'
{makeIndexer: makeStridedIndexer} = require './strided'

class IndexerBase

indexerClasses = []

getIndexerClass = (nd) ->
  if nd < 1
    utils.throwWithData "Number of dimensions must be greater than 1", {nd}
  indexerClasses[nd] or= makeIndexerClass nd

# TODO: turn this into a meta class!
makeIndexerClass = (nd) -> 
  class Indexer extends IndexerBase

    @nd: nd
    nd: nd

    constructor: 
      if nd is 1 
        (@shape, @offset) -> [@_shape0] = @shape
      else
        utils.buildCsFunction, ['shape', 'offset'], (f) ->
          f.line "@shape = shape"
          f.line "@offset = offset"
          f.line "@_shape#{d} = shape[#{d}]" for d in [0...nd]
          f.line "@_stride#{nd-2} = @_shape#{nd-1}"
          for d in [nd-3..0] by -1
            f.line "@_stride#{d} = @_stride#{d+1}*@_shape#{d+1}"

    flatten: utils.buildCsFunction ['indices'], (f) ->
      f.line 'offset = @offset + indices[#{nd-1}]'
      f.line "offset += @_stride#{d}*indices[#{d}]" for d in [0...nd-1]
      f.line "return offset"

    index: (index) ->
      new (getIndexerClass nd-1) @shape.slice(1), @offset + @_stride0*index

    slice: (start=0, stop=@_shape0, stride=1) ->
      shape = @shape.slice 0
      shape[0] = ceil((stop-start)/stride)|0

      strides = @strides.slice 0
      strides[0] *= stride

      makeStridedIndexer shape, strides, @offset + start*@_stride0

    flatForEach: do ->
      loopFunc = looping.flatLoop nd, (looper) ->
        {flatIndex} = indexFlatLoop looper
        looper
          .addArg "func"
          .on "step", -> looper.line "return if func(#{flatIndex}) is true"
      (func) -> loopFunc @shape, this, func

  if nd is 1
    Indexer::flatten = ([index]) -> @offset + index
    Indexer::index = (index) -> @offset + index

  return Indexer


exports.makeIndexer = (shape, offset=0) ->
  new (getIndexerClass shape.length) shape, offset

exports.indexFlatLoop = indexFlatLoop = (looper) ->
  {nd} = looper

  indexer = looper.var "indexer"
  offset = looper.var "offset"

  looper
    .addArg indexer
    .on "beforeLoop", ->
      looper.line "#{offset} = #{indexer}.offset"
    .afterDimension, (dim) ->
      looper.line "#{offset}++" if dim is nd-1

  return {flatIndex: offset, indexer}
