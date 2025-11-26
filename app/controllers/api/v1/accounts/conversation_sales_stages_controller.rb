class Api::V1::Accounts::ConversationSalesStagesController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :fetch_conversation
  before_action :authorize_conversation

  def show
    stage_manager = SalesPipelineServices::ConversationStageManager.new(
      conversation: @conversation,
      account: current_account
    )
    @current_stage = stage_manager.current_stage
    render json: @current_stage ? stage_response(@current_stage) : {}
  end

  def update
    stage_manager = SalesPipelineServices::ConversationStageManager.new(
      conversation: @conversation,
      account: current_account
    )

    stage = current_account.sales_pipeline_stages.includes(:label).find(stage_params[:stage_id])
    if stage.label.blank?
      return render json: { error: 'Stage label is missing. Please configure a label for this stage.' }, status: :unprocessable_entity
    end

    stage_manager.update_stage!(stage)

    @current_stage = stage
    render json: stage_response(@current_stage)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Stage not found' }, status: :not_found
  rescue StandardError => e
    Rails.logger.error("Sales stage update failed: #{e.message}")
    render json: { error: 'Unable to update sales stage' }, status: :internal_server_error
  end

  def destroy
    stage_manager = SalesPipelineServices::ConversationStageManager.new(
      conversation: @conversation,
      account: current_account
    )

    stage_manager.remove_stage!
    head :ok
  rescue StandardError => e
    Rails.logger.error("Sales stage remove failed: #{e.message}")
    render json: { error: 'Unable to remove sales stage' }, status: :internal_server_error
  end

  private

  def fetch_conversation
    @conversation = current_account.conversations.find(params[:conversation_id])
  end

  def stage_params
    params.require(:sales_stage).permit(:stage_id)
  end

  def stage_response(stage)
    {
      id: stage.id,
      name: stage.name,
      color: stage.color,
      position: stage.position,
      is_default: stage.is_default,
      is_closed_won: stage.is_closed_won,
      is_closed_lost: stage.is_closed_lost,
      label_id: stage.label_id,
      label: stage.label&.slice(:id, :title, :color)
    }
  end

  def authorize_conversation
    authorize(@conversation)
  end
end
