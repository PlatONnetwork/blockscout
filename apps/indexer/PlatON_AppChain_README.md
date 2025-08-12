### 注意点
- PlatON的block无需reorg，也没有safe_block概念。
- 为了和ether的rpc接口兼容，PlatON需要提供eth_blockNumber中参数为："safe"的支持(和"latest"等效)
- 连接的L2节点，需要是归档节点，以便支持RPC接口：debug_traceTransaction

### INDEXER_PLATON_APPCHAIN_L2_START_BLOCK，INDEXER_PLATON_APPCHAIN_L1_START_BLOCK参数配置说明
- 系统初次运行时，这两个参数可以配置为：1
- 系统停止后重启，理论上，有两种方法配置此参数：目前应用链采用的是第二种方法。
1. INDEXER_PLATON_APPCHAIN_L2_START_BLOCK重置为表blocks中获取最大区块+1；INDEXER_PLATON_APPCHAIN_L1_START_BLOCK重置为(l1_events,l1_executes,checkpoints)表最大区块+1
2. 保持参数的设置为1，有每个fetcher自己查询各自表里最大区块号+1，作为继续获取历史区块数据库的起始区块号。

### L1事件的监听处理
l1_event.ex, l1_execute, checkpoint.ex，既需要获取L1上从INDEXER_PLATON_APPCHAIN_L1_START_BLOCK开始的历史区块的事件，也要赋值获取新区块的相关事件。
这个是有l1_event.ex, l1_execute, checkpoint.ex中通过消息:continue来循环完成的。

### L2事件的监听处理
##### 历史区块事件
由apps/indexer/lib/indexer/fetcher/platon_appchain.ex来启动各个子模块的的fetcehr，如：indexer/fetcher/platon_appchain/l2_event.ex, l2_execute.ex, l2_validator_event.ex, commitment.ex来完成的，
当历史区块处理完成后，这些fetcher将stop。
调用链，比如：
apps/indexer/lib/indexer/fetcher/platon_appchain.ex # fill_block_range() -> apps/indexer/lib/indexer/fetcher/platon_appchain/l2_validator_event.ex # find_and_save_entities()，此方法调用 Chain.import()完成数据导入
其他子模块类似：
apps/indexer/lib/indexer/fetcher/platon_appchain.ex # fill_block_range() -> apps/indexer/lib/indexer/fetcher/platon_appchain/l2_event.ex # find_and_save_entities()，此方法调用 Chain.import()完成数据导入


Chain.import()，会调用比如：
apps/explorer/lib/explorer/chain/import/runner/platon_appchain/l2_validator_events.ex实现的@impl Import.Runner run方法来完成导入数据，同时，会更新表：L2_validators数据，因为L2_validators数据，实际上是由表：L2_validator_event数据决定

##### 新区块事件
是有 indexer/block/fetcher.ex来实时处理的，

调用链： apps/indexer/lib/indexer/block/fetcher.ex#fetch_and_import_range() - >
    apps/indexer/lib/indexer/transform/platon_appchain/l2_validator_events.ex:15 # parse() ->  apps/indexer/lib/indexer/transform/platon_appchain/l2_validator_events.ex # event_to_l2_validator_events
    apps/indexer/lib/indexer/transform/platon_appchain/l2_events.ex:15 # parse() ->  apps/indexer/lib/indexer/transform/platon_appchain/l2_events.ex # event_to_l2_event()
    apps/indexer/lib/indexer/transform/platon_appchain/l2_executes.ex:15 # parse() ->  apps/indexer/lib/indexer/transform/platon_appchain/l2_execute.ex # event_to_l2_execute()
    apps/indexer/lib/indexer/transform/platon_appchain/l2_reward_events.ex:15 # parse() ->  apps/indexer/lib/indexer/transform/platon_appchain/l2_reward_event.ex # event_to_l2_reward_event()
    apps/indexer/lib/indexer/transform/platon_appchain/commitments.ex:15 # parse() ->  apps/indexer/lib/indexer/transform/platon_appchain/commitment.ex # event_to_commitment()

最后由indexer/block/fetcher.ex的 __MODULE__.import()方法来更新数据，会调用每个模块的@impl Import.Runner run来导入数据？（应该是的），比如会调用：apps/explorer/lib/explorer/chain/import/runner/platon_appchain/l2_validator_events.ex:run(Multi.t(), list(), map()) :: Multi.t()来来导入:L2_validator_event数据 l2_validators数据


##### 数据导入
表：L2_validator_events数据更新：
1. 由 apps/explorer/lib/explorer/chain/import/runner/platon_appchain/l2_validator_events.ex实现的@impl Import.Runner run方法来完成导入数据，同时，会更新表：L2_validators数据，因为L2_validators数据，实际上是由表：L2_validator_event数据决定

其他表： L2_events / l2_executes  / commitments 类似过程，但是他们只处理一个表数据而已。




