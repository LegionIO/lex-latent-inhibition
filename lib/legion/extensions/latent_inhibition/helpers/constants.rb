# frozen_string_literal: true

module Legion
  module Extensions
    module LatentInhibition
      module Helpers
        module Constants
          MAX_STIMULI          = 500
          INHIBITION_RATE      = 0.03
          DISINHIBITION_RATE   = 0.2
          NOVELTY_THRESHOLD    = 3

          INHIBITION_LABELS = {
            (0.0..0.2) => :uninhibited,
            (0.2..0.4) => :low,
            (0.4..0.6) => :moderate,
            (0.6..0.8) => :high,
            (0.8..1.0) => :saturated
          }.freeze

          NOVELTY_LABELS = {
            true  => :novel,
            false => :familiar
          }.freeze
        end
      end
    end
  end
end
