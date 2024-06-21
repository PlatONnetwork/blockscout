defmodule Explorer.Repo.PlatonAppchain.Migrations.CreateCheckPoints do
  use Ecto.Migration

  # 当用户在L2上发起一些交易，需要把相应信息同步到L1时，L2会触发 L2StateSynced 事件，并被L2收集并组成一个checkpoint，提交到L1，L1收到checkpoint后，并不执行其中的交易，而是保存后等待用户在L1发起交易操作时，再再L1执行相应逻辑
  # checkpoints表保存 checkpoint 信息
  def change do
    create table(:checkpoints, primary_key: false) do
      # l2上的epoch，一个epoch结束块高生成一个checkpoint
      add(:epoch, :bigint, null: false, primary_key: true)
      # checkpoint收集的事件的L2开始块高（epoch开始的前3个块高）
      add(:start_block_number, :bigint, null: false)
      # checkpoint收集事件的l2上截至块高（epoch结束的前3个块高）
      add(:end_block_number, :bigint, null: false)
      # state_root
      add(:state_root, :bytea, null: false)
      # checkpoint中包含的事件数（另起线程统计l2_events中数据，缺省就是null, 如果是null表示还没有统计。)
      add(:event_counts, :integer, null: true)
      # 交易所在L1区块
      add(:block_number, :bigint, null: false)
      # checkpoint 批次在L1上的hash
      add(:hash, :bytea, null: false)
      # checkpoint交易所在L1交易时间
      add(:block_timestamp, :"timestamp without time zone", null: true)
      # l1上交易发起者
      add(:from, :bytea, null: true)
      # l1上交易手序费
      add(:tx_fee, :numeric, precision: 100, null: true)

      #record timestamp
      timestamps(null: false, type: :utc_datetime_usec)
    end
  end
end
