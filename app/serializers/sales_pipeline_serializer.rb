class SalesPipelineSerializer
  def initialize(resource)
    @resource = resource
  end

  def as_json(*)
    {
      id: @resource.id,
      name: @resource.name,
      created_at: @resource.created_at,
      updated_at: @resource.updated_at,
      sales_pipeline_stages: sales_pipeline_stages_data
    }
  end

  private

  def sales_pipeline_stages_data
    return [] unless @resource.sales_pipeline_stages

    @resource.sales_pipeline_stages.map do |stage|
      SalesPipelineStageSerializer.new(stage).as_json
    end
  end
end
