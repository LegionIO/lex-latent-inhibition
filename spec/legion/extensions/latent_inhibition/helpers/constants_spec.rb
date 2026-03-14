# frozen_string_literal: true

RSpec.describe Legion::Extensions::LatentInhibition::Helpers::Constants do
  describe 'MAX_STIMULI' do
    it 'is 500' do
      expect(described_class::MAX_STIMULI).to eq(500)
    end
  end

  describe 'INHIBITION_RATE' do
    it 'is 0.03' do
      expect(described_class::INHIBITION_RATE).to eq(0.03)
    end
  end

  describe 'DISINHIBITION_RATE' do
    it 'is 0.2' do
      expect(described_class::DISINHIBITION_RATE).to eq(0.2)
    end
  end

  describe 'NOVELTY_THRESHOLD' do
    it 'is 3' do
      expect(described_class::NOVELTY_THRESHOLD).to eq(3)
    end
  end

  describe 'INHIBITION_LABELS' do
    it 'covers the full 0.0..1.0 range' do
      scores = [0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0]
      scores.each do |score|
        match = described_class::INHIBITION_LABELS.find { |range, _| range.cover?(score) }
        expect(match).not_to be_nil, "no label found for score #{score}"
      end
    end

    it 'labels 0.0 as uninhibited' do
      label = described_class::INHIBITION_LABELS.find { |range, _| range.cover?(0.0) }&.last
      expect(label).to eq(:uninhibited)
    end

    it 'labels 1.0 as saturated' do
      label = described_class::INHIBITION_LABELS.find { |range, _| range.cover?(1.0) }&.last
      expect(label).to eq(:saturated)
    end
  end

  describe 'NOVELTY_LABELS' do
    it 'maps true to :novel' do
      expect(described_class::NOVELTY_LABELS[true]).to eq(:novel)
    end

    it 'maps false to :familiar' do
      expect(described_class::NOVELTY_LABELS[false]).to eq(:familiar)
    end
  end
end
