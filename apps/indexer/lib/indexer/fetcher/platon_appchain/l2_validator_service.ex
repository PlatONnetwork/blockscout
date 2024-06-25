defmodule Indexer.Fetcher.PlatonAppchain.L2ValidatorService do
  @moduledoc """
  更新l2_validator表记录.
  """
  require Logger
  use Bitwise
  alias Indexer.Fetcher.PlatonAppchain.Contracts.L2StakeHandler
  alias Explorer.Chain
  alias Explorer.Chain.PlatonAppchain.L2Validator
  alias Indexer.Fetcher.PlatonAppchain


  @spec upsert_validator(Repo.t(), binary()) :: {:ok, integer()} | {:error, reason :: String.t()}
  def upsert_validator(repo, validator_hex) do
    validatorMap = L2StakeHandler.getValidator(validator_hex)
    L2Validator.upsert_validator(repo, validatorMap)
  end

  @spec update_validator_by_event(Repo.t(), map()) :: {:ok, integer()} | {:error, reason :: String.t()}
  def update_validator_by_event(repo, event) do
    validatorInfoMap = L2StakeHandler.getValidator(Hash.to_string(event.validator_hash))

    lock_block_number = PlatonAppchain.calculateBlockNumberAfterEpochs(event.block_number, PlatonAppchain.l2_epochs_for_locking_exit())

    exit_info =
      cond do
        PlatonAppchain.l2_validator_is_unstaked(validatorInfoMap.amount) ->  %{exit_block: event.block_number, lock_block: lock_block_number, exit_desc: "Unstaked"}
        PlatonAppchain.l2_validator_is_slashed(validatorInfoMap.status) ->  %{exit_block: event.block_number, lock_block: lock_block_number, exit_desc: "Slashing"}
        PlatonAppchain.l2_validator_is_duplicated(validatorInfoMap.status) ->  %{exit_block: event.block_number, lock_block: lock_block_number, exit_desc: "Duplicated"}
        PlatonAppchain.l2_validator_is_lowBlocks(validatorInfoMap.status) ->  %{exit_block: event.block_number, lock_block: lock_block_number, exit_desc: "LowBlocks"}
        PlatonAppchain.l2_validator_is_lowThreshold(validatorInfoMap.status) ->  %{exit_block: event.block_number, lock_block: lock_block_number, exit_desc: "LowThreshold"}
        true -> %{}
      end
    Map.merge(validatorInfoMap, exit_info)
    L2Validator.update_validator(repo, validatorInfoMap)
  end

  @spec increase_stake(binary(), integer()) :: {:ok, L2Validator.t()} | {:error, reason :: String.t()}
  def increase_stake(validator_hash, increment) do
    L2Validator.update_stake_amount(validator_hash, increment)
  end

  def decrease_stake(validator_hash, decrement) do
    L2Validator.update_stake_amount(validator_hash, 0-decrement)
  end


  def increase_delegation(validator_hash, increment) do
    L2Validator.update_delegate_amount(validator_hash, increment)
  end
  def decrease_delegation(validator_hash, decrement) do
    L2Validator.update_delegate_amount(validator_hash, 0-decrement)
  end

  # [{validator_hash, amount},{...}]
  def slash(slash_tuple_list) do
    L2Validator.slash(slash_tuple_list)
  end

#  def update_validator_status(validator_hash, current_status, block_number) do
#    cond do
#      PlatonAppchain.l2_validator_is_slashed(current_status) ->
#        L2Validator.update_status(validator_hash,  PlatonAppchain.l2_validator_status()[:Slashing])
#
#      PlatonAppchain.l2_validator_is_duplicated(current_status) ->
#        L2Validator.update_status(validator_hash,  PlatonAppchain.l2_validator_status()[:Duplicated])
#
#      PlatonAppchain.l2_validator_is_unstaked(current_status) ->
#        # 解质押，把节点信息从l2_validators表移动到l2_validator_historys表中，历史表中状态为：Unstaked
#        L2Validator.unstake(validator_hash, block_number, "", PlatonAppchain.l2_validator_status()[:Unstaked])
#
#      PlatonAppchain.l2_validator_is_lowBlocks(current_status) ->
#        L2Validator.update_status(validator_hash,  PlatonAppchain.l2_validator_status()[:LowBlocks])
#
#      PlatonAppchain.l2_validator_is_lowThreshold(current_status) ->
#        L2Validator.update_status(validator_hash,  PlatonAppchain.l2_validator_status()[:LowThreshold])
#     end
#  end

  # [{validator_hash, rank},{...}]
  def update_rank_and_amount(rank_tuple_list) do
     Logger.info(fn -> "update l2 validators rank: (#{inspect(rank_tuple_list)})" end,
       logger: :platon_appchain
     )
    L2Validator.update_rank_and_amount(rank_tuple_list)
  end

