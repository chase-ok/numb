
_ = require 'underscore'
utils = require '../../utils'
{ceil} = Math
looping = require './looping'

class IndexerBase

  broaden: (extraDimensions) ->
    shape = utils.repeat(1, extraDimensions).concat @shape
    strides = utils.repeat(0, extraDimensions).concat @strides
    new (getIndexerClass @nd+extraDimensions) shape, strides, @offset

  squeeze: ->
    shape = []
    strides = []
    for size, i in @shape when size isnt 1
      shape.push size
      strides.push @strides[i]
    new (getIndexerClass shape.length) shape, strides, @offset

indexerClasses = []

getIndexerClass = (nd) ->
  if nd < 1
    utils.throwWithData "Number of dimensions must be greater than 1", {nd}
  indexerClasses[nd] or= makeIndexerClass nd

makeIndexerClass = (nd) -> 
  class Indexer extends IndexerBase

    @nd: nd
    nd: nd

    constructor: (@shape, @strides, @offset) ->

    flatten: utils.buildCsFunction ['indices'], (f) ->
      f.line 'offset = @offset'
      f.line "offset += @strides[#{d}]*indices[#{d}]" for d in [0...nd]
      f.line "return offset"

    index: (index) ->
      offset = @offset + @strides[0]*index
      new (getIndexerClass nd-1) @shape.slice(1), @strides.slice(1), offset

    slice: (start=0, stop=@shape[0], stride=1) ->
      shape = @shape.slice 0
      shape[0] = ceil((stop-start)/stride)|0

      strides = @strides.slice 0
      strides[0] *= stride

      new Indexer shape, strides, @offset + start*@strides[0]

    flatForEach: do ->
      loopFunc = looping.flatLoop nd, (looper) ->
        {flatIndex} = indexFlatLoop looper
        looper
          .addArg "func"
          .on "step", -> looper.line "return if func(#{flatIndex}) is true"
      (func) -> loopFunc @shape, this, func

  if nd is 1
    Indexer::flatten = ([index]) -> @index index
    Indexer::index = (index) -> @offset + @_stride0*index

  return Indexer

exports.makeIndexer = (shape, strides, offset=0) ->
  nd = shape.length

  unless strides?
    strides = new Array nd
    strides[nd-1] = 1
    strides[d] = strides[d+1]*shape[d+1] for d in [nd-2..0] by -1
    # set empty dimensions to 0 stride
    strides[d] = 0 for size, d in shape when size is 1

  new (getIndexerClass nd) shape, strides, offset

exports.indexFlatLoop = indexFlatLoop = (looper) ->
  {nd} = looper

  indexer = looper.var "indexer"
  strides = (looper.var "stride#{dim}" for dim in [0...nd])
  offsets = (looper.var "offsets#{dim}" for dim in [0...nd])

  looper
    .addArg indexer
    .on "beforeLoop", ->
      looper.line "[#{strides.join ","}] = #{indexer}.strides"
      looper.line "#{offsets[0]} = #{indexer}.offset"
    .on "beforeDimension", (dim) ->
      looper.line "#{offsets[dim+1]} = #{offsets[dim]}" unless dim is nd-1
    .on "afterDimension", (dim) ->
      looper.line "#{offsets[dim]} += #{strides[dim]}"

  return {flatIndex: offsets[nd-1], indexer}
