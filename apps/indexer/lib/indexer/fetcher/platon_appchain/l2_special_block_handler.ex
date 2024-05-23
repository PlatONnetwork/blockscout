defmodule Indexer.Fetcher.PlatonAppchain.L2SpecialBlockHandler do
  @moduledoc """
  处理L2在特殊区块上的逻辑
  """

  require Logger

  alias Indexer.Fetcher.PlatonAppchain
  alias Indexer.Fetcher.PlatonAppchain.Contracts.{L2StakeHandler,L2RewardManager}

  @period_type [round: 1, epoch: 2]

  # 共识周期结束，调用底层rpc，得到此共识周期，每个验证人实际出块数，再加上配置的应该出块数，就可以算出每个验证人的出块率。
  # 如果一个验证人的出库数是0，底层也会返回。
  @spec l2_block_produced_statistics(list()) :: list()
  def l2_block_produced_statistics(blocks) when is_list(blocks) do
      Enum.reduce(blocks, [], fn block, acc ->
        [get_l2_block_produced_statistic_if_round_end_block(block) | acc]
      end)
  end

  @spec get_l2_block_produced_statistic_if_round_end_block(map()) :: list()
  defp get_l2_block_produced_statistic_if_round_end_block(block) when is_map(block) do
    if PlatonAppchain.is_round_end_block(block.number) == true do
      epoch = PlatonAppchain.calculateL2Epoch(block.number)
      round = PlatonAppchain.calculateL2Round(block.number)
      blocks_of_validator_list = L2StakeHandler.get_blocks_of_validators(@period_type[:round], round)
      get_l2_block_produced_statistic(blocks_of_validator_list, epoch, round)
    end
  end

  defp get_l2_block_produced_statistic(blocks_of_validator_list, epoch, round) do
    blocks_of_validator_list
    |> Enum.map(fn item ->
      %{
        epoch: epoch,
        round: round,
        validator_hash: item.validator_hash,
        should_blocks: 10, #todo: 做成env的变量
        actual_blocks: item.actual_blocks,
      }
    end)
  end
end
