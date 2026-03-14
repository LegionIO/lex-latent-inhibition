# frozen_string_literal: true

require 'legion/extensions/latent_inhibition/version'
require 'legion/extensions/latent_inhibition/helpers/constants'
require 'legion/extensions/latent_inhibition/helpers/stimulus_record'
require 'legion/extensions/latent_inhibition/helpers/inhibition_engine'
require 'legion/extensions/latent_inhibition/runners/latent_inhibition'
require 'legion/extensions/latent_inhibition/client'

module Legion
  module Extensions
    module LatentInhibition
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
