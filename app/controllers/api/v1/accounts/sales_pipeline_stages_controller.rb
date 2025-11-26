class Api::V1::Accounts::SalesPipelineStagesController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :fetch_sales_pipeline
  before_action :fetch_stage, except: [:index, :create]
  before_action :authorize_stage

  def index
    @stages = @sales_pipeline.sales_pipeline_stages.includes(:label)
    render json: @stages.map { |stage| stage_response(stage) }
  end

  def show
    render json: stage_response(@stage)
  end

  def create
    ActiveRecord::Base.transaction do
      safe_name = stage_params[:name].presence || 'Etapa'
      safe_color = stage_params[:color].presence || '#1f93ff'
      safe_position = stage_params[:position].presence || @sales_pipeline.sales_pipeline_stages.maximum(:position).to_i + 1

      label = current_account.labels.create!(
        title: SalesPipelineStage.label_title_from(safe_name),
        color: safe_color,
        description: "Estágio do pipeline de vendas: #{safe_name}"
      )

      @stage = @sales_pipeline.sales_pipeline_stages.create!(
        stage_params.merge(
          name: safe_name,
          color: safe_color,
          position: safe_position,
          label_id: label.id,
          account: current_account
        )
      )
    end

    render json: stage_response(@stage), status: :created
  end

  def update
    ActiveRecord::Base.transaction do
      safe_name = stage_params[:name].presence || @stage.name
      safe_color = stage_params[:color].presence || @stage.color

      @stage.update!(stage_params.merge(name: safe_name, color: safe_color))
    end

    render json: stage_response(@stage)
  end

  def destroy
    migration_stage_id = params.dig(:stage, :migration_stage_id)

    ActiveRecord::Base.transaction do
      if migration_stage_id.present?
        migrate_conversations!(migration_stage_id)
      else
        validate_destruction!
      end

      @stage.destroy!
    end

    head :ok
  end

  def reorder
    stage_orders = params.require(:stages).map { |s| [s[:id], s[:position]] }.to_h

    ActiveRecord::Base.transaction do
      stage_orders.each do |stage_id, position|
        stage = @sales_pipeline.sales_pipeline_stages.find(stage_id)
        stage.update!(position: position)
      end
    end

    head :ok
  end

  private

  def fetch_sales_pipeline
    @sales_pipeline = current_account.sales_pipelines.first_or_create!(
      name: Api::V1::Accounts::SalesPipelinesController::DEFAULT_PIPELINE_NAME
    )
  end

  def fetch_stage
    @stage = @sales_pipeline.sales_pipeline_stages.find(params[:id])
  end

  def stage_params
    params.require(:stage).permit(:name, :color, :position, :is_default, :is_closed_won, :is_closed_lost)
  end

  def validate_destruction!
    return if @stage.conversations.empty?

    render json: { 
      error: 'Não é possível excluir estágio com conversas ativas',
      conversations_count: @stage.conversations.count
    }, status: :unprocessable_entity
  end

  def migrate_conversations!(migration_stage_id)
    migration_stage = @sales_pipeline.sales_pipeline_stages.find(migration_stage_id)
    manager = SalesPipelineServices::ConversationStageManager

    @stage.conversations.find_each do |conversation|
      stage_manager = manager.new(conversation: conversation, account: current_account)
      stage_manager.update_stage!(migration_stage)
    end
  end

  def authorize_stage
    authorize(@stage || SalesPipelineStage.new(account: current_account, sales_pipeline: @sales_pipeline))
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
end
