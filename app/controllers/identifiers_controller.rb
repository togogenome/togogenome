class IdentifiersController < ApplicationController
  def convert(identifiers, databases)
    @db_links = Identifier.convert(identifiers, databases)
  end

  def teach(databases)
    @db_links   = Identifier.sample(databases)
    @sample_ids = @db_links.map {|item| item[:node0].split('/').last }.join('\n')
  end
end
