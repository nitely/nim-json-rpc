# json-rpc
# Copyright (c) 2023-2025 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

{.push raises: [], gcsafe.}

import
  json_serialization,
  cbor_serialization,
  cbor_serialization/pkg/results as cbor_results,
  stew/byteutils

export cbor_serialization, cbor_results

# XXX disable distinct writer
createCborFlavor CrpcSys,
  automaticObjectSerialization = false,
#  automaticPrimitivesSerialization = false,
  requireAllFields = true,
  omitOptionalFields = true, # Skip optional fields==none in Writer
  allowUnknownFields = true,
  skipNullFields = false     # Skip optional fields==null in Reader

proc toJsonString(value: CborBytes): JsonString =
  string.fromBytes(seq[byte](value)).JsonString

proc readValue*(r: var CrpcSys.Reader, val: var JsonString)
       {.gcsafe, raises: [IOError, SerializationError].} =
  val = r.readValue(CborBytes).toJsonString()

proc writeValue*(w: var CrpcSys.Writer, val: JsonString)
       {.gcsafe, raises: [IOError].} =
  w.writeValue CborBytes(val.string.toBytes())

proc readJsonRPC2Literal*(r: var CrpcSys.Reader): JsonString
       {.gcsafe, raises: [IOError, SerializationError].} =
  r.readValue(string).JsonString

proc writeJsonRpc2Literal*(w: var CrpcSys.Writer, val: JsonString)
      {.gcsafe, raises: [IOError].} =
  w.writeValue val.string

proc writeNullValue*(w: var CrpcSys.Writer)
      {.gcsafe, raises: [IOError].} =
  w.writeValue cborNull

## Shims for Json compat

proc tokKind*(r: var CrpcSys.Reader): JsonValueKind
       {.gcsafe, raises: [IOError, SerializationError].} =
  case r.parser.cborKind()
  of CborValueKind.Bytes: JsonValueKind.Array
  of CborValueKind.String: JsonValueKind.String
  of CborValueKind.Unsigned, CborValueKind.Negative, CborValueKind.Float: JsonValueKind.Number
  of CborValueKind.Object: JsonValueKind.Object
  of CborValueKind.Array: JsonValueKind.Array
  of CborValueKind.Bool: JsonValueKind.Bool
  of CborValueKind.Null, CborValueKind.Undefined: JsonValueKind.Null
  # This is not quite accurate but it's never checked for these values
  # and we still want to support them in positional paramenters
  of CborValueKind.Tag: JsonValueKind.Number
  of CborValueKind.Simple: JsonValueKind.Number

proc parseAsString*(r: var CrpcSys.Reader): JsonString
       {.gcsafe, raises: [IOError, SerializationError].} =
  r.readValue(JsonString)

proc parseNull*(r: var CrpcSys.Reader)
       {.gcsafe, raises: [IOError, SerializationError].} =
  discard r.parseSimpleValue()

template writeMember*(w: var CrpcSys.Writer, name: string, value: auto) =
  writeField(w, name, value)

proc writeArray*[C: not void](w: var CrpcSys.Writer, values: C) {.raises: [IOError].} =
  mixin writeValue
  w.writeValue(values)

template beginRecord*(w: var CrpcSys.Writer, _: type) =
  w.beginObject()

template endRecord*(w: var CrpcSys.Writer) =
  w.endObject()

#const
#  JsonRPC2Literal = "2.0"
#  MaxIdStringLength = 256

#template shouldWriteObjectField*(F: type Cbor, field: RequestParamsTx): bool =
#  case field.kind
#  of rpPositional:
#    field.positional.len > 0
#  of rpNamed:
#    field.named.len > 0
#
#func isFieldExpected*(F: type Cbor, _: type RequestParamsRx): bool {.compileTime.} =
#  false

