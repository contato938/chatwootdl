class Api::V1::Accounts::SalesPipelinesController < Api::V1::Accounts::BaseController
  DEFAULT_PIPELINE_NAME = 'Default Sales Pipeline'.freeze

  before_action :current_account
  before_action :fetch_sales_pipeline, except: [:index, :create]
  before_action :authorize_sales_pipeline

  def index
    @sales_pipeline = current_account.sales_pipelines.first_or_create!(default_pipeline_attributes)
    @stages = @sales_pipeline.sales_pipeline_stages.includes(:label)
    render json: pipeline_response(@sales_pipeline, @stages)
  end

  def show
    @stages = @sales_pipeline.sales_pipeline_stages.includes(:label)
    render json: pipeline_response(@sales_pipeline, @stages)
  end

  def create
    attrs = permitted_params.to_h
    attrs[:name] = DEFAULT_PIPELINE_NAME if attrs[:name].blank?
    @sales_pipeline = current_account.sales_pipelines.create!(attrs)
    render json: pipeline_response(@sales_pipeline), status: :created
  end

  def update
    @sales_pipeline.update!(permitted_params)
    render json: pipeline_response(@sales_pipeline)
  end

  def destroy
    @sales_pipeline.destroy!
    head :ok
  end

  private

  def fetch_sales_pipeline
    @sales_pipeline = current_account.sales_pipelines.find(params[:id])
  end

  def permitted_params
    params.require(:sales_pipeline).permit(:name)
  end

  def authorize_sales_pipeline
    authorize(@sales_pipeline || SalesPipeline.new(account: current_account))
  end

  def pipeline_response(pipeline, stages = nil)
    stages ||= pipeline.sales_pipeline_stages.includes(:label)

    {
      id: pipeline.id,
      name: pipeline.name,
      stages: stages.map { |stage| stage_response(stage) }
    }
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
