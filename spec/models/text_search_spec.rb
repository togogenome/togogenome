require 'spec_helper'

describe TextSearch do
  describe 'self.search_by_stanza_id' do
    context "'Organism name' スタンザに対して 'PCC71' でテキスト検索する" do
      subject {
        TextSearch.search_by_stanza_id('PCC71', 'organism_names')
      }

      it { should include(stanza_id: 'organism_names') }
      it { should include(count: 10) }
      it { should include(report_type: 'organisms') }
      it { subject[:stanza_url].should match /\/stanza\/organism_names/ }
      it {
        should include(urls:
          ['http://localhost:9292/stanza/organism_names?tax_id=163908',
           'http://localhost:9292/stanza/organism_names?tax_id=1168',
           'http://localhost:9292/stanza/organism_names?tax_id=32057',
           'http://localhost:9292/stanza/organism_names?tax_id=103690',
           'http://localhost:9292/stanza/organism_names?tax_id=102127',
           'http://localhost:9292/stanza/organism_names?tax_id=118166',
           'http://localhost:9292/stanza/organism_names?tax_id=128403',
           'http://localhost:9292/stanza/organism_names?tax_id=179408',
           'http://localhost:9292/stanza/organism_names?tax_id=32055',
           'http://localhost:9292/stanza/organism_names?tax_id=93135']
        )
      }
    end
  end
end
