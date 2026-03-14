# frozen_string_literal: true

RSpec.describe Legion::Extensions::LatentInhibition::Runners::LatentInhibition do
  let(:engine) { Legion::Extensions::LatentInhibition::Helpers::InhibitionEngine.new }
  let(:client) { Legion::Extensions::LatentInhibition::Client.new }

  describe '#expose' do
    it 'returns a hash with exposure data' do
      result = client.expose(label: 'bell', engine: engine)
      expect(result).to be_a(Hash)
      expect(result[:label]).to eq('bell')
      expect(result[:exposure_count]).to eq(1)
    end

    it 'increments exposure on repeated calls' do
      client.expose(label: 'bell', engine: engine)
      result = client.expose(label: 'bell', engine: engine)
      expect(result[:exposure_count]).to eq(2)
    end

    it 'includes inhibition_score' do
      result = client.expose(label: 'tone', engine: engine)
      expect(result).to have_key(:inhibition_score)
    end

    it 'includes novel status' do
      result = client.expose(label: 'new', engine: engine)
      expect(result[:novel]).to be(true)
    end

    it 'uses default engine when none provided' do
      result = client.expose(label: 'default_test')
      expect(result[:label]).to eq('default_test')
    end
  end

  describe '#associate' do
    it 'returns a hash with effectiveness' do
      result = client.associate(label: 'bell', outcome: 'food', engine: engine)
      expect(result[:effectiveness]).to be_between(0.0, 1.0)
    end

    it 'returns full effectiveness for fresh stimulus' do
      result = client.associate(label: 'fresh', outcome: 'reward', engine: engine)
      expect(result[:effectiveness]).to be_within(0.001).of(1.0)
    end

    it 'returns reduced effectiveness after pre-exposure' do
      20.times { engine.expose_stimulus(label: 'pre_exposed') }
      result = client.associate(label: 'pre_exposed', outcome: 'reward', engine: engine)
      expect(result[:effectiveness]).to be < 0.5
    end

    it 'includes blocked flag' do
      result = client.associate(label: 'fresh', outcome: 'test', engine: engine)
      expect(result).to have_key(:blocked)
    end

    it 'marks association as blocked after saturation' do
      50.times { engine.expose_stimulus(label: 'saturated') }
      result = client.associate(label: 'saturated', outcome: 'anything', engine: engine)
      expect(result[:blocked]).to be(true)
    end
  end

  describe '#disinhibit' do
    it 'returns not_found for unknown stimulus' do
      result = client.disinhibit(label: 'unknown', engine: engine)
      expect(result[:status]).to eq(:not_found)
    end

    it 'reduces inhibition after significant event' do
      10.times { engine.expose_stimulus(label: 'conditioned') }
      result = client.disinhibit(label: 'conditioned', intensity: 1.0, engine: engine)
      expect(result[:new_score]).to be < result[:prior_score]
    end

    it 'defaults intensity to 1.0' do
      5.times { engine.expose_stimulus(label: 'cue') }
      result = client.disinhibit(label: 'cue', engine: engine)
      expect(result[:reduction]).to be > 0.0
    end
  end

  describe '#novel_stimuli' do
    it 'returns hash with stimuli and count' do
      result = client.novel_stimuli(engine: engine)
      expect(result).to have_key(:stimuli)
      expect(result).to have_key(:count)
    end

    it 'returns novel stimuli list' do
      engine.expose_stimulus(label: 'new_thing')
      result = client.novel_stimuli(engine: engine)
      expect(result[:count]).to eq(1)
    end

    it 'count matches stimuli array size' do
      engine.expose_stimulus(label: 'a')
      engine.expose_stimulus(label: 'b')
      result = client.novel_stimuli(engine: engine)
      expect(result[:count]).to eq(result[:stimuli].size)
    end
  end

  describe '#most_inhibited' do
    before do
      5.times  { engine.expose_stimulus(label: 'mid') }
      20.times { engine.expose_stimulus(label: 'top') }
    end

    it 'returns hash with stimuli and count' do
      result = client.most_inhibited(engine: engine)
      expect(result).to have_key(:stimuli)
      expect(result).to have_key(:count)
    end

    it 'respects limit parameter' do
      result = client.most_inhibited(limit: 1, engine: engine)
      expect(result[:stimuli].size).to eq(1)
    end

    it 'returns most inhibited first' do
      result = client.most_inhibited(limit: 2, engine: engine)
      expect(result[:stimuli].first[:label]).to eq('top')
    end
  end

  describe '#inhibition_report' do
    it 'returns a report hash' do
      result = client.inhibition_report(engine: engine)
      expect(result[:total_stimuli]).to eq(0)
    end

    it 'reflects current engine state' do
      engine.expose_stimulus(label: 'tracked')
      result = client.inhibition_report(engine: engine)
      expect(result[:total_stimuli]).to eq(1)
    end

    it 'includes all required report fields' do
      result = client.inhibition_report(engine: engine)
      %i[total_stimuli novel_count inhibited_count saturated_count mean_inhibition max_inhibition label_breakdown].each do |key|
        expect(result).to have_key(key)
      end
    end
  end
end
