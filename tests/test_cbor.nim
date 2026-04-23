# json-rpc
# Copyright (c) 2019-2023 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

import ../json_rpc/rpcclient except EnumRepresentation, shouldWriteObjectField
import ../json_rpc/rpcserver except EnumRepresentation, shouldWriteObjectField
import chronos/unittest2/asynctests
import cbor_serialization

createCborFlavor CborFlavor,
  automaticObjectSerialization = false,
  automaticPrimitivesSerialization = false

CborFlavor.defaultSerialization string

proc setupServer*(srv: RpcServer) =
  srv.rpc(CborFlavor):
    proc myProcCtx1(s: string): string =
      #doAssert false
      return s

createRpcSigsFromNim(RpcClient, CborFlavor):
  proc myProcCtx1(s: string): string

template callTests(client: untyped) =
  test "Successful RPC call":
    let r = waitFor client.myProcCtx1("abc")
    check r.string == "abc"

suite "Socket Server/Client RPC/lengthHeaderBE32":
  setup:
    const framing = Framing.lengthHeaderBE32()
    var srv = newRpcSocketServer(["127.0.0.1:0"], framing = framing)
    var client = newRpcSocketClient(framing = framing)

    srv.setupServer()
    srv.start()
    waitFor client.connect(srv.localAddress()[0])

  teardown:
    waitFor client.close()
    srv.stop()
    waitFor srv.closeWait()

  callTests(client)
