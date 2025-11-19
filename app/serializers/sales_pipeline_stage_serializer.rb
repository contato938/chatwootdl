class SalesPipelineStageSerializer
  def initialize(resource)
    @resource = resource
  end

  def as_json(*)
    {
      id: @resource.id,
      name: @resource.name,
      color: @resource.color,
      position: @resource.position,
      is_default: @resource.is_default,
      is_closed_won: @resource.is_closed_won,
      is_closed_lost: @resource.is_closed_lost,
      created_at: @resource.created_at,
      updated_at: @resource.updated_at,
      label: label_data,
      sales_pipeline: sales_pipeline_data
    }
  end

  private

  def label_data
    return nil unless @resource.label

    {
      id: @resource.label.id,
      title: @resource.label.title,
      description: @resource.label.description,
      color: @resource.label.color,
      show_on_sidebar: @resource.label.show_on_sidebar,
      created_at: @resource.label.created_at,
      updated_at: @resource.label.updated_at
    }
  end

  def sales_pipeline_data
    return nil unless @resource.sales_pipeline

    {
      id: @resource.sales_pipeline.id,
      name: @resource.sales_pipeline.name,
      created_at: @resource.sales_pipeline.created_at,
      updated_at: @resource.sales_pipeline.updated_at
    }
  end
end
