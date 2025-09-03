defmodule Indexer.Transform.PlatonAppchain.L2ValidatorEvents do
  @moduledoc """
  Helper functions for transforming data for Platon Appchain l2 validator events.
  """

  require Logger

  alias Indexer.Fetcher.PlatonAppchain.L2ValidatorEvent
  alias Indexer.Helper

  @doc """
  Returns a list of l2 executes given a list of logs.
  apps/indexer/lib/indexer/block/fetcher.ex中fetch_and_import_range()中调用，得到事件并import到db
  """
  @spec parse(list(), list()) :: list()
  def parse(logs, json_rpc_named_arguments) do
    Logger.debug("to parse L2ValidatorEvents")
    prev_metadata = Logger.metadata()
    Logger.metadata(fetcher: :platon_appchain_l2_validator_events_realtime)

    items =
      with false <-
             is_nil(Application.get_env(:indexer, L2ValidatorEvent)[:start_block_l2]),
           l2_stake_handler = Application.get_env(:indexer, L2ValidatorEvent)[:l2_stake_handler],
           true <- Helper.address_correct?(l2_stake_handler) do
        l2_stake_handler = String.downcase(l2_stake_handler)
        event_signatures = L2ValidatorEvent.event_signatures()

        Logger.debug("to parse L2ValidatorEvents-2")

        logs
        |> Enum.filter(fn log ->

          #Logger.debug("to parse L2ValidatorEvents-3 log: #{inspect(log)}")

          result = !is_nil(log.first_topic) && Enum.member?(event_signatures, String.downcase(log.first_topic)) &&
            String.downcase(Helper.address_hash_to_string(log.address_hash)) == l2_stake_handler
          #Logger.debug("L2ValidatorEvents3:(#{inspect(result)}")
            result
        end)
        |> Enum.reduce([], fn log, acc ->
          Logger.info("L2 (Stake Event) message found, validator: #{log.second_topic}.")

          # todo:
          # l2_events.ex等几个文件中，为什么没有用Enum.reduce递归，而是直接用了一个Enum.map？
          acc ++ L2ValidatorEvent.event_to_l2_validator_events(
            log.index,
            log.first_topic,
            log.second_topic,
            log.third_topic,
            log.data,
            log.transaction_hash,
            log.block_number,
            json_rpc_named_arguments
          )
        end)
      else
        true ->
          []

        false ->
          Logger.error("L2 StakeHandler contract address is incorrect. Cannot use #{__MODULE__} for parsing logs.")
          []
      end

    Logger.reset_metadata(prev_metadata)

    items
  end
end
