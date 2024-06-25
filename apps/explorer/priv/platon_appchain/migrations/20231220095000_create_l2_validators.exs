defmodule Explorer.Repo.PlatonAppchain.Migrations.CreateL2Validators do
  use Ecto.Migration

  def change do
    create table(:l2_validators, primary_key: false) do
      # 验证人地址, validator_hash
      add(:validator_hash, :bytea, null: false, primary_key: true)
      # 质押成为验证人的epoch，这个不需要作为主键的一部分，如果insert的时候发现validator_hash存在，说明就是新的质押，直接替换stake_epoch。旧的数据移动到history即可
      add(:stake_epoch, :bigint, null: false)
      # 验证人owner地址
      add(:owner_hash, :bytea, null: false)
      # commission_rate是底层链上保存的，40，表示40%，30表示30%
      # 拥金比例, 每个结算周期，每个验证人获得总奖励，首先按此CommissionRate扣除Commission，剩余的再按质押/委托金额比例分配。
      add(:commission_rate, :integer, null: true, default: 0)
      # 有效质押金额
      add(:stake_amount, :numeric, precision: 100, null: false, default: 0)
      # 锁定的质押金额
      add(:locking_stake_amount, :numeric, precision: 100, null: false, default: 0)
      # 可提取的质押金额
      add(:withdrawal_stake_amount, :numeric, precision: 100, null: false, default: 0)
      # 有效委托金额
      add(:delegate_amount, :numeric, precision: 100, null: false, default: 0)
      # 验证人已提取的奖励
      add(:withdrawn_reward, :numeric, precision: 100, null: false, default: 0)
      # 验证人可领取奖励（出块与质押）
      add(:stake_reward, :numeric, precision: 100, null: false, default: 0)
      # 委托奖励
      add(:delegate_reward, :numeric, precision: 100, null: false, default: 0)
      # 验证人可提取的金额
      add(:pending_validator_rewards, :numeric, precision: 100, null: false, default: 0)
      # 排名，获取所有质押节点返回的列表序号
      add(:rank, :integer, null: false, default: 0)
      # 验证人名称
      add(:name, :string, null: true)
      # 验证人描述信息
      add(:detail, :string, null: true)
      # 节点logo
      add(:logo, :text, null: true)
      # 验证人官方网站
      add(:website, :string, null: true)
      # 预估年收益率，万分之一单位,
      add(:expect_apr, :integer, null: true)
      # 最近24小时出块数
      add(:produced_blocks, :bigint, null: true)
      # 最近24小时出块率，万分之一单位,
      add(:block_rate, :integer, null: true)
      # 是否验证 0-未验证，1-已验证
      add(:auth_status, :integer, null: false, default: 0)
      # Invalided    ValidatorStatus = 1 << iota // 0001: The validator is deactivated
      #	LowBlocks                                // 0010: The validator was low block rate
      #	LowThreshold                             // 0100: The validator's stake was lower than minimum stake threshold
      #	Duplicated                               // 1000: The validator was duplicate block or duplicate signature
      #	Unstaked                                 // 0001,0000: The validator was unstaked
      #	Slashing                                 // 0010,0000: The validator is being slashed
      #	Valided      = 0                         // 0000: The validator was activated
      #	NotExist     = 1 << 31                   // 1000,xxxx,... : The validator is not exist
      # 底层是用bit来存储的，是个复合状态
      # 链上验证人状态有：0: 正常 1：无效（只要有后面4种情况，就是无效状态） 2：低出块阈值（出块低于此值将退出） 4: 低阈值（质押数量低于此值将退出） 8: 双签 16：解质押 32:惩罚
      add(:status, :integer, null: false, default: 0)

      # 0-candidate(质押节点) 1-active(共识节点候选人) 2-Consensus(共识节点)
      # 目前没有 2-Consensus(共识节点)记录
      add(:role, :integer, null: false, default: 0)
      # 退出开始区块
      add(:exit_block, :bigint, null: false)
      # 锁定结束区块（真正退出完成）
      add(:lock_block, :bigint, null: false)
      # 退出内容
      add(:exit_desc, :string, null: true)

      timestamps(null: false, type: :utc_datetime_usec)
    end
  end
end
