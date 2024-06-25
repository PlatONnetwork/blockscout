defmodule BlockScoutWeb.L1L2EventChannel do
  @moduledoc false
  use BlockScoutWeb, :channel

  intercept([
    "l1_to_l2_txn",
    "l2_to_l1_txn"
  ])

  def join("platon_appchain:l1_to_l2_txn", _params, socket) do
    IO.puts("websocket is join to L1L2EventChannel>>>>>>>>>>>>>>>>>>>>>>>>>")
    {:ok, %{}, socket}
  end

  def join("platon_appchain:l2_to_l1_txn", _params, socket) do
    IO.puts("websocket is join to L2L1EventChannel>>>>>>>>>>>>>>>>>>>>>>>>>")
    {:ok, %{}, socket}
  end


  def handle_out(
        "l1_to_l2_txn",
        l1_events,
        %Phoenix.Socket{handler: BlockScoutWeb.UserSocketV2} = socket
      ) do
    IO.puts("websocket handle_out l1_to_l2_txn tx to client>>>>>>>>>>>>>>>>>>>>>>>>>")
    push(socket, "l1_to_l2_txn", %{
      tx_hash: "tx_hash",
      block_number: 1
    })

    {:noreply, socket}
  end


  def handle_out(
        "l2_to_l1_txn",
        l2_events,
        %Phoenix.Socket{handler: BlockScoutWeb.UserSocketV2} = socket
      ) do
    IO.puts("websocket handle_out l2_to_l1_txn tx to client>>>>>>>>>>>>>>>>>>>>>>>>>")
    push(socket, "l2_to_l1_txn", %{
      tx_hash: "tx_hash",
      block_number: 1
    })

    {:noreply, socket}
  end
end
