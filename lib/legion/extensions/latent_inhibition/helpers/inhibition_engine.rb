# frozen_string_literal: true

module Legion
  module Extensions
    module LatentInhibition
      module Helpers
        class InhibitionEngine
          include Constants

          def initialize
            @stimuli = {}
          end

          def expose_stimulus(label:)
            stimulus = find_or_create(label)
            stimulus.expose!
            prune_if_needed
            stimulus.to_h
          end

          def attempt_association(label:, outcome:)
            stimulus = find_or_create(label)
            effectiveness = stimulus.associate!(outcome: outcome)
            {
              label:            label,
              outcome:          outcome,
              effectiveness:    effectiveness,
              inhibition_score: stimulus.inhibition_score,
              inhibition_label: stimulus.inhibition_label,
              blocked:          effectiveness < 0.1
            }
          end

          def disinhibit(label:, intensity:)
            return { label: label, status: :not_found } unless @stimuli.key?(label)

            stimulus = @stimuli[label]
            prior_score = stimulus.inhibition_score
            stimulus.disinhibit!(intensity: intensity)
            {
              label:       label,
              prior_score: prior_score,
              new_score:   stimulus.inhibition_score,
              reduction:   (prior_score - stimulus.inhibition_score).round(10)
            }
          end

          def novel_stimuli
            @stimuli.values.select(&:novel?).map(&:to_h)
          end

          def most_inhibited(limit: 10)
            @stimuli.values
                    .sort_by { |s| -s.inhibition_score }
                    .first(limit)
                    .map(&:to_h)
          end

          def inhibition_report
            stimuli = @stimuli.values
            return empty_report if stimuli.empty?

            {
              total_stimuli:    stimuli.size,
              novel_count:      stimuli.count(&:novel?),
              inhibited_count:  stimuli.count { |s| s.inhibition_score > 0.0 },
              saturated_count:  stimuli.count { |s| s.inhibition_label == :saturated },
              mean_inhibition:  (stimuli.sum(&:inhibition_score) / stimuli.size).round(10),
              max_inhibition:   stimuli.map(&:inhibition_score).max.round(10),
              label_breakdown:  label_breakdown(stimuli)
            }
          end

          def prune_if_needed
            return if @stimuli.size <= Constants::MAX_STIMULI

            overflow = @stimuli.size - Constants::MAX_STIMULI
            oldest = @stimuli.values.sort_by { |s| s.last_exposed_at || Time.at(0) }.first(overflow)
            oldest.each { |s| @stimuli.delete(s.label) }
          end

          def to_h
            {
              stimuli: @stimuli.transform_values(&:to_h),
              report:  inhibition_report
            }
          end

          private

          def find_or_create(label)
            @stimuli[label] ||= StimulusRecord.new(label: label)
          end

          def empty_report
            {
              total_stimuli:   0,
              novel_count:     0,
              inhibited_count: 0,
              saturated_count: 0,
              mean_inhibition: 0.0,
              max_inhibition:  0.0,
              label_breakdown: {}
            }
          end

          def label_breakdown(stimuli)
            stimuli.group_by(&:inhibition_label).transform_values(&:count)
          end
        end
      end
    end
  end
end
