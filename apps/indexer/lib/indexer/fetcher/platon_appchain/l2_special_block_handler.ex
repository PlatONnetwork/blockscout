defmodule Indexer.Fetcher.PlatonAppchain.L2SpecialBlockHandler do
  @moduledoc """
  处理L2在特殊区块上的逻辑
  """

  require Logger

  alias Indexer.Fetcher.PlatonAppchain
  alias Indexer.Fetcher.PlatonAppchain.Contracts.{L2StakeHandler,L2RewardManager}
  alias Indexer.Fetcher.PlatonAppchain.L2ValidatorService

  @period_type [round: 1, epoch: 2]

  # 返回 l2_block_produced_statistic_list，格式如下：
  # [
  #	%{
  #		round: round,
  #		validator_hash: item.validator_hash,
  #		should_blocks: PlatonAppchain.l2_round_size_per_validator(),
  #		actual_blocks: item.actual_blocks,
  #	}
  #]
  def inspect(blocks) when is_list(blocks) do
    round_end_blocks = Enum.filter(blocks, fn block -> PlatonAppchain.is_round_end_block(block.number) == true end)

    l2_block_produced_statistic_list =
      round_end_blocks
      |> Enum.reduce(round_end_blocks, [], fn block,acc ->
        acc ++ get_l2_block_produced_statistic(block)
      end)

    epoch_begin_blocks = Enum.filter(blocks, fn block -> PlatonAppchain.is_epoch_begin_block(block.number) == true end)

    if epoch_begin_blocks != nil do
      max_epoch_begin_block = Enum.take(epoch_begin_blocks, -1)

      L2ValidatorService.reset_active_validators(max_epoch_begin_block)

      # 结算周期结束，会重新选举201名单
      # 添加成功通过ws给前端发消息 begin，以便前端更新验证人列表
      Endpoint.broadcast("platon_appchain_l2_validator:all_validator", "all_validator", 1)
      # 添加成功通过ws给前端发消息 end
    end

    l2_block_produced_statistic_list
  end

  # 共识周期结束，调用底层rpc，得到此共识周期，每个验证人实际出块数，再加上配置的应该出块数，就可以算出每个验证人的出块率。
  # 如果一个验证人的出库数是0，底层也会返回。
  # 去掉重复的，如果有重复的，在upsert的时候，PGSql 会发生错误：ON CONFLICT DO UPDATE command cannot affect row a second time
  # 实际上，在blockscout的所有importer中，因为是同一个事务中，所以都应该避免import的数据中有重复的。
  # 这个只是在测试时get_l2_block_produced_statistic_if_round_end_block/1方法去掉是否是共识周期结束块的判断时，才会出现重复数据，此时，需要去重。
  # Enum.uniq_by(statis, fn elem -> {elem.validator_hash, elem.round} end)
  # 返回list[map()]
  defp get_l2_block_produced_statistic(block) do
    round = PlatonAppchain.calculateL2Round(block.number)
    blocks_of_validator_list = L2StakeHandler.getBlocksOfValidators(@period_type[:round], round)

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
