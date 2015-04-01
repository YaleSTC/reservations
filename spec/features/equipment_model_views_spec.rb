require 'spec_helper'

describe 'Equipment model views' do
  subject { page }

  context 'index view' do
    before { visit equipment_models_path }
    it { is_expected.to have_content('Equipment Models') }
    it { is_expected.to have_content(@eq_model.name) }
  end
end
