defmodule Explorer.Repo.PlatonAppchain.Migrations.CreateCommitments do
  use Ecto.Migration

  # L2监听L1上合约的事件，定期把监听到的事件，打包提交一个commitment合约交易到L2。验证人会重放commitment中交易逻辑，并触发StateSyncedResult事件。
  # commitments表记录commitment合约交易的信息
  def change do
    create table(:commitments, primary_key: false) do
      # 交易hash
      add(:hash, :bytea, null: false, primary_key: true)
      # 批次state root
      add(:state_root, :bytea, null: false)
      # 交易所在区块
      add(:block_number, :bigint, null: false)
      # 批次起始msgId
      add(:start_id, :integer, null: false)
      # 批次结束msgId
      add(:end_id, :integer, null: false)
      # 批次总交易数（endId-startId+1）
      add(:tx_number, :integer, null: false)
      # 批次交易发起者
      add(:from, :bytea, null: false)
      # 交易时间
      add(:block_timestamp, :"timestamp without time zone", null: true)

      timestamps(null: false, type: :utc_datetime_usec)
    end
  end
end
