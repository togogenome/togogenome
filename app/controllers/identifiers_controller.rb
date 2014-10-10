class IdentifiersController < ApplicationController
  def convert(identifiers, databases)
    @identifiers, @databases = identifiers, databases
    @count = Identifier.count(identifiers, databases)

    respond_to do |format|
      format.js do
        @db_links = Identifier.convert(identifiers, databases)
      end

      format.csv do
        @database_labels = databases.map {|db| Database.find(db)['label'] }
        @filename = 'identifiers.csv'
      end
    end
  end

  def teach(databases)
    @databases   = databases
    @db_links    = Identifier.sample(databases)
    @count       = @db_links.count
    @identifiers = @db_links.map {|item| item[:node0].split('/').last }
  end
end
