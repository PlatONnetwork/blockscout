defmodule Explorer.Chain.PlatonAppchain.Commitment do
  use Explorer.Schema

  alias Explorer.Chain.{
    Hash,
    Block,
    Data
    }
  @optional_attrs ~w()a

  @required_attrs ~w(hash state_root block_number start_id end_id tx_number from block_timestamp)a

  @allowed_attrs @optional_attrs ++ @required_attrs

  @typedoc """
  * `hash` - 批次交易hash
  * `state_root` - 批次state root
  * `start_id` - 批次起始event id
  * `end_id` - 批次结束event id
  * `tx_number` - 批次总交易数（endId-startId+1）
  * `from` - 批次交易发起者
  * `to` - 批次交易接收者
  * `block_number` - 批次交易所在区块
  * `block_timestamp` - 批次交易所在区块时间戳
  """
  @type t :: %__MODULE__{
               hash:  Hash.t(),
               state_root:  Data.t(),
               block_number:  Block.block_number(),
               start_id:  non_neg_integer(),
               end_id: non_neg_integer(),
               tx_number: non_neg_integer(),
               from:  Hash.Address.t(),
               block_timestamp: DateTime.t() | nil,
             }

  @primary_key false
  schema "commitments" do
    field(:hash, Hash.Full, primary_key: true)
    field(:state_root, Data)
    field(:block_number, :integer)
    field(:start_id, :integer)
    field(:end_id, :integer)
    field(:tx_number, :integer)
    field(:from, Hash.Address)
    field(:block_timestamp, :utc_datetime_usec)
    timestamps()
  end

  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Schema.t()
  def changeset(%__MODULE__{} = module, attrs \\ %{}) do
    module
    |> cast(attrs, @allowed_attrs)  # 确保@allowed_attrs中指定的key才会赋值到结构体中
    |> validate_required(@required_attrs)
    |> unique_constraint(:hash)
  end

end
