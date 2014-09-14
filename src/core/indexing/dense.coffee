
_ = require 'underscore'
utils = require '../../utils'

class IndexerBase

  broaden: (extraDimensions) ->
    shape = utils.repeat(1, extraDimensions).concat @shape
    strides = utils.repeat(0, extraDimensions).concat @strides
    new (getIndexerClass @nd+extraDimensions) shape, strides, @offset

  squeeze: ->
    shape = []
    strides = []
    for size, i in @shape
      continue if size is 1
      shape.push size
      strides.push @strides[i]
    new (getIndexerClass shape.length) shape, strides, @offset

indexerClasses = []

getIndexerClass = (nd) ->
  if nd < 1
    utils.throwWithData "Number of dimensions must be greater than 1", {nd}

  unless indexerClasses[nd]?
    indexerClasses[nd] = makeIndexerClass nd

  return indexerClasses[nd]

indexerClasses[1] = class Indexer1D extends IndexerBase

  @nd: 1

  constructor: (@shape, @strides, @offset) ->
    @nd = 1
    [@_shape] = @shape
    [@_stride] = @strides

  flatten: ([index]) -> @index index

  index: (index) -> @offset + @_stride*index

  slice: (start=0, stop=@_shape, stride=1) ->
    shape = [((stop-start)/stride)|0]
    new Indexer1D shape, [@_stride*stride], @offset+offset

  flatForEach: (func) ->
    offset = @offset
    for i in [0...@_shape] by 1
      if func offset then break
      offset += @_stride

makeIndexerClass = (nd) -> class Indexer extends IndexerBase

  @nd: nd

  constructor: (@shape, @strides, @offset) ->
    @nd = nd

  flatten: utils.buildCsFunction ['indices'], (f) ->
    f.line 'offset = @offset'
    f.line "offset += @strides[#{d}]*indices[#{d}]" for d in [0...nd]
    f.line "return offset"

  index: (index) ->
    offset = @offset + @strides[0]*index
    new (getIndexerClass nd-1) @shape.slice(1), @strides.slice(1), offset

  slice: (start=0, stop=@shape[0], stride=1) ->
    shape = @shape.slice 0
    shape[0] = Math.ceil((stop-start)/stride)|0

    strides = @strides.slice 0
    strides[0] *= stride

    new Indexer shape, strides, @offset + start*@strides[0]

  flatForEach: utils.buildCsFunction ['func'], (f) ->
    f.line "stride#{d} = @strides[#{d}]" for d in [0...nd]

    for d in [0...nd]
      offset = if d is 0 then '@offset' else "offset#{d-1}"
      f.line "offset#{d} = #{offset}"
      f.line "for i#{d} in [0...@shape[#{d}]] by 1"
      f.indent()
      if d is nd-1 then f.line "if func offset#{d} then break"
      f.line "offset#{d} += stride#{d}"

    f.dedent() for d in [0...nd]
    f.line 'return'


exports.makeIndexer = (shape, strides, offset=0) ->
  nd = shape.length

  unless strides?
    strides = new Array nd
    strides[nd-1] = 1
    strides[d] = strides[d+1]*shape[d+1] for d in [nd-2..0] by -1
    # set empty dimensions to 0 stride
    strides[d] = 0 for size, d in shape when size is 1

  new (getIndexerClass nd) shape, strides, offset

exports.flatLoop = (looper) ->
  {nd} = looper

  indexer = looper.var "indexer"
  strides = (looper.var "stride#{dim}" for dim in [0...nd])
  offsets = (looper.var "offsets#{dim}" for dim in [0...nd])

  looper
    .addArg indexer
    .on "beforeLoop", (builder) ->
      builder.line "[#{strides.join ","}] = #{indexer}.strides"
      builder.line "#{offsets[0]} = #{indexer}.offset"
    .on "beforeDimension", (dim, add) ->
      unless dim is nd-1
        builder.line "#{offsets[dim+1]} = #{offsets[dim]}"
    .on "afterDimension", (dim, add) ->
      builder.line "#{offsets[dim]} += #{strides[dim]}"

  return {flatIndex: offsets[nd-1], indexer}
