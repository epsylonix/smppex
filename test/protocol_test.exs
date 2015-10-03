defmodule SMPPEX.ProtocolTest do
  use AssertHelpers
  use HexHelpers

  import SMPPEX.Protocol

  test "parse: insuficient data" do
    assert parse(<<1,2,3,4,5,6,7,8,9,0,1,2,3,4,5>>) == {:ok, nil, <<1,2,3,4,5,6,7,8,9,0,1,2,3,4,5>>}
    assert parse(<<1,2,3>>) == {:ok, nil, <<1,2,3>>}
  end

  test "parse: bad command_length" do
    assert {:error, _} = parse(from_hex "00 00 00 0F   00 00 00 00   00 00 00 00   00 00 00 00")
  end

  test "parse: bad command_id" do
    pdu = %SMPPEX.Pdu{
      command_id: 0x80003302,
      command_name: nil,
      command_status: 0,
      sequence_number: 1,
      valid: false
    }
    tail = from_hex("AA BB CC")
    assert {:ok, ^pdu, ^tail} = parse(from_hex "00 00 00 10   80 00 33 02   00 00 00 00   00 00 00 01   AA BB CC")
  end

  test "parse: good header" do
    pdu = %SMPPEX.Pdu{
      command_id: 0x80000002,
      command_name: :bind_transmitter_resp,
      command_status: 0,
      sequence_number: 1
    }
    tail = from_hex("AA BB CC")
    assert {:ok, ^pdu, ^tail} = parse(from_hex "00 00 00 10   80 00 00 02   00 00 00 00   00 00 00 01   AA BB CC")
  end
end

