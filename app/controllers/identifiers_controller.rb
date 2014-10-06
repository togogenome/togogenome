class IdentifiersController < ApplicationController
  def convert(identifiers, databases)
    @identifiers, @databases = identifiers, databases
    @db_links = Identifier.convert(identifiers, databases)
  end

  def teach(databases)
    @databases  = databases
    @db_links   = Identifier.sample(databases)
    @identifiers = @db_links.map {|item| item[:node0].split('/').last }
  end

  def download(identifiers, databases)
    @identifiers, @databases = identifiers, databases
    @count = Identifier.count(identifiers, databases)
  end
end
