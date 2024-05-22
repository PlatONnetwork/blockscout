defmodule BlockScoutWeb.API.V2.StatsController do
  use Phoenix.Controller

  alias BlockScoutWeb.API.V2.Helper
  alias BlockScoutWeb.Chain.MarketHistoryChartController
  alias Explorer.{Chain, Market}
  alias Explorer.Chain.Address.Counters
  alias Explorer.Chain.Cache.Block, as: BlockCache
  alias Explorer.Chain.Cache.{GasPriceOracle, GasUsage}
  alias Explorer.Chain.Cache.Transaction, as: TransactionCache
  alias Explorer.Chain.Supply.RSK
  alias Explorer.Chain.Transaction.History.TransactionStats
  alias Explorer.Counters.AverageBlockTime
  alias Plug.Conn
  alias Timex.Duration
  alias Explorer.Chain.PlatonAppchain
  alias Explorer.Chain.PlatonAppchain.L2Validator

  @api_true [api?: true]

  def stats(conn, _params) do
    market_cap_type =
      case Application.get_env(:explorer, :supply) do
        RSK ->
          RSK

        _ ->
          :standard
      end

    exchange_rate = Market.get_coin_exchange_rate()
    secondary_coin_exchange_rate = Market.get_secondary_coin_exchange_rate()

    transaction_stats = Helper.get_transaction_stats()

    gas_prices =
      case GasPriceOracle.get_gas_prices() do
        {:ok, gas_prices} ->
          gas_prices

        _ ->
          nil
      end

    coin_price_change =
      case Market.fetch_recent_history() do
        [_today, yesterday | _] ->
          exchange_rate.usd_value && yesterday.closing_price &&
            exchange_rate.usd_value
            |> Decimal.div(yesterday.closing_price)
            |> Decimal.sub(1)
            |> Decimal.mult(100)
            |> Decimal.to_float()
            |> Float.ceil(2)

        _ ->
          nil
      end

    gas_price = Application.get_env(:block_scout_web, :gas_price)

    json(
      conn,
      %{
        "total_blocks" => BlockCache.estimated_count() |> to_string(),
        "total_addresses" => @api_true |> Counters.address_estimated_count() |> to_string(),
        "total_transactions" => TransactionCache.estimated_count() |> to_string(),
        "average_block_time" => AverageBlockTime.average_block_time() |> Duration.to_milliseconds(),
        "coin_image" => exchange_rate.image_url,
        "coin_price" => exchange_rate.usd_value,
        "coin_price_change_percentage" => coin_price_change,
        "secondary_coin_price" => secondary_coin_exchange_rate.usd_value,
        "total_gas_used" => GasUsage.total() |> to_string(),
        "transactions_today" => Enum.at(transaction_stats, 0).number_of_transactions |> to_string(),
        "gas_used_today" => Enum.at(transaction_stats, 0).gas_used,
        "gas_prices" => gas_prices,
        "gas_prices_update_in" => GasPriceOracle.update_in(),
        "gas_price_updated_at" => GasPriceOracle.get_updated_at(),
        "static_gas_price" => gas_price,
        "market_cap" => Helper.market_cap(market_cap_type, exchange_rate),
        "tvl" => exchange_rate.tvl_usd,
        "network_utilization_percentage" => network_utilization_percentage()
      }
      |> add_chain_type_fields()
      |> backward_compatibility(conn)
      |> add_stats_platon_appchain()
    )
  end

  defp network_utilization_percentage do
    {gas_used, gas_limit} =
      Enum.reduce(Chain.list_blocks(), {Decimal.new(0), Decimal.new(0)}, fn block, {gas_used, gas_limit} ->
        {Decimal.add(gas_used, block.gas_used), Decimal.add(gas_limit, block.gas_limit)}
      end)

    if Decimal.compare(gas_limit, 0) == :eq,
      do: 0,
      else: gas_used |> Decimal.div(gas_limit) |> Decimal.mult(100) |> Decimal.to_float()
  end

  def transactions_chart(conn, _params) do
    [{:history_size, history_size}] =
      Application.get_env(:block_scout_web, BlockScoutWeb.Chain.TransactionHistoryChartController, [{:history_size, 30}])

    today = Date.utc_today()
    latest = Date.add(today, -1)
    earliest = Date.add(latest, -1 * history_size)

    date_range = TransactionStats.by_date_range(earliest, latest, @api_true)

    transaction_history_data =
      date_range
      |> Enum.map(fn row ->
        %{date: row.date, tx_count: row.number_of_transactions}
      end)

    json(conn, %{
      chart_data: transaction_history_data
    })
  end

  def market_chart(conn, _params) do
    exchange_rate = Market.get_coin_exchange_rate()

    recent_market_history = Market.fetch_recent_history()
    current_total_supply = MarketHistoryChartController.available_supply(Chain.supply_for_days(), exchange_rate)

    price_history_data =
      recent_market_history
      |> case do
        [today | the_rest] ->
          [
            %{
              today
              | closing_price: exchange_rate.usd_value
            }
            | the_rest
          ]

        data ->
          data
      end
      |> Enum.map(fn day -> Map.take(day, [:closing_price, :market_cap, :tvl, :date]) end)

    market_history_data =
      MarketHistoryChartController.encode_market_history_data(price_history_data, current_total_supply)

    json(conn, %{
      chart_data: market_history_data,
      # todo: remove when new frontend is ready to use data from chart_data property only
      available_supply: current_total_supply
    })
  end

  def secondary_coin_market_chart(conn, _params) do
    recent_market_history = Market.fetch_recent_history(true)

    chart_data =
      recent_market_history
      |> Enum.map(fn day -> Map.take(day, [:closing_price, :date]) end)

    json(conn, %{
      chart_data: chart_data
    })
  end

  defp backward_compatibility(response, conn) do
    case Conn.get_req_header(conn, "updated-gas-oracle") do
      ["true"] ->
        response

      _ ->
        response
        |> Map.update("gas_prices", nil, fn
          gas_prices ->
            %{slow: gas_prices[:slow][:price], average: gas_prices[:average][:price], fast: gas_prices[:fast][:price]}
        end)
    end
  end

  case Application.compile_env(:explorer, :chain_type) do
    :rsk ->
      defp add_chain_type_fields(response) do
        alias Explorer.Chain.Cache.RootstockLockedBTC

        case RootstockLockedBTC.get_locked_value() do
          rootstock_locked_btc when not is_nil(rootstock_locked_btc) ->
            response |> Map.put("rootstock_locked_btc", rootstock_locked_btc)

          _ ->
            response
        end
      end

    "optimism" ->
      defp add_chain_type_fields(response) do
        import Explorer.Counters.LastOutputRootSizeCounter, only: [fetch: 1]
        response |> Map.put("last_output_root_size", fetch(@api_true))
      end

    _ ->
      defp add_chain_type_fields(response), do: response
  end


  defp add_stats_platon_appchain(stats) do
    if System.get_env("CHAIN_TYPE") == "platon_appchain" do
      # 获取token总供应量
      token_contract_address =  System.get_env("INDEXER_PLATON_APPCHAIN_L1_TOKEN_CONTRACT")
      l1_rpc =  System.get_env("INDEXER_PLATON_APPCHAIN_L1_RPC")
      tx_data = Ethers.Contracts.ERC20.total_supply()
      {:ok, total_supply} = Ethers.call(tx_data, to: token_contract_address, rpc_opts: [url: l1_rpc])
      stats = stats |> Map.put("total_supply", Integer.to_string(total_supply))

      # 获取总质押量及验证人数
      %{total_staked: total_assets_staked, validator_count: validator_count}  = L2Validator.statistics_validators()
      stats = stats |> Map.put("validator_count", validator_count)
      stats = stats |> Map.put("total_assets_staked", total_assets_staked)

      # 计算质押率
      case  get_excitation_balance() do
        {:ok, excitation_balance} ->
          liq_balance =  Decimal.sub(Decimal.new(total_supply), excitation_balance)
          staked_rate = Decimal.div(total_assets_staked,liq_balance) |> Decimal.mult(100)   # |> Decimal.to_float()
          stats = stats |> Map.put("staked_rate", staked_rate)
        _-> stats = stats |> Map.put("staked_rate", nil)
      end

      # 下个checkpoint批次所在区块(取block表最大区块进行计算)
      %{block_number: block_number_value} = Chain.get_max_block_number()
      next_l2_state_batch_block = next_l2_round_block_number(block_number_value)
      stats = stats |> Map.put("next_l2_state_batch_block", next_l2_state_batch_block)

    else
      stats
    end
  end

  # 激励池余额
  def get_excitation_balance() do
    json_rpc_named_arguments = json_rpc_named_arguments(System.get_env("ETHEREUM_JSONRPC_HTTP_URL"))
    l2_reward_manager_contract = json_rpc_named_arguments(System.get_env("INDEXER_PLATON_APPCHAIN_L2_REWARD_MANAGER_CONTRACT"))
    address_balances = EthereumJSONRPC.fetch_balances([%{block_quantity: "latest", hash_data: l2_reward_manager_contract}], json_rpc_named_arguments)
    balance =  case address_balances do
      {:ok, %EthereumJSONRPC.FetchedBalances{params_list: [%{address_hash: address_hash_value, block_number: block_number_value, value: balance}]}} -> {:ok,Decimal.new(balance)}
      _-> {:error, nil}
    end
  end

  def next_l2_round_block_number(current_block_number) do
    l2_round_size = String.to_integer(System.get_env("INDEXER_PLATON_APPCHAIN_L2_ROUND_SIZE") || 250)
    next_round = calculateL2Round(current_block_number, l2_round_size)
    next_round * l2_round_size + 1
  end

  def calculateL2Round(current_block_number, round_size) do
    if rem(current_block_number,round_size)==0 do
      div(current_block_number, round_size)
    else
      div(current_block_number, round_size) + 1
    end
  end

  # 返回 JSON rpc 请求时的参数
  def json_rpc_named_arguments(rpc_url) do
    [
      transport: EthereumJSONRPC.HTTP,
      transport_options: [
        http: EthereumJSONRPC.HTTP.HTTPoison,
        url: rpc_url,
        http_options: [
          recv_timeout: :timer.minutes(10),
          timeout: :timer.minutes(10),
          hackney: [pool: :ethereum_jsonrpc]
        ]
      ]
    ]
  end
end
