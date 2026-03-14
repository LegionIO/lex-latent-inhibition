# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module LatentInhibition
      module Helpers
        class StimulusRecord
          include Constants

          attr_reader :id, :label, :exposure_count, :inhibition_score, :last_exposed_at, :associations

          def initialize(label:)
            @id              = SecureRandom.uuid
            @label           = label
            @exposure_count  = 0
            @inhibition_score = 0.0
            @last_exposed_at = nil
            @associations    = []
          end

          def expose!
            @exposure_count  += 1
            @last_exposed_at  = Time.now.utc
            @inhibition_score = (@inhibition_score + Constants::INHIBITION_RATE).clamp(0.0, 1.0).round(10)
            self
          end

          def associate!(outcome:)
            effectiveness = (1.0 - @inhibition_score).clamp(0.0, 1.0).round(10)
            @associations << { outcome: outcome, effectiveness: effectiveness, recorded_at: Time.now.utc }
            effectiveness
          end

          def disinhibit!(intensity:)
            reduction = (Constants::DISINHIBITION_RATE * intensity.clamp(0.0, 1.0)).round(10)
            @inhibition_score = (@inhibition_score - reduction).clamp(0.0, 1.0).round(10)
            self
          end

          def novel?
            @exposure_count < Constants::NOVELTY_THRESHOLD
          end

          def inhibition_label
            Constants::INHIBITION_LABELS.find { |range, _| range.cover?(@inhibition_score) }&.last || :saturated
          end

          def to_h
            {
              id:               @id,
              label:            @label,
              exposure_count:   @exposure_count,
              inhibition_score: @inhibition_score,
              inhibition_label: inhibition_label,
              novel:            novel?,
              last_exposed_at:  @last_exposed_at,
              associations:     @associations.dup
            }
          end
        end
      end
    end
  end
end
