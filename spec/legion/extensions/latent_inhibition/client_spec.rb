# frozen_string_literal: true

RSpec.describe Legion::Extensions::LatentInhibition::Client do
  let(:client) { described_class.new }

  it 'responds to all runner methods' do
    %i[expose associate disinhibit novel_stimuli most_inhibited inhibition_report].each do |method|
      expect(client).to respond_to(method)
    end
  end

  it 'maintains state across calls on the default engine' do
    client.expose(label: 'persistent')
    client.expose(label: 'persistent')
    report = client.inhibition_report
    expect(report[:total_stimuli]).to eq(1)
  end

  it 'demonstrates the full latent inhibition cycle' do
    # Pre-expose stimulus without consequence — builds inhibition
    10.times { client.expose(label: 'neutral_tone') }

    # Now try to form an association
    result = client.associate(label: 'neutral_tone', outcome: 'shock')
    expect(result[:effectiveness]).to be < 0.7

    # Compare with a novel stimulus
    novel_result = client.associate(label: 'new_tone', outcome: 'shock')
    expect(novel_result[:effectiveness]).to be > result[:effectiveness]
  end

  it 'disinhibits a pre-exposed stimulus so it can learn again' do
    10.times { client.expose(label: 'primed') }
    before_eff = client.associate(label: 'primed', outcome: 'test')[:effectiveness]

    client.disinhibit(label: 'primed', intensity: 1.0)
    after_eff = client.associate(label: 'primed', outcome: 'test')[:effectiveness]

    expect(after_eff).to be > before_eff
  end

  it 'identifies novel stimuli correctly' do
    client.expose(label: 'brand_new')
    result = client.novel_stimuli
    labels = result[:stimuli].map { |s| s[:label] }
    expect(labels).to include('brand_new')
  end
end
