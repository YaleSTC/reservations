# frozen_string_literal: true

require 'spec_helper'

shared_examples_for 'soft deletable' do
  let(:model) { described_class }

  describe '#deleted?' do
    it 'returns true if the deleted_at attribute is present' do
      obj = model.new(deleted_at: Time.zone.now)
      expect(obj).to be_deleted
    end

    it 'returns false if the deleted_at attribute is nil' do
      obj = model.new(deleted_at: nil)
      expect(obj).not_to be_deleted
    end
  end

  describe '#destroy' do
    let!(:obj) { FactoryGirl.create(model.to_s.underscore.to_sym) }

    it 'sets the deleted_at attribute by default' do
      allow(obj).to receive(:deleted?).and_return(false)
      allow(obj).to receive(:associated_records).and_return([])
      # rounding necessary due to MySQL rounding in the database
      time = Time.zone.now.round(0)
      Timecop.freeze(time) do
        expect { obj.destroy }.to change { obj.reload.deleted_at }
          .from(nil).to(time)
      end
    end
    it 'actually destroys the object if :force is passed' do
      expect { obj.destroy(:force) }.to change { model.count }.by(-1)
    end
    it 'returns the object if it has already been deleted' do
      allow(obj).to receive(:deleted?).and_return(true)
      expect(obj.destroy).to eq(obj)
    end

    context 'with associations' do
      let(:associated) { instance_spy(model) }

      before do
        allow(obj).to receive(:associated_records).and_return([associated])
      end

      it 'calls destroy on associated records' do
        obj.destroy
        expect(associated).to have_received(:destroy)
      end
      it 'passes along the force parameter' do
        obj.destroy(:force)
        expect(associated).to have_received(:destroy).with(:force)
      end
    end
  end

  describe '#revive' do
    let!(:obj) { FactoryGirl.create(model.to_s.underscore.to_sym) }

    it 'unsets the deleted_at attribute by default' do
      obj.update!(deleted_at: Time.zone.now) # necessary so that it changes
      allow(obj).to receive(:deleted?).and_return(true)
      allow(obj).to receive(:associated_records).and_return([])
      expect { obj.revive }.to change { obj.reload.deleted_at }.to(nil)
    end
    it 'returns the object if it is not deleted' do
      allow(obj).to receive(:deleted?).and_return(false)
      expect(obj.revive).to eq(obj)
    end

    context 'with associations' do
      let(:associated) { instance_spy(model) }

      before do
        allow(obj).to receive(:associated_records).and_return([associated])
      end

      it 'calls revive on associated records' do
        allow(obj).to receive(:deleted?).and_return(true)
        obj.revive
        expect(associated).to have_received(:revive)
      end
    end
  end
end
