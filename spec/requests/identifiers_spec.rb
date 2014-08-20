require 'spec_helper'

describe "IdentifiersRequest" do
  describe 'GET teach' do
    it "Render teach, convert, db_link_table" do
      xhr :get, identifiers_teach_path,
        {databases: %w(jcsd massbank uniprot)}

      expect(response.status).to be(200)
      expect(response).to render_template(:teach)
      expect(response).to render_template(:convert)
      expect(response).to render_template(:db_link_table)
    end

    it "Show 'Not found.'" do
      xhr :get, identifiers_teach_path,
        {databases: %w(jcsd massbank uniprot pdb)}

      expect(response.status).to be(200)
      expect(response).to render_template(:teach)
      expect(response).to render_template(:convert)
      expect(response).to render_template(:db_link_table)
      expect(response.body).to include("Not found.")
    end
  end

  describe 'GET convert' do
    it "Render convert, db_link_tabke" do
      xhr :get, identifiers_convert_path,
        {databases: %w(uniprot refseq), identifiers: ['P16033']}

      expect(response.status).to be(200)
      expect(response).to render_template(:convert)
      expect(response).to render_template(:db_link_table)
    end

    it "Show 'Not found.'" do
      xhr :get, identifiers_convert_path,
        {databases: %w(uniprot refseq), identifiers: ['PXXXXX']}

      expect(response.status).to be(200)
      expect(response).to render_template(:convert)
      expect(response).to render_template(:db_link_table)
      expect(response.body).to include("Not found.")
    end
  end
end
