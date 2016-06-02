require 'spec_helper'

describe ApplicationHelper, type: :helper do
  describe '.paperclip_full_url' do
    it "when passed an invalid object returns '#'" do
      bad_obj = double(url: nil)

      expect(paperclip_full_url(bad_obj)).to eq('#')
    end

    context 'when passed a valid object' do
      it 'returns the url if no relative root is set' do
        good_obj = double(url: '/url')
        allow(Rails.application.config.action_controller).to \
          receive(:relative_url_root).and_return(nil)

        expect(paperclip_full_url(good_obj)).to eq(good_obj.url)
      end

      it 'returns the url prepended by the relative root if set' do
        good_obj = double(url: '/url')
        rel_root = 'test'
        allow(Rails.application.config.action_controller).to \
          receive(:relative_url_root).and_return(rel_root)

        expect(paperclip_full_url(good_obj)).to \
          eq("#{rel_root}#{good_obj.url}")
      end
    end
  end
end
