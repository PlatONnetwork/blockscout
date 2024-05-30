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
    statis =
      Enum.reduce(blocks, [], fn block, acc ->
        acc ++ get_l2_block_produced_statistic_if_round_end_block(block)
      end)

    # 去掉重复的，如果有重复的，在upsert的时候，PGSql 会发生错误：ON CONFLICT DO UPDATE command cannot affect row a second time
    # 实际上，在blockscout的所有importer中，因为是同一个事务中，所以都应该避免import的数据中有重复的。
    # 这个只是在测试时get_l2_block_produced_statistic_if_round_end_block/1方法去掉是否是共识周期结束块的判断时，才会出现重复数据，此时，需要去重。
    # Enum.uniq_by(statis, fn elem -> {elem.validator_hash, elem.round} end)
  end

  @spec get_l2_block_produced_statistic_if_round_end_block(map()) :: list()
  defp get_l2_block_produced_statistic_if_round_end_block(block) when is_map(block) do
    if PlatonAppchain.is_round_end_block(block.number) == true do
      #epoch = PlatonAppchain.calculateL2Epoch(block.number)
      round = PlatonAppchain.calculateL2Round(block.number)
      blocks_of_validator_list = L2StakeHandler.getBlocksOfValidators(@period_type[:round], round)

      get_l2_block_produced_statistic(blocks_of_validator_list,  round)
    else
      []
    end
  end

  # 返回list[map()]
  defp get_l2_block_produced_statistic(blocks_of_validator_list, round) do
    blocks_of_validator_list
    |> Enum.map(fn item ->
      %{
        round: round,
        validator_hash: item.validator_hash,
        should_blocks: PlatonAppchain.l2_round_size_per_validator(),
        actual_blocks: item.actual_blocks,
      }
    end)
  end
end
