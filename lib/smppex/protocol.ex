defmodule SMPPEX.Protocol do

  alias SMPPEX.Protocol.CommandNames
  import SMPPEX.ParseResult

  def parse(bin) when byte_size(bin) < 4 do
    ok(nil, bin)
  end

  def parse(bin) do
    <<command_length :: big-unsigned-integer-size(32), rest :: binary >> = bin
    cond do
      command_length < 16 ->
        error("Invalid PDU command_length #{inspect command_length}")
      command_length <= byte_size(bin) ->
        body_length = command_length - 16
        << header :: binary-size(12), body :: binary-size(body_length), next_pdus :: binary >> = rest
        ok(parse_pdu(header, body), next_pdus)
      true ->
        ok(nil, bin)
    end
  end

  defp parse_pdu(header, body) do
    case parse_header(header) do
      {:ok, pdu} ->
        parse_body(pdu.command_name, pdu, body)
      {:unknown, pdu} ->
        pdu
    end
  end

  defp parse_header(<<command_id :: big-unsigned-integer-size(32), command_status :: big-unsigned-integer-size(32), sequence_number :: big-unsigned-integer-size(32)>>) do
    case CommandNames.name_by_id(command_id) do
      {:ok, name} ->
        {:ok, %SMPPEX.Pdu{
          command_id: command_id,
          command_name: name,
          command_status: command_status,
          sequence_number: sequence_number
        }}
      :unknown ->
        {:unknown, %SMPPEX.Pdu{
          command_id: command_id,
          command_status: command_status,
          sequence_number: sequence_number,
          valid: false
        }}
    end
  end

  defp parse_body(command_id, pdu, body) do
    map = mandatory_field_map(command_id)
    case parse_mandatory_fields(map, body) do
      {:ok, fields, rest_tlvs} ->
        case parse_optional_fields(rest_tlvs) do
          {:ok, tlvs} ->
            %SMPPEX.Pdu{ pdu | mandatory: fields, optional: tlvs }
          error -> {:error, {"TLV parse error", error}}
        end
      error -> {:error, {"Mandatory fields parse error", error}}
    end
  end

  defp mandatory_field_map(_command_id), do: nil

  defp parse_mandatory_fields(_map, body), do: {:ok, %{}, body}
  defp parse_optional_fields(_body), do: {:ok, %{}}

end
