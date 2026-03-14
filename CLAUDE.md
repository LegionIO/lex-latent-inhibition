# lex-latent-inhibition

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-latent-inhibition`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::LatentInhibition`

## Purpose

Familiarity-based stimulus filtering for LegionIO agents. Models the psychological phenomenon where pre-exposed stimuli are more slowly associated with outcomes — familiar things are harder to learn from. Tracks exposure counts per stimulus, builds up an inhibition score with each non-consequential exposure, and reduces association effectiveness proportionally. Supports disinhibition to restore learning capacity for re-evaluated stimuli.

## Gem Info

- **Require path**: `legion/extensions/latent_inhibition`
- **Ruby**: >= 3.4
- **License**: MIT
- **Registers with**: `Legion::Extensions::Core`

## File Structure

```
lib/legion/extensions/latent_inhibition/
  version.rb
  helpers/
    constants.rb          # Limits, rates, thresholds, labels
    stimulus_record.rb    # StimulusRecord value object
    inhibition_engine.rb  # In-memory stimulus registry + inhibition logic
  runners/
    latent_inhibition.rb  # Runner module

spec/
  legion/extensions/latent_inhibition/
    helpers/
      constants_spec.rb
      stimulus_record_spec.rb
      inhibition_engine_spec.rb
    runners/latent_inhibition_spec.rb
  spec_helper.rb
```

## Key Constants

```ruby
MAX_STIMULI          = 500
INHIBITION_RATE      = 0.03   # inhibition score increment per non-consequential exposure
DISINHIBITION_RATE   = 0.2    # inhibition score decrement on disinhibit call
NOVELTY_THRESHOLD    = 3      # exposure_count < 3 -> novel stimulus

INHIBITION_LABELS = {
  (0.8..)     => :highly_inhibited,
  (0.5...0.8) => :moderately_inhibited,
  (0.2...0.5) => :slightly_inhibited,
  (..0.2)     => :minimally_inhibited
}

NOVELTY_LABELS = {
  novel:       'First encounter; high association potential',
  familiar:    'Pre-exposed; inhibition building',
  established: 'Well-known; association effectiveness reduced'
}
```

## Helpers

### `Helpers::StimulusRecord` (class)

Tracks inhibition state for a single stimulus.

| Attribute | Type | Description |
|---|---|---|
| `id` | String | stimulus identifier (provided by caller) |
| `label` | String | human-readable stimulus name |
| `exposure_count` | Integer | total exposures including consequential ones |
| `inhibition_score` | Float (0..1) | accumulated inhibition from non-consequential exposures |

Key methods:
- `expose!` — increments exposure_count; increments inhibition_score by INHIBITION_RATE (cap 1.0)
- `associate!(outcome)` — records an outcome association; `effectiveness = 1.0 - inhibition_score`
- `disinhibit!` — decrements inhibition_score by DISINHIBITION_RATE (floor 0.0)
- `novel?` — exposure_count < NOVELTY_THRESHOLD
- `inhibition_label` — :highly_inhibited / :moderately_inhibited / :slightly_inhibited / :minimally_inhibited

### `Helpers::InhibitionEngine` (class)

Registry of all stimulus records.

| Method | Description |
|---|---|
| `expose_stimulus(stimulus_id:, label:)` | creates or retrieves record, calls expose! |
| `attempt_association(stimulus_id:, outcome:)` | associates outcome with reduced effectiveness |
| `disinhibit(stimulus_id:)` | reduces inhibition for a stimulus |
| `novel_stimuli` | stimuli with exposure_count < NOVELTY_THRESHOLD |
| `most_inhibited(limit:)` | top N stimuli by inhibition_score |
| `inhibition_report` | counts by inhibition level, avg inhibition, novel count |
| `prune_if_needed` | removes lowest-exposure records when over MAX_STIMULI |

## Runners

Module: `Legion::Extensions::LatentInhibition::Runners::LatentInhibition`

Private state: `@engine` (memoized `InhibitionEngine` instance).

| Runner Method | Parameters | Description |
|---|---|---|
| `expose` | `stimulus_id:, label: stimulus_id` | Register a stimulus exposure |
| `associate` | `stimulus_id:, outcome:` | Attempt association with inhibition-reduced effectiveness |
| `disinhibit` | `stimulus_id:` | Reduce inhibition for a stimulus |
| `novel_stimuli` | (none) | All stimuli below novelty threshold |
| `most_inhibited` | `limit: 10` | Top N most inhibited stimuli |
| `inhibition_report` | (none) | Summary statistics across all stimuli |

## Integration Points

- **lex-memory**: latent inhibition can gate trace reinforcement — stimuli with high inhibition_score reduce the `reinforce` effectiveness when storing new memories about familiar domains.
- **lex-curiosity**: highly inhibited stimuli are less likely to generate wonders — familiar things do not trigger curiosity.
- **lex-learning-rate**: high inhibition on a domain provides a signal to lower the learning rate (familiar content is absorbed more slowly).
- **lex-metacognition**: `LatentInhibition` is listed under `:cognition` capability category.

## Development Notes

- Stimulus IDs are provided by callers — they can be any string (domain names, action types, content hashes). There is no schema enforcement.
- `associate!` returns the `effectiveness` value (1.0 - inhibition_score). A caller recording a memory trace at effectiveness 0.3 should reduce the trace's reinforcement strength accordingly.
- `disinhibit!` reduces inhibition by a fixed DISINHIBITION_RATE regardless of current inhibition level. Multiple disinhibit calls are needed to fully restore a highly inhibited stimulus.
- `novel?` threshold is hardcoded at NOVELTY_THRESHOLD = 3. A stimulus exposed 3 times is no longer considered novel even if inhibition is still low.
- No decay actor — inhibition scores only decrease via explicit `disinhibit` calls. There is no passive forgetting of familiarity.
