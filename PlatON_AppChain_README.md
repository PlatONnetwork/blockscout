<h1 align="center">PlatON AppChain</h1>
<p align="center">Blockchain Explorer for PlatON App Chains based on Blockscout.</p>



## Env for PlatON AppChain

```shell
# L2 RPC客户端类型
export ETHEREUM_JSONRPC_VARIANT=geth
# L2 RPC url
export ETHEREUM_JSONRPC_HTTP_URL="http://192.168.9.82:8801"
# L1 RPC url
export INDEXER_PLATON_APPCHAIN_L1_RPC="http://192.168.9.81:8801"

# 链类型/链名称
export CHAIN_TYPE="platon_appchain"

# 同步 L1 链上数据时，起始块高
export INDEXER_PLATON_APPCHAIN_L1_START_BLOCK=1

# L1 链上的质押/委托合约地址
export INDEXER_PLATON_APPCHAIN_L1_STAKE_MANAGER_CONTRACT="0xB04B468EB388C613cb453A60f6d610A009E1Ff55"

# L1 链上的质押/委托状态同步合约地址
export INDEXER_PLATON_APPCHAIN_L1_STATE_SENDER_CONTRACT="0x92b68E65Ef272afA1B8F001501D17F13B836E735"

# L1 链上的接收 L1 上质押/委托信息的合约地址
export INDEXER_PLATON_APPCHAIN_L1_EXIT_HELPER_CONTRACT="0x7B66bf9dAba52733231e32D3e2fe1008205c1458"

# L1 链上的处理 L2 提交的checkpoint交易的合约地址
export INDEXER_PLATON_APPCHAIN_L1_CHECKPOINT_MANAGER_CONTRACT="0x0bb7AC917fA06100cDfF38641E6c2C6Bae4F4890"

# 同步 L2 链上数据时，起始块高
export INDEXER_PLATON_APPCHAIN_L2_START_BLOCK=1

# L2 链上内置质押/委托合约地址
export INDEXER_PLATON_APPCHAIN_L2_STAKE_HANDLER_CONTRACT="0x1000000000000000000000000000000000000005"

# L2 链上内置质押/委托奖励管理合约地址
export INDEXER_PLATON_APPCHAIN_L2_REWARD_MANAGER_CONTRACT="0x1000000000000000000000000000000000000006"

# L2 链上的质押/委托状态同步合约地址
export INDEXER_PLATON_APPCHAIN_L2_STATE_SENDER_CONTRACT="0x1000000000000000000000000000000000000001"

# L2 链上的内置合约，接收处理 L1质押/委托信息
export INDEXER_PLATON_APPCHAIN_L2_STATE_RECEIVER_CONTRACT="0x1000000000000000000000000000000000000002"

# L2 链上每个共识周期的区块数
export INDEXER_PLATON_APPCHAIN_L2_ROUND_SIZE=250

# L2 链上每个结算周期的区块数
export INDEXER_PLATON_APPCHAIN_L2_EPOCH_SIZE=500

# L2 链上每个共识周期每个验证人应该出块数
export INDEXER_PLATON_APPCHAIN_L2_ROUND_SIZE_PER_VALIDATOR=10

# 应用的数据库连接
export DATABASE_URL=postgresql://dev_user:123456@10.2.10.22:5432/platon_appchain

# 数据库连接池数
export POOL_SIZE=100

# L2 链的trace url
export ETHEREUM_JSONRPC_TRACE_URL="http://192.168.9.82:8801"

# L2 链的rpc协议类型
export ETHEREUM_JSONRPC_TRANSPORT=http

# 如果为 "true"，则忽略所有使用 eth_getBalance 方法（参数为任何区块，但不包括最新区块：latest）发出的请求
export ETHEREUM_JSONRPC_DISABLE_ARCHIVE_BALANCES=false

# Blockscout 版本
export BLOCKSCOUT_VERSION=v6.5.0-beta

# L2 给出块验证人的出块奖励，这个奖励不分配给委托人。(platon的出块奖励+质押奖励，一起参与分配)
export INDEXER_PLATON_APPCHAIN_L2_BLOCK_REWARD=4000000000000000000

# L2 撤销委托后被锁定的结算周期数
export INDEXER_PLATON_APPCHAIN_L2_EPOCHS_FOR_LOCKING_UNDELEGATION=6

# 提供 L2 市值数据的第三方服务：coin_market_cap 
export EXCHANGE_RATES_MARKET_CAP_SOURCE="coin_market_cap"

# 提供 L2 加个的第三方服务：coin_market_cap 
export EXCHANGE_RATES_PRICE_SOURCE="coin_market_cap"

# 调用coin_market_cap的api的私钥，需要coin_market_cap官网注册
export EXCHANGE_RATES_COINMARKETCAP_API_KEY="0b277714-442e-4e4e-85cb-d058bbdc0337"

# coin_market_cap定义的token id（目前用LAT的ID），后面要换成应用链的原生token
export EXCHANGE_RATES_COINMARKETCAP_COIN_ID=9720

# L2 TOKEN名称
export EXCHANGE_RATES_COIN="LAT"

# 调用第三方服务：coin_market_cap API 可能需要的代理
export EXCHANGE_RATES_PROXY="http://127.0.0.1:7890"

# Disables or enables fetching of coin price from Coingecko API.
export DISABLE_EXCHANGE_RATES=false
```
