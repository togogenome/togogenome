class IdentifiersController < ApplicationController
  def convert(identifiers, databases)
    #identifiers ['P16033', 'G0JEW3']
    #databases ['uniprot', 'pfam', 'refseq', 'ec-code']

    if databases.nil? and identifiers.empty?
      @message = 'Input identifiers to be converted and select target and intermediate databases.'
    elsif databases.nil?
      @message = 'Select target and intermediate databases.'
    elsif identifiers.empty?
      @message = 'Input identifiers to be converted.'
    else
      @db_links = Identifier.convert(identifiers, databases)
      @message = 'Identifiers not found.' if @db_links.empty?
    end
  end
end
