# frozen_string_literal: true

RSpec.describe Legion::Extensions::LatentInhibition::Helpers::StimulusRecord do
  subject(:record) { described_class.new(label: 'test_stimulus') }

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(record.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets label' do
      expect(record.label).to eq('test_stimulus')
    end

    it 'starts with zero exposure_count' do
      expect(record.exposure_count).to eq(0)
    end

    it 'starts with zero inhibition_score' do
      expect(record.inhibition_score).to eq(0.0)
    end

    it 'starts with nil last_exposed_at' do
      expect(record.last_exposed_at).to be_nil
    end

    it 'starts with empty associations' do
      expect(record.associations).to be_empty
    end
  end

  describe '#expose!' do
    it 'increments exposure_count' do
      record.expose!
      expect(record.exposure_count).to eq(1)
    end

    it 'raises inhibition_score by INHIBITION_RATE' do
      record.expose!
      expect(record.inhibition_score).to be_within(0.0001).of(
        Legion::Extensions::LatentInhibition::Helpers::Constants::INHIBITION_RATE
      )
    end

    it 'sets last_exposed_at' do
      record.expose!
      expect(record.last_exposed_at).to be_a(Time)
    end

    it 'returns self for chaining' do
      expect(record.expose!).to eq(record)
    end

    it 'clamps inhibition_score at 1.0 after many exposures' do
      50.times { record.expose! }
      expect(record.inhibition_score).to be <= 1.0
    end

    it 'accumulates inhibition with multiple exposures' do
      3.times { record.expose! }
      expected = (Legion::Extensions::LatentInhibition::Helpers::Constants::INHIBITION_RATE * 3).round(10)
      expect(record.inhibition_score).to be_within(0.0001).of(expected)
    end
  end

  describe '#associate!' do
    it 'returns effectiveness of 1.0 for uninhibited stimulus' do
      effectiveness = record.associate!(outcome: 'reward')
      expect(effectiveness).to be_within(0.001).of(1.0)
    end

    it 'returns reduced effectiveness for inhibited stimulus' do
      20.times { record.expose! }
      effectiveness = record.associate!(outcome: 'reward')
      expect(effectiveness).to be < 1.0
    end

    it 'appends to associations array' do
      record.associate!(outcome: 'reward')
      expect(record.associations.size).to eq(1)
      expect(record.associations.first[:outcome]).to eq('reward')
    end

    it 'stores effectiveness in association record' do
      eff = record.associate!(outcome: 'pain')
      expect(record.associations.last[:effectiveness]).to eq(eff)
    end

    it 'stores recorded_at timestamp' do
      record.associate!(outcome: 'neutral')
      expect(record.associations.last[:recorded_at]).to be_a(Time)
    end

    it 'rounds effectiveness to 10 decimal places' do
      20.times { record.expose! }
      eff = record.associate!(outcome: 'test')
      expect(eff.to_s.split('.').last.length).to be <= 10
    end
  end

  describe '#disinhibit!' do
    before { 10.times { record.expose! } }

    it 'reduces inhibition_score' do
      prior = record.inhibition_score
      record.disinhibit!(intensity: 1.0)
      expect(record.inhibition_score).to be < prior
    end

    it 'clamps score at 0.0' do
      record.disinhibit!(intensity: 1000.0)
      expect(record.inhibition_score).to eq(0.0)
    end

    it 'returns self for chaining' do
      expect(record.disinhibit!(intensity: 0.5)).to eq(record)
    end

    it 'applies partial disinhibition proportionally to intensity' do
      prior = record.inhibition_score
      record.disinhibit!(intensity: 0.5)
      expected_reduction = (Legion::Extensions::LatentInhibition::Helpers::Constants::DISINHIBITION_RATE * 0.5).round(10)
      expect(prior - record.inhibition_score).to be_within(0.0001).of(expected_reduction)
    end

    it 'clamps intensity to [0.0, 1.0] before applying' do
      prior = record.inhibition_score
      record.disinhibit!(intensity: 5.0)
      max_reduction = Legion::Extensions::LatentInhibition::Helpers::Constants::DISINHIBITION_RATE
      expect(prior - record.inhibition_score).to be_within(0.0001).of(max_reduction)
    end
  end

  describe '#novel?' do
    it 'returns true when exposure_count < NOVELTY_THRESHOLD' do
      expect(record.novel?).to be(true)
    end

    it 'returns false after NOVELTY_THRESHOLD or more exposures' do
      Legion::Extensions::LatentInhibition::Helpers::Constants::NOVELTY_THRESHOLD.times { record.expose! }
      expect(record.novel?).to be(false)
    end
  end

  describe '#inhibition_label' do
    it 'returns :uninhibited for a new record' do
      expect(record.inhibition_label).to eq(:uninhibited)
    end

    it 'returns :saturated after many exposures' do
      50.times { record.expose! }
      expect(record.inhibition_label).to eq(:saturated)
    end
  end

  describe '#to_h' do
    before { record.expose! }

    it 'includes all expected keys' do
      h = record.to_h
      %i[id label exposure_count inhibition_score inhibition_label novel last_exposed_at associations].each do |key|
        expect(h).to have_key(key)
      end
    end

    it 'reflects current state' do
      h = record.to_h
      expect(h[:exposure_count]).to eq(1)
      expect(h[:label]).to eq('test_stimulus')
    end
  end
end