#  def backup_exited_validator(repo, validator_hash, status, exit_number, exit_desc) do
#    L2Validator.backup_exited_validator(repo, validator_hash, status, exit_number, exit_desc)
#  end
#
#  def delete_exited_validator(repo, validator_hash) do
#    L2Validator.delete_exited_validator(repo, validator_hash)
#  end


  # 验证人的角色：0-candidate(质押节点) 1-active(201共识节点后续人) 2-Consensus(43共识节点)， 参考：apps/indexer/lib/indexer/fetcher/platon_appchain.ex:72
  # 共识轮末，查询新的43共识节点，把原记录role=2的记录更新为role=1，根据新的43共识节点更新记录
  # 结算周期末（肯定也是某个共识周期末），查询新的43共识节点，查询新的大名单201，把原记录role=1 / 2的记录更新为role=0；更加新的201名单，更新记录；更加新的43名单，更新记录
#  def reset_validators_role(block_first..block_last) do
#    # 把区块号range倒过来。（因为要找最后一个符号条件的区块号）
#    block_number_desc_order =
#      Enum.to_list(block_first..block_last)
#      |> Enum.reverse()
#
#    # 找到符合条件的最大的区块号
#    last_epoch_end_block =  Enum.find(block_number_desc_order, fn block_number -> PlatonAppchain.is_epoch_end_block(block_number) end)
#    if last_epoch_end_block != nil do
#      last_epoch = PlatonAppchain.calculateL2Epoch(last_epoch_end_block)
#      active_list = L2StakeHandler.getValidatorAddrs(2, last_epoch) # 每个结算周期末，得到201大名单（共识节点候选节点）
#      L2Validator.reset_role_at_epoch_end(active_list)
#
#      # 添加成功通过ws给前端发消息 begin
#      Endpoint.broadcast("platon_appchain_l2_validator:all_validator", "all_validator", 1)
#      # 添加成功通过ws给前端发消息 end
#      {:ok, "add new validator(s) successfully"}
#
##      last_round = PlatonAppchain.calculateL2Round(last_epoch_end_block)
##      verifying_list = L2StakeHandler.getValidatorAddrs(1, last_round) # 每个共识周期末，得到43小名单（共识节点）
##      L2Validator.reset_role_at_epoch_end(active_list, verifying_list)
#    else
#      # 找到符合条件的最大的区块号
#      # 目前前端不需要展示43名单，端展示只需要展示201名单所以暂时不更新。也据是说，不会有 verifying 的角色
##      last_round_end_block = Enum.find(block_number_desc_order, fn block_number -> PlatonAppchain.is_round_end_block(block_number) end)
##       if last_round_end_block != nil do
##         last_round = PlatonAppchain.calculateL2Round(last_round_end_block)
##         consensus_list = L2StakeHandler.getValidatorAddrs(1, last_round)
##         L2Validator.reset_role_at_round_end(consensus_list)
##       end
#    end
#  end


  def reset_active_validators(epoch_begin_block) do
    epoch = PlatonAppchain.calculateL2Epoch(epoch_begin_block)
    active_validator_list = L2StakeHandler.getValidatorAddrs(2, epoch) # 每个结算周期末，得到201大名单（共识节点候选节点）
    L2Validator.reset_active_validators(active_validator_list)

    # 添加成功通过ws给前端发消息 begin
    Endpoint.broadcast("platon_appchain_l2_validator:all_validator", "all_validator", 1)
    # 添加成功通过ws给前端发消息 end
    {:ok, "add new validator(s) successfully"}
  end

end

