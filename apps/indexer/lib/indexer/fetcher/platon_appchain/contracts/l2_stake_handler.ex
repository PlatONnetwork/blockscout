defmodule Indexer.Fetcher.PlatonAppchain.Contracts.L2StakeHandler do
  @moduledoc """
  Stake handler contract interface encapsulation
  """
  alias Ethers
  alias Explorer.Chain.{Hash}
  require Logger


  # use Ethers.Contract, abi_file: "config/abi/L2_StakeHandler.json", default_address:  System.get_env("INDEXER_PLATON_APPCHAIN_L2_STAKE_HANDLER_CONTRACT")
  use Ethers.Contract, abi_file: "config/abi/L2_StakeHandler.json"
  defp l2StakeHandlerContract() do
    System.get_env("INDEXER_PLATON_APPCHAIN_L2_STAKE_HANDLER_CONTRACT")
  end

  # @rpc_opts [url: System.get_env("ETHEREUM_JSONRPC_HTTP_URL"), http_headers: [{"Content-Type", "application/json"}]]
  defp rpc_opts() do
    [url: System.get_env("ETHEREUM_JSONRPC_HTTP_URL"), http_headers: [{"Content-Type", "application/json"}]]
  end

  @default_size 10

  defp convertValidatorToJSON(validator) do
    data = %{
      validator_hash: elem(validator, 0),
      owner_hash: elem(validator, 1),
      stake_amount: elem(validator, 2),
      delegate_amount: elem(validator, 3),
      commission_rate: elem(validator, 4),
      status: elem(validator, 5),
      stake_epoch: elem(validator, 6)
      #stakeIndex: elem(validator, 7),
      #pubKey: Base.encode16(elem(validator, 8)),
      #blsKey: Base.encode16(elem(validator, 9))
    }
    data
  end

  defp convertDelegationToJSON(delegation) do
    data = %{
      validator_hash: elem(delegation, 0),
      delegator_hash:  elem(delegation, 1),
      delegate_amount: elem(delegation, 2)
      #delegate_amount: elem(delegation, 3),
      #delegateEpoch: elem(delegation, 4),
    }
    data
  end

  @doc """
  Query the list of all validators, Support pagination to query the list of all validators

  ## Parameters
    * `start`(bytes) - represents the starting query ID. When passing empty bytes, it defaults to starting from the first Id
    * `size`(integer) - page size

  ## Returns
    * bytes of next start
    * ValidatorInfo array for query

  ## Examples
     {"7072696F7269747956616C696461746F7200000000000000000000000000FFFFFFFFFFFFFFFFFFC46535FF00000000000000010000000000000002",
  [
   %{
     "blsKey" => "828B858EAB99526F901CE610AE3D2D9B08F2302E56A29698776D2135E94FC074C575A53E27B8A68E9A7692F3BE65965A",
     "commissionRate" => 100,
     "delegateAmount" => 10000,
     "epoch" => 1,
     "owner" => "0x70d207c1322ccb9069d3790d6768866dabff1035",
     "pubKey" => "8D84E41F83E833F622C45766E7E425CF03A225867FACB05BAF90EAF29C1BF53680988DAB4E6F058759871C91B3E6FF888AABC41DAEC4B8E0877FC8FE8FEED27F",
     "stakeAmount" => 1000000000,
     "stakeIndex" => 1,
     "status" => 0,
     "validatorAddr" => "0x70d207c1322ccb9069d3790d6768866dabff1035"
   },
   %{
     "blsKey" => "B6F85C577FF890F9737595A9E326D5539CC1CC859C879017CF25ACCEF8A96518EC9747EF621625063DC17AE95300A74F",
     "commissionRate" => 100,
     "delegateAmount" => 0,
     "epoch" => 1,
     "owner" => "0x70d207c1322ccb9069d3790d6768866dabff1035",
     "pubKey" => "5C79BF8B836BDC85FE513A64A558291E96AC2405B6B95D5CA05BB20DB9C0A1A00E12D11DD540D8685267015CE71CEF43781A75157EC6F266CC88A8FB8B5C6C17",
     "stakeAmount" => 1000000000,
     "stakeIndex" => 0,
     "status" => 0,
     "validatorAddr" => "0x1dd26dfb60b996fd5d5152af723949971d9119ee"
   }
  ]}
  """
  @spec getAllValidators(non_neg_integer(), non_neg_integer()) :: {list()}
  def getValidators(start \\ <<>>, size \\ @default_size) do
    # 将会调用config/abi/L2_StakeHandler.json中的方法，getValidators

    toAddress = System.get_env("INDEXER_PLATON_APPCHAIN_L2_STAKE_HANDLER_CONTRACT")
    Logger.debug(fn -> "getValidators L2 stake contract: #{toAddress}" end,logger: :platon_appchain)
    Logger.error(fn -> "getValidators L2 stake contract: #{toAddress}" end,logger: :platon_appchain)

    result = get_validators(start, size) |> Ethers.call(to: l2StakeHandlerContract(), rpc_opts: rpc_opts())

    Logger.debug(fn -> "getValidators result: #{inspect(result)}" end,logger: :platon_appchain)
    Logger.error(fn -> "getValidators result: #{inspect(result)}" end,logger: :platon_appchain)

    {:ok, data} = result
    # Logger.debug(fn -> "getValidators: #{inspect(data)}" end , logger: :platon_appchain)
    [nextStart | validators] = data
    validatorsJson = List.first(validators) |> Enum.map(fn validator -> convertValidatorToJSON(validator) end)
    {Base.encode16(nextStart), validatorsJson}
  end

  @doc """
  Query the list of all validators, Support pagination to query the list of all validators

  ## Parameters
    * `all`(array of validator info) - Array to save all validator info。用于递归调用传递结果数据
    * `start`(bytes) - Represents the starting query ID. When passing empty bytes, it defaults to starting from the first Id, default is <<>>
    * `size`(integer) - Use this paging value to continuously obtain the loop calling interface until all data is obtained. default is 10

  ## Returns
    * All Validator Info array for query
  """
  @spec getAllValidators(list(), non_neg_integer(), non_neg_integer()) :: {list()}
  def getAllValidators(all \\ [], start \\ <<>>, size \\ @default_size) do
    if size == 0 do
      all
    else
      {nextStart, validators} = getValidators(start, size)
      all = all ++ validators
      getAllValidators(all, Base.decode16!(nextStart), length(validators))
    end
  end

  @doc """
  Query the list of validators by addrs。Support to query the list of validators by addr of validators

  ## Parameters
    * `validators`(address[]) - addr of validators

  ## Returns
    * ValidatorInfo array for query

  ## Examples
    [
  %{
    "blsKey" => "828B858EAB99526F901CE610AE3D2D9B08F2302E56A29698776D2135E94FC074C575A53E27B8A68E9A7692F3BE65965A",
    "commissionRate" => 100,
    "delegateAmount" => 10000,
    "epoch" => 1,
    "owner" => "0x70d207c1322ccb9069d3790d6768866dabff1035",
    "pubKey" => "8D84E41F83E833F622C45766E7E425CF03A225867FACB05BAF90EAF29C1BF53680988DAB4E6F058759871C91B3E6FF888AABC41DAEC4B8E0877FC8FE8FEED27F",
    "stakeAmount" => 1000000000,
    "stakeIndex" => 1,
    "status" => 0,
    "validatorAddr" => "0x70d207c1322ccb9069d3790d6768866dabff1035"
  }
  ]
  """
  @spec getValidatorsWithAddr(list(String.t()), non_neg_integer) :: map()
  def getValidatorsWithAddr(validator_addresses, block_number) do
    # 将会调用config/abi/L2_StakeHandler.json中的方法，getValidatorsWithAddr
    result = get_validators_with_addr(validator_addresses) |> Ethers.call(to: l2StakeHandlerContract(), rpc_opts: [block_number: block_number] ++ rpc_opts())
    {:ok, validators} = result
    validatorsJson = validators |> Enum.map(fn validator -> convertValidatorToJSON(validator) end)
    validatorsJson
  end

  @doc """
        iex> getValidator("0x97ab3d4f7f5051f127b0e9f8d10772125d94d65b")
        %{commission_rate: 80,
          delegate_amount: 0,
          owner_hash: "0x97ab3d4f7f5051f127b0e9f8d10772125d94d65b",
          stake_amount: 1000000000,
          stake_epoch: 4,
          status: 0,
          validator_hash: "0x97ab3d4f7f5051f127b0e9f8d10772125d94d65b"
        }
  """
  @spec getValidator(String.t(), non_neg_integer) :: map()
  def getValidator(validator_hex, block_number) do
    # 将会调用config/abi/L2_StakeHandler.json中的方法，getValidatorsWithAddr
    result = get_validators_with_addr([validator_hex]) |> Ethers.call(to: l2StakeHandlerContract(), rpc_opts: [block: block_number] ++ rpc_opts())
    {:ok, validators} = result

    Logger.info("getValidator result: #{inspect(validators)}")
    if length(validators) > 0 do
      convertValidatorToJSON(List.first(validators))
    else
      %{}
    end

  end


  @doc """
  Query the list of validators for a certain period。For the convenience of expanding the list of validators with multiple period properties

  ## Parameters
    * `periodType`(integer) - represents a period of a certain type
     1: round: from 1; 如果是0表示创始块中的数据
     2: epoch: from 1; 如果是0表示创始块中的数据
    * `period`(integer) - represents the number of intervals

  ## Returns
    * validator address array

  ## Examples
    ["0x1dd26dfb60b996fd5d5152af723949971d9119ee","0x70d207c1322ccb9069d3790d6768866dabff1035","0x343972bf63d1062761aaaa891d2750f03cb4b2f7"]
  """
  @spec getValidatorAddrs(non_neg_integer(), non_neg_integer()) :: {list()}
  def getValidatorAddrs(periodType, period) do
    # 将会调用config/abi/L2_StakeHandler.json中的方法，getValidatorAddrs
    result = get_validator_addrs(periodType, period) |> Ethers.call(to: l2StakeHandlerContract(), rpc_opts: rpc_opts())
    {:ok, addrs} = result
    addrs
  end

  @doc """
  # 数据来源：
  #     当同步区块时，如果此区块是round结束块（根据规则计算是否是round结束块），则调用底层rpc接口，获取此round所有验证人的出块情况，并被每个验证人一个应出块数（通过配置），最后把数据import到此表。
  # 注意：
  #     如果此round某个验证人因为各种原因，没有出块，底层rpc接口的返回数据中，也会包括此验证人，实际出库数=0即可。
  """
  @spec getBlocksOfValidators(non_neg_integer(), non_neg_integer()) :: {list()}
  def getBlocksOfValidators(periodType, period) do
    # 返回
    # [
    #  {"0x343972bf63d1062761aaaa891d2750f03cb4b2f7", 90},
    #  {"0x1dd26dfb60b996fd5d5152af723949971d9119ee", 80},
    #  {"0x70d207c1322ccb9069d3790d6768866dabff1035", 80}
    # ]

    result = get_blocks_of_validators(periodType, period) |> Ethers.call(to: l2StakeHandlerContract(), rpc_opts: rpc_opts())
    case result do
      {:ok, blockProducedInfos} -> convertBlockProducedInfos(blockProducedInfos)
      _ -> []
    end
  end
  defp convertBlockProducedInfos(blockProducedInfos) do
    Enum.reduce(blockProducedInfos, [], fn eachItem, acc ->
      block_info = %{validator_hash: elem(eachItem, 0), actual_blocks: elem(eachItem, 1)}
      [block_info | acc] #后来的插入头部，效率高
    end)
    # |> Enum.reverse  #反转list
  end

  @doc """
  Query the delegation information of the delegator on these validators based on the addr list of validators

  ## Parameters
    * `validators`(address[]) - addr of validators
    * `delegator`(address) - the delegator

  ## Returns
    * DelegationInfo array for query

  ## Examples
   # [%{
   #      "amount" => 10000,
   #      "delegateEpoch" => 1395,
   #      "delegatorAddr:" => "0x62953f9213f899f2a51680c2fbb4282a2591bfc8",
   #      "stakeEpoch" => 1,
   #      "validatorAddr" => "0x70d207c1322ccb9069d3790d6768866dabff1035"
   #    }]
  """
  @spec getDelegationsWithValidator(list(), String.t()) :: {list()}
  def getDelegationsWithValidator(validators_hex, delegator_hex) do
    # 将会调用config/abi/L2_StakeHandler.json中的方法，getDelegationsWithValidator
    result =  get_delegations_with_validator(validators_hex, delegator_hex) |> Ethers.call(to: l2StakeHandlerContract(), rpc_opts: rpc_opts())
    {:ok, delegations} = result


    delegationJson = delegations |> Enum.map(fn delegation -> convertDelegationToJSON(delegation) end)

    #求总的委托金额
    totalDelegations = Enum.reduce(delegationJson, 0, fn item, acc -> acc + item.delegate_amount end)

    %{
      validator_hash: validators_hex,
      delegator_hash:  delegator_hex,
      delegate_amount: totalDelegations
    }

  end


  @doc """
  Query how much is yet to become withdrawable for account.

  ## Parameters
    * `validator`(address) - The validator to calculate amount for
    * `delegator`(address) - The delegator to calculate amount for

  ## Returns
    * Amount not yet withdrawable

  """
  @spec pendingWithdrawalsOfDelegate(String.t(), String.t()) :: {non_neg_integer()}
  def pendingWithdrawalsOfDelegate(validator_hex, delegator_hex) do
    # 将会调用config/abi/L2_StakeHandler.json中的方法，pendingWithdrawalsOfDelegate
    result = pending_withdrawals_of_delegate(validator_hex, delegator_hex) |> Ethers.call(to: l2StakeHandlerContract(), rpc_opts: rpc_opts())
    {:ok, pendingWithdrawals} = result
    pendingWithdrawals
  end

  @doc """
  Query how much is yet to become withdrawable for account.

  ## Parameters
    * `validator`(address) - The validator to calculate amount for

  ## Returns
    * Amount not yet withdrawable
  """
  @spec pendingWithdrawalsOfStake(String.t()) :: {non_neg_integer()}
  def pendingWithdrawalsOfStake(validator_hex) do
    # 将会调用config/abi/L2_StakeHandler.json中的方法，pendingWithdrawalsOfStake
    result = pending_withdrawals_of_stake(validator_hex) |> Ethers.call(to: l2StakeHandlerContract(), rpc_opts: rpc_opts())
    {:ok, pendingWithdrawals} = result
    pendingWithdrawals
  end

  @doc """
  Query how much can be withdrawn for account in this epoch.

  ## Parameters
    * `validator`(address) - The validator to calculate amount for
    * `delegator`(address) - The delegator to calculate amount for

  ## Returns
    * Amount withdrawable
  """
  @spec withdrawableOfDelegate(String.t(), String.t()) :: {non_neg_integer()}
  def withdrawableOfDelegate(validator_hex, delegator_hex) do
    # 将会调用config/abi/L2_StakeHandler.json中的方法，withdrawableOfDelegate
    result = withdrawable_of_delegate(validator_hex, delegator_hex) |> Ethers.call(to: l2StakeHandlerContract(), rpc_opts: rpc_opts())
    {:ok, withdrawable} = result
    withdrawable
  end

  @doc """
  Query how much can be withdrawn for account in this epoch.

  ## Parameters
    * `validator`(address) - The account to calculate amount for

  ## Returns
    * Amount withdrawable
  """
  @spec withdrawableOfStake(String.t()) :: {non_neg_integer()}
  def withdrawableOfStake(validator_hex) do
    # 将会调用config/abi/L2_StakeHandler.json中的方法，withdrawableOfStake
    result = withdrawable_of_stake(validator_hex) |> Ethers.call(to: l2StakeHandlerContract(), rpc_opts: rpc_opts())
    {:ok, withdrawable} = result
    withdrawable
  end

  @doc """
  查询委托人在验证节点上的委托信息，包括锁定委托，可领取委托，有效委托
  ## Parameters
  * `delegator_validator_pairs`(list()) - The account to calculate amount for
  [
    %{delegator_hash: "0x0101", validator_hash: "0x01"},
    %{delegator_hash: "0x0202", validator_hash: "0x01"},
    %{delegator_hash: "0x0202", validator_hash: "0x02"}
  ]
  ## Returns
  Examples:
    [
      %{delegator_hash: "0x0101", validator_hash: "0x01", withdrawal_delegate_amount: 100, locking_delegate_amount: 200, delegate_amount: 300},
      %{delegator_hash: "0x0202", validator_hash: "0x01", withdrawal_delegate_amount: 100, locking_delegate_amount: 200, delegate_amount: 300},
      %{delegator_hash: "0x0202", validator_hash: "0x02", withdrawal_delegate_amount: 100, locking_delegate_amount: 200, delegate_amount: 300}
    ]
  """
  @spec getDelegateDetails(list()) :: {list()}
  def getDelegateDetails(delegator_validator_pairs) do
    delegator_validator_pairs
    |> Enum.map(fn pair ->  getDelegatorDetails(pair.delegator_hash, pair.validator_hash) end)
  end

  defp getDelegatorDetails(delegator_hash, validator_hash) do
    Logger.info("getDelegatorDetails, delegator_hash: #{delegator_hash}")
    Logger.info("getDelegatorDetails, validator_hash: #{validator_hash}")
    delegator_hash_hex = Hash.to_string(delegator_hash)
    validator_hash_hex = Hash.to_string(validator_hash)

    withdrawal_delegate_amount = withdrawableOfDelegate(validator_hash_hex, delegator_hash_hex)
    locking_delegate_amount = pendingWithdrawalsOfDelegate(validator_hash_hex, delegator_hash_hex)
    delegation_info =  getDelegationsWithValidator([validator_hash_hex], delegator_hash_hex)
    %{delegator_hash: delegator_hash, validator_hash: validator_hash, withdrawal_delegate_amount: withdrawal_delegate_amount, locking_delegate_amount: locking_delegate_amount,  delegate_amount: delegation_info.delegate_amount}
  end

end
