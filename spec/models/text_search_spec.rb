require 'spec_helper'

describe TextSearch do
  describe 'self.search_stanza' do
    context "'Organism name' スタンザに対して 'PCC71' でテキスト検索する" do
      subject {
        TextSearch.search_stanza('organism_names', 'PCC71')
      }

      it { should include(id: 'organism_names') }
      it { should include(count: 10) }
      it { should include(report_type: 'organisms') }
      it { subject[:url].should match /\/stanza\/organism_names/ }
      it {
        should include(entry_ids:
          [
            {'tax_id' => '163908'},
            {'tax_id' => '1168'},
            {'tax_id' => '32057'},
            {'tax_id' => '103690'},
            {'tax_id' => '102127'},
            {'tax_id' => '118166'},
            {'tax_id' => '128403'},
            {'tax_id' => '179408'},
            {'tax_id' => '32055'},
            {'tax_id' => '93135'}
          ]
        )
      }
    end
  end
end
