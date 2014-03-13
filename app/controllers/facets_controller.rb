class FacetsController < ApplicationController
  respond_to :json

  def show(id, node)
    respond_with(Facets::Base.lookup(id).new(id: node).children)
  end

  def search(id, word)
    result = Facets::Base.lookup(id).search(word) # +1: check for 'more items'
    respond_with(result.map {|r| {label: r.name, value: r.name, id: r.id, description: r.description, ancestor: r.ancestor} })
  end
end
