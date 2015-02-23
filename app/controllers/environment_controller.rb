class EnvironmentController < ApplicationController
  def show(id)
    @meo_id = id
    @environment = Environment.find(id)
  end
end
