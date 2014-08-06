class IdentifiersController < ApplicationController
  def convert(identifiers, databases, sample_mode)
    #identifiers ['P16033', 'G0JEW3']
    #databases ['uniprot', 'pfam', 'refseq', 'ec-code']

    if databases.nil? and identifiers.empty?
      @message = 'Input identifiers to be converted and select target and intermediate databases.'
    elsif databases.nil?
      @message = 'Select target and intermediate databases.'
    elsif @sample_mode = (sample_mode == 'true')
      @db_links  =  Identifier.sample(databases)

      if @db_links.empty?
        @message = 'Identifiers not found.'
      else
        @sample_id = @db_links.first[:node0].split('/').last
      end
    else
      @db_links = Identifier.convert(identifiers, databases)
      @message = 'Identifiers not found.' if @db_links.empty?
    end
  end
end
