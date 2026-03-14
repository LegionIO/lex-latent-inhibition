# lex-latent-inhibition

Familiarity-based stimulus filtering for LegionIO agents. Part of the LegionIO cognitive architecture extension ecosystem (LEX).

## What It Does

`lex-latent-inhibition` models the psychological phenomenon where pre-exposed stimuli are harder to learn from. Each non-consequential exposure builds up an inhibition score, reducing association effectiveness. Novel stimuli (fewer than 3 exposures) have full learning potential. Familiar stimuli can be disinhibited to restore their learning capacity when they become contextually relevant again.

Key capabilities:

- **Exposure tracking**: counts non-consequential stimulus encounters
- **Inhibition accumulation**: +0.03 per exposure (cap 1.0)
- **Association effectiveness**: `1.0 - inhibition_score` — familiar stimuli are harder to associate
- **Disinhibition**: -0.2 per call to restore learning capacity
- **Novelty detection**: exposure count < 3 = novel, full association potential

## Installation

Add to your Gemfile:

```ruby
gem 'lex-latent-inhibition'
```

Or install directly:

```
gem install lex-latent-inhibition
```

## Usage

```ruby
require 'legion/extensions/latent_inhibition'

client = Legion::Extensions::LatentInhibition::Client.new

# Register exposures for a familiar stimulus
10.times { client.expose(stimulus_id: :deployment_warning, label: 'Deployment warning alert') }

# Attempt to learn something from it (effectiveness will be reduced)
result = client.associate(stimulus_id: :deployment_warning, outcome: 'requires_review')
# => { stimulus_id: :deployment_warning, outcome: 'requires_review', effectiveness: 0.7 }

# Disinhibit when the stimulus is genuinely important
client.disinhibit(stimulus_id: :deployment_warning)

# Find novel stimuli (full learning potential)
client.novel_stimuli

# Find most inhibited stimuli
client.most_inhibited(limit: 5)

# Summary report
client.inhibition_report
```

## Runner Methods

| Method | Description |
|---|---|
| `expose` | Register a stimulus exposure (builds inhibition) |
| `associate` | Attempt an association with inhibition-reduced effectiveness |
| `disinhibit` | Reduce a stimulus's inhibition score |
| `novel_stimuli` | All stimuli with fewer than 3 exposures |
| `most_inhibited` | Top N stimuli by inhibition score |
| `inhibition_report` | Summary: counts by inhibition level, avg inhibition |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
