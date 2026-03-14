# frozen_string_literal: true

RSpec.describe Legion::Extensions::LatentInhibition::Helpers::InhibitionEngine do
  subject(:engine) { described_class.new }

  describe '#expose_stimulus' do
    it 'returns a hash with stimulus data' do
      result = engine.expose_stimulus(label: 'bell')
      expect(result).to be_a(Hash)
      expect(result[:label]).to eq('bell')
    end

    it 'increments exposure_count on repeated calls' do
      engine.expose_stimulus(label: 'bell')
      result = engine.expose_stimulus(label: 'bell')
      expect(result[:exposure_count]).to eq(2)
    end

    it 'raises inhibition_score over time' do
      result1 = engine.expose_stimulus(label: 'tone')
      result2 = engine.expose_stimulus(label: 'tone')
      expect(result2[:inhibition_score]).to be > result1[:inhibition_score]
    end

    it 'tracks novel status correctly' do
      result = engine.expose_stimulus(label: 'new_thing')
      expect(result[:novel]).to be(true)
    end

    it 'marks stimulus as not novel after threshold exposures' do
      threshold = Legion::Extensions::LatentInhibition::Helpers::Constants::NOVELTY_THRESHOLD
      threshold.times { engine.expose_stimulus(label: 'frequent') }
      result = engine.expose_stimulus(label: 'frequent')
      expect(result[:novel]).to be(false)
    end

    it 'creates distinct stimuli for different labels' do
      engine.expose_stimulus(label: 'a')
      engine.expose_stimulus(label: 'b')
      report = engine.inhibition_report
      expect(report[:total_stimuli]).to eq(2)
    end
  end

  describe '#attempt_association' do
    it 'returns a hash with outcome and effectiveness' do
      result = engine.attempt_association(label: 'bell', outcome: 'food')
      expect(result[:outcome]).to eq('food')
      expect(result[:effectiveness]).to be_between(0.0, 1.0)
    end

    it 'returns high effectiveness for novel stimulus' do
      result = engine.attempt_association(label: 'new', outcome: 'reward')
      expect(result[:effectiveness]).to be_within(0.001).of(1.0)
    end

    it 'returns reduced effectiveness after many exposures' do
      20.times { engine.expose_stimulus(label: 'old') }
      result = engine.attempt_association(label: 'old', outcome: 'reward')
      expect(result[:effectiveness]).to be < 0.5
    end

    it 'marks association as blocked when effectiveness is very low' do
      50.times { engine.expose_stimulus(label: 'saturated') }
      result = engine.attempt_association(label: 'saturated', outcome: 'something')
      expect(result[:blocked]).to be(true)
    end

    it 'includes inhibition_score and inhibition_label' do
      result = engine.attempt_association(label: 'bell', outcome: 'food')
      expect(result).to have_key(:inhibition_score)
      expect(result).to have_key(:inhibition_label)
    end
  end

  describe '#disinhibit' do
    it 'returns not_found status for unknown label' do
      result = engine.disinhibit(label: 'unknown', intensity: 1.0)
      expect(result[:status]).to eq(:not_found)
    end

    it 'reduces inhibition_score for known stimulus' do
      10.times { engine.expose_stimulus(label: 'bell') }
      result = engine.disinhibit(label: 'bell', intensity: 1.0)
      expect(result[:new_score]).to be < result[:prior_score]
    end

    it 'returns prior_score and new_score' do
      5.times { engine.expose_stimulus(label: 'tone') }
      result = engine.disinhibit(label: 'tone', intensity: 0.5)
      expect(result[:prior_score]).to be > 0.0
      expect(result[:new_score]).to be < result[:prior_score]
    end

    it 'includes reduction amount' do
      5.times { engine.expose_stimulus(label: 'cue') }
      result = engine.disinhibit(label: 'cue', intensity: 1.0)
      expect(result[:reduction]).to be_within(0.001).of(result[:prior_score] - result[:new_score])
    end
  end

  describe '#novel_stimuli' do
    it 'returns empty array when no stimuli exist' do
      expect(engine.novel_stimuli).to be_empty
    end

    it 'returns novel stimuli' do
      engine.expose_stimulus(label: 'fresh')
      stimuli = engine.novel_stimuli
      expect(stimuli.map { |s| s[:label] }).to include('fresh')
    end

    it 'excludes familiar stimuli' do
      threshold = Legion::Extensions::LatentInhibition::Helpers::Constants::NOVELTY_THRESHOLD
      (threshold + 1).times { engine.expose_stimulus(label: 'old') }
      stimuli = engine.novel_stimuli
      expect(stimuli.map { |s| s[:label] }).not_to include('old')
    end
  end

  describe '#most_inhibited' do
    before do
      5.times  { engine.expose_stimulus(label: 'low') }
      20.times { engine.expose_stimulus(label: 'high') }
      1.times  { engine.expose_stimulus(label: 'fresh') }
    end

    it 'returns stimuli ordered by inhibition_score descending' do
      stimuli = engine.most_inhibited(limit: 3)
      scores = stimuli.map { |s| s[:inhibition_score] }
      expect(scores).to eq(scores.sort.reverse)
    end

    it 'respects the limit parameter' do
      stimuli = engine.most_inhibited(limit: 2)
      expect(stimuli.size).to be <= 2
    end

    it 'includes the most inhibited stimulus first' do
      stimuli = engine.most_inhibited(limit: 1)
      expect(stimuli.first[:label]).to eq('high')
    end
  end

  describe '#inhibition_report' do
    it 'returns empty report when no stimuli exist' do
      report = engine.inhibition_report
      expect(report[:total_stimuli]).to eq(0)
      expect(report[:mean_inhibition]).to eq(0.0)
    end

    it 'counts total stimuli correctly' do
      engine.expose_stimulus(label: 'a')
      engine.expose_stimulus(label: 'b')
      expect(engine.inhibition_report[:total_stimuli]).to eq(2)
    end

    it 'counts novel stimuli' do
      engine.expose_stimulus(label: 'new')
      report = engine.inhibition_report
      expect(report[:novel_count]).to eq(1)
    end

    it 'computes mean_inhibition' do
      engine.expose_stimulus(label: 'x')
      report = engine.inhibition_report
      expect(report[:mean_inhibition]).to be > 0.0
    end

    it 'includes max_inhibition' do
      10.times { engine.expose_stimulus(label: 'heavy') }
      engine.expose_stimulus(label: 'light')
      report = engine.inhibition_report
      expect(report[:max_inhibition]).to be > report[:mean_inhibition]
    end

    it 'includes label_breakdown hash' do
      engine.expose_stimulus(label: 'x')
      report = engine.inhibition_report
      expect(report[:label_breakdown]).to be_a(Hash)
    end

    it 'counts saturated stimuli' do
      50.times { engine.expose_stimulus(label: 'saturated') }
      report = engine.inhibition_report
      expect(report[:saturated_count]).to eq(1)
    end
  end

  describe '#prune_if_needed' do
    it 'prunes oldest stimuli when MAX_STIMULI is exceeded' do
      max = Legion::Extensions::LatentInhibition::Helpers::Constants::MAX_STIMULI
      (max + 5).times { |i| engine.expose_stimulus(label: "stim_#{i}") }
      report = engine.inhibition_report
      expect(report[:total_stimuli]).to be <= max
    end
  end

  describe '#to_h' do
    it 'includes stimuli and report keys' do
      engine.expose_stimulus(label: 'test')
      h = engine.to_h
      expect(h).to have_key(:stimuli)
      expect(h).to have_key(:report)
    end
  end
end
