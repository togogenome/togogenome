class MappingsController < ApplicationController
  def index
  end

  def convert(identifiers, databases)
    #identifiers ['P16033', 'G0JEW3']
    #databases ['uniprot', 'pfam', 'refseq', 'ec-code']

    if identifiers.empty? || databases.nil? 
      @message = 'Input identifiers to be converted and select target and intermediate databases.' 
    else
      @db_links = Identifier.convert(identifiers, databases)
      @message = 'Identifiers not found.' if @db_links.empty?
    end
  end
end
