class VirusController < ApplicationController
  def show(id)
    @virus_id = id
    @virus = Virus.find(id)
  end
end
