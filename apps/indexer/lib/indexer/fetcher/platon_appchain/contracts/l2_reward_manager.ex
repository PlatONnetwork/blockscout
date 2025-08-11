defmodule Indexer.Fetcher.PlatonAppchain.Contracts.L2RewardManager do
  @moduledoc """
  L2 reward manager contract interface encapsulation
  """
  alias Ethers
  # use Ethers.Contract, abi_file: "config/abi/L2_RewardManager.json", default_address: System.get_env("INDEXER_PLATON_APPCHAIN_L2_REWARD_MANAGER_CONTRACT")
  use Ethers.Contract, abi_file: "config/abi/L2_RewardManager.json"
  defp l2RewardManagerContract() do
    System.get_env("INDEXER_PLATON_APPCHAIN_L2_REWARD_MANAGER_CONTRACT")
  end

  # @rpc_opts [url: System.get_env("ETHEREUM_JSONRPC_HTTP_URL"), http_headers: [{"Content-Type", "application/json"}]]
  defp rpc_opts() do
    [url: System.get_env("ETHEREUM_JSONRPC_HTTP_URL"), http_headers: [{"Content-Type", "application/json"}]]
  end


  @doc """
  Query the total reward (epoch reward and blocks reward) paid for the given epoch

  ## Parameters
    * `epochId`(integer) - epoch id

  ## Returns
    * the total reward (epoch reward and blocks reward) paid for the given epoch
  """
  def paidRewardPerEpoch(epochId) do
    result = paid_reward_per_epoch(epochId) |> Ethers.call(to: l2RewardManagerContract(), rpc_opts: rpc_opts())
    {:ok, paidReward} = result
    paidReward
  end

  @doc """
  Query the pending reward for the given account(validator)

  ## Parameters
    * `validator`(address) - addr of validator

  ## Returns
    * Pending reward for the given account(validator)
  """
  def pendingValidatorRewards(validator) do
    result = pending_validator_rewards(validator) |> Ethers.call(to: l2RewardManagerContract(), rpc_opts: rpc_opts())
    {:ok, pendingRewards} = result
    pendingRewards
  end

  @doc """
  Query the pending reward of delegator for the given account(validator)

  ## Parameters
    * `validator`(address) - addr of validators
    * `delegator`(address) - addr of delegator

  ## Returns
    * Pending reward of delegator for the given account(validator)
  """
  def pendingDelegatorRewards(validator, delegator) do
    result = pending_delegator_rewards(validator, delegator) |> Ethers.call(to: l2RewardManagerContract(), rpc_opts: rpc_opts())
    {:ok, pendingRewards} = result
    pendingRewards
  end
end
