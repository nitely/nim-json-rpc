
import
  stew/[base64, byteutils],
  cbor_serialization,
  json_serialization

export cbor_serialization

{.push raises: [], gcsafe.}

#proc readValue*(
#    r: var CborReader, value: var JsonString
#) {.raises: [IOError, SerializationError].} =
#  value = decode(Base64, r.readValue(string)).JsonString

#converter toJsonString*(x: seq[byte]): JsonString =
#  #debugEcho encode(Base64, x)
#  JsonString("\"" & encode(Base64, x) & "\"")

proc readValue*(
    r: var CborReader, value: var string
) {.raises: [IOError, SerializationError].} =
  r.read(value)

proc writeValue*(
    r: var CborWriter, value: string
) {.raises: [IOError].} =
  r.write(value)

#proc writeValue*(
#    r: var CborWriter, value: JsonString
#) {.raises: [IOError].} =
#  let val = string.fromBytes(encode(Base64, value.string.toBytes()))
#  r.writeValue(val)
