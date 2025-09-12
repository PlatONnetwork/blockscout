defmodule BlockScoutWeb.API.V2.PlatonAppchainView do
  use BlockScoutWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("platon_appchain_deposits.json", %{
        commitments: commitments,
        next_page_params: next_page_params
      }) do
    %{
      items:
        Enum.map(commitments, fn commitments ->
          %{
            "no" => commitments.event_id,
            "l1_txn_hash" => commitments.l1_event_hash,
            "l1_block_number" => commitments.l1_block_number,
            "l1_amount" => commitments.l1_amount,
            "tx_type" => commitments.tx_type,
            "block_timestamp" => commitments.block_timestamp,
            "state_batches_index" => Integer.to_string(commitments.start_id) <> "-"  <> Integer.to_string(commitments.end_id),
            "state_batches_txn_hash" => commitments.commitment_hash,
            "state_root" => commitments.state_root,
            "l2_event_hash" => commitments.l2_event_hash,
            "status" => commitments.replay_status
          }
        end),
      next_page_params: next_page_params
    }
  end

  @spec render(String.t(), map()) :: map()
  def render("platon_appchain_deposits_batches.json", %{
    commitments: commitments,
    next_page_params: next_page_params
  }) do
    %{
      items:
        Enum.map(commitments, fn commitments ->
           %{
             "index" =>  Integer.to_string(commitments.start_id) <> "-"  <> Integer.to_string(commitments.end_id),
             "l2_state_batches_hash" => commitments.state_batches_txn_hash,
             "l2_block" => commitments.block_number,
             "block_timestamp" => commitments.block_timestamp,
             "batch_root" => commitments.state_root,
             "l1_txns" => commitments.tx_number,
             "submitter" => commitments.from
           }
        end),
      next_page_params: next_page_params
    }
  end

  def render("platon_appchain_withdrawals.json", %{
        withdrawals: withdrawals,
        next_page_params: next_page_params
      }) do
    %{
      items:
        Enum.map(withdrawals, fn withdrawal ->
          %{
            "no" => withdrawal.event_id,
            "epoch" => withdrawal.epoch,
            "from" => withdrawal.from,
            "l2_txn_hash" => withdrawal.l2_event_hash,
            "l2_amount" => withdrawal.l2_amount,
            "type" => withdrawal.tx_type,
            "block_timestamp" => withdrawal.block_timestamp,
            "state_batches_index" =>  Integer.to_string(withdrawal.start_block_number) <> "-"  <> Integer.to_string(withdrawal.end_block_number),
            "state_batches_txn_hash" => withdrawal.checkpoint_hash,
            "state_root" => withdrawal.state_root,
            "l1_txn_hash" => withdrawal.l1_exec_hash,
            "status" => withdrawal.replay_status
          }
        end),
      next_page_params: next_page_params
    }
  end

  def render("platon_appchain_withdrawals_batches.json", %{
    withdrawals: withdrawals,
    next_page_params: next_page_params
  }) do
    %{
      items:
        Enum.map(withdrawals, fn withdrawal ->
         %{
           "no" => withdrawal.epoch,
           "start_block_number" => withdrawal.start_block_number,
           "end_block_number" => withdrawal.end_block_number,
           "l1_state_batches_hash" => withdrawal.l1_state_batches_hash,
           "l1_block" => withdrawal.block_number,
           "block_timestamp" => withdrawal.block_timestamp,
           "batch_root" => withdrawal.state_root,
           "l2_txns" => withdrawal.l2_txns,
           "submitter" => withdrawal.from,
           "tx_fee" => withdrawal.tx_fee

         }
        end),
      next_page_params: next_page_params
    }
  end

  def render("platon_appchain_withdrawals_batches_details.json", %{withdrawals_batches_details: withdrawals_batches_details}) do
    %{
      items:
      %{
        "epoch" => withdrawals_batches_details.epoch,
        "start_block_number" => withdrawals_batches_details.start_block_number,
        "end_block_number" => withdrawals_batches_details.end_block_number,
        "state_root" => withdrawals_batches_details.state_root,
        "block_number" => withdrawals_batches_details.block_number,
        "hash" => withdrawals_batches_details.hash,
        "block_timestamp" => withdrawals_batches_details.block_timestamp,
        "from" => withdrawals_batches_details.from,
        "tx_fee" => withdrawals_batches_details.tx_fee
      }
    }
  end

  def render("platon_appchain_withdrawals_batches_tx.json", %{
    withdrawals: withdrawals,
    next_page_params: next_page_params
  }) do
    %{
      items:
        Enum.map(withdrawals, fn withdrawal ->
          %{
            "hash" => withdrawal.hash,
            "type" => withdrawal.type,
            "method" =>  withdrawal.method,# 待转换 就是l2Event.tx_type
            "block" => withdrawal.block_number,
            "from" => %{"hash" => withdrawal.from},
            "to" => %{"hash" => withdrawal.to},
            "value" => withdrawal.value,
            "fee" => %{"type" => "actual", "value" => withdrawal.fee},
          }
        end),
      next_page_params: next_page_params
    }
  end

  def render("platon_appchain_items_count.json", %{count: count}) do
    count
  end
end
