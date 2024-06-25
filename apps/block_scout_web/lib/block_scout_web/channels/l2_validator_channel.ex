defmodule BlockScoutWeb.L2ValidatorChannel do
  @moduledoc """
  Establishes pub/sub channel for change validator.
  """
  use BlockScoutWeb, :channel
  require Logger

  intercept([
    "all_validator",
    "active_validator",
    "candidate_validator",
    "history_validator",
  ])

  def join("platon_appchain_l2_validator:all_validator", _params, socket) do
    {:ok, %{}, socket}
  end

  def join("platon_appchain_l2_validator:active_validator", _params, socket) do
    {:ok, %{}, socket}
  end

  def join("platon_appchain_l2_validator:candidate_validator", _params, socket) do
    {:ok, %{}, socket}
  end

  def join("platon_appchain_l2_validator:history_validator", _params, socket) do
    {:ok, %{}, socket}
  end

  #    test begin
#  alias BlockScoutWeb.Endpoint
#  Endpoint.broadcast("platon_appchain:l1_to_l2_txn", "l1_to_l2_txn", %{
#    batch: 1
#  })
  #    test end
  def handle_out(
        "all_validator",
        validatorsCount,
        %Phoenix.Socket{handler: BlockScoutWeb.UserSocketV2} = socket
      ) do

    push(socket, "all_validator", %{count: validatorsCount})
    {:noreply, socket}
  end

  def handle_out(
        "active_validator",
        activeValidatorsCount,
        %Phoenix.Socket{handler: BlockScoutWeb.UserSocketV2} = socket
      ) do
    push(socket, "active_validator", %{count: activeValidatorsCount})
    {:noreply, socket}
  end

  def handle_out(
        "candidate_validator",
        validatorsCount,
        %Phoenix.Socket{handler: BlockScoutWeb.UserSocketV2} = socket
      ) do
#    result_validator = Enum.map(validators, fn validator -> convert_l2_validator(validator) end)
    push(socket, "candidate_validator", %{count: validatorsCount})
    {:noreply, socket}
  end

  def handle_out(
        "history_validator",
        historyValidatorsCount,
        %Phoenix.Socket{handler: BlockScoutWeb.UserSocketV2} = socket
      ) do
    push(socket, "history_validator", %{count: historyValidatorsCount})
    {:noreply, socket}
  end
end