#proc readValue*(r: var CrpcSys.Reader, val: var JsonRPC2)
#      {.gcsafe, raises: [IOError, SerializationError].} =
#  let version = r.readValue(string)
#  if version != JsonRPC2Literal:
#    r.raiseUnexpectedValue("Invalid JSON-RPC version, want=" &
#      JsonRPC2Literal & " got=" & version)
#
#proc writeValue*(w: var CrpcSys.Writer, val: JsonRPC2)
#      {.gcsafe, raises: [IOError].} =
#  w.writeValue JsonRPC2Literal
#
#proc readValue*(r: var CrpcSys.Reader, val: var RequestId)
#      {.gcsafe, raises: [IOError, SerializationError].} =
#  let ck = r.parser.cborKind()
#  case ck
#  of CborValueKind.Unsigned, CborValueKind.Negative:
#    val = RequestId(kind: riNumber, num: r.readValue(int))
#  of CborValueKind.String:
#    val = RequestId(kind: riString, str: r.parseString(MaxIdStringLength))
#  of CborValueKind.Null:
#    val = RequestId(kind: riNull)
#    discard r.parseSimpleValue()
#  else:
#    r.raiseUnexpectedValue("Invalid RequestId, must be Number, String, or Null, got=" & $ck)
#
#proc writeValue*(w: var CrpcSys.Writer, val: RequestId)
#       {.gcsafe, raises: [IOError].} =
#  case val.kind
#  of riNumber: w.writeValue val.num
#  of riString: w.writeValue val.str
#  of riNull:   w.writeValue cborNull
#
#proc readValue*(
#    r: var CrpcSys.Reader, value: var Opt[RequestId]
#) {.raises: [IOError, SerializationError].} =
#  value.ok r.readValue(RequestId)
#
#proc toJsonString(value: CborBytes): JsonString =
#  string.fromBytes(seq[byte](value)).JsonString
#
#proc readValue*(r: var CrpcSys.Reader, val: var JsonString)
#       {.gcsafe, raises: [IOError, SerializationError].} =
#  val = r.readValue(CborBytes).toJsonString()
#
#proc writeValue*(w: var CrpcSys.Writer, val: JsonString)
#       {.gcsafe, raises: [IOError].} =
#  w.writeValue CborBytes(val.string.toBytes())
#
#proc toJsonKind(k: CborValueKind): JsonValueKind =
#  case k
#  of CborValueKind.Bytes: JsonValueKind.Array
#  of CborValueKind.String: JsonValueKind.String
#  of CborValueKind.Unsigned, CborValueKind.Negative, CborValueKind.Float: JsonValueKind.Number
#  of CborValueKind.Object: JsonValueKind.Object
#  of CborValueKind.Array: JsonValueKind.Array
#  of CborValueKind.Bool: JsonValueKind.Bool
#  of CborValueKind.Null, CborValueKind.Undefined: JsonValueKind.Null
#  # This is not quite accurate but it does not matter; it's only
#  # used to check if ParamDescRx kind is null or not
#  of CborValueKind.Tag: JsonValueKind.Array
#  of CborValueKind.Simple: JsonValueKind.Number
#
#proc readValue*(r: var CrpcSys.Reader, val: var RequestParamsRx)
#       {.gcsafe, raises: [IOError, SerializationError].} =
#  let ck = r.parser.cborKind()
#  case ck
#  of CborValueKind.Array:
#    val = RequestParamsRx(kind: rpPositional)
#    r.parseArray:
#      val.positional.add ParamDescRx(
#        kind: ck.toJsonKind(),
#        param: r.readValue(JsonString),
#      )
#  of CborValueKind.Object:
#    val = RequestParamsRx(kind: rpNamed)
#    for key in r.readObjectFields():
#      val.named.add ParamDescNamed(
#        name: key,
#        value: r.readValue(JsonString),
#      )
#  else:
#    r.raiseUnexpectedValue("RequestParam must be either array or object, got=" & $ck)
#
#proc writeValue*(w: var CrpcSys.Writer, val: RequestParamsTx)
#      {.gcsafe, raises: [IOError].} =
#  case val.kind
#  of rpPositional:
#    w.writeValue val.positional
#  of rpNamed:
#    w.writeObject:
#      for x in val.named:
#        w.writeField(x.name, x.value)
#
#proc readValue*(r: var CrpcSys.Reader, val: var ResponseRx)
#       {.gcsafe, raises: [IOError, SerializationError].} =
#  # We need to overload ResponseRx reader because
#  # we don't want to skip null fields
#  r.parseObjectWithoutSkip(key):
#    case key
#    of "jsonrpc": r.readValue(val.jsonrpc)
#    of "id"     : r.readValue(val.id)
#    of "result" : val.result = r.readValue(JsonString)
#    of "error"  : r.readValue(val.error)
#    else: discard
#
#proc readValue*(r: var CrpcSys.Reader, val: var ResponseRx2)
#       {.gcsafe, raises: [IOError, SerializationError].} =
#  # https://www.jsonrpc.org/specification#response_object
#
#  var
#    jsonrpcOpt: Opt[JsonRPC2]
#    idOpt: Opt[RequestId]
#    resultOpt: Opt[JsonString]
#    errorOpt: Opt[ResponseError]
#
#  r.parseObjectWithoutSkip(key):
#    case key
#    of "jsonrpc": r.readValue(jsonrpcOpt)
#    of "id"     : r.readValue(idOpt)
#    of "result" : resultOpt.ok r.readValue(JsonString)
#    of "error"  : r.readValue(errorOpt)
#    else: discard
#
#  if jsonrpcOpt.isNone:
#    r.parser.raiseIncompleteObject("Missing or invalid `jsonrpc` version")
#  let id = idOpt.valueOr:
#    r.parser.raiseIncompleteObject("Missing `id` field")
#
#  if resultOpt.isNone() and errorOpt.isNone():
#    r.parser.raiseIncompleteObject("Missing `result` or `error` field")
#
#  if errorOpt.isSome():
#    if resultOpt.isSome():
#      r.raiseUnexpectedValue("Both `result` and `error` fields present")
#
#    val = ResponseRx2(id: id, kind: ResponseKind.rkError, error: move(errorOpt[]))
#  else:
#    val = ResponseRx2(id: id, kind: ResponseKind.rkResult, result: move(resultOpt[]))
#
#proc readValue*(r: var CrpcSys.Reader, val: var RequestBatchRx)
#       {.gcsafe, raises: [IOError, SerializationError].} =
#  let ck = r.parser.cborKind()
#  case ck
#  of CborValueKind.Array:
#    val = RequestBatchRx(kind: rbkMany)
#    r.readValue(val.many)
#    if val.many.len == 0:
#      r.raiseUnexpectedValue("Batch must contain at least one message")
#  of CborValueKind.Object:
#    val = RequestBatchRx(kind: rbkSingle)
#    r.readValue(val.single)
#  else:
#    r.raiseUnexpectedValue("RequestBatch must be either array or object, got=" & $ck)
#
#template writeRequest*(writer: var Writers, name: string, params: RequestParamsTx, id: int) =
#  writer.writeObject:
#    writer.writeField("jsonrpc", JsonRPC2())
#    writer.writeField("method", name)
#    writer.writeField("params", params)
#    writer.writeField("id", id)
#
#template writeNotification*(writer: var CrpcSys.Writer, name: string, params: RequestParamsTx) =
#  writer.writeObject:
#    writer.writeField("jsonrpc", JsonRPC2())
#    writer.writeField("method", name)
#    writer.writeField("params", params)
#
#template withWriter*(T: type CrpcSys, writer, body: untyped): seq[byte] =
#  var stream = memoryOutput()
#
#  {.cast(noSideEffect), cast(raises: []).}:
#    var writer = T.Writer.init(stream)
#    body
#
#  stream.getOutput(seq[byte])

{.pop.}
