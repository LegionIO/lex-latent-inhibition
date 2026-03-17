# frozen_string_literal: true

require_relative 'lib/legion/extensions/latent_inhibition/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-latent-inhibition'
  spec.version       = Legion::Extensions::LatentInhibition::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Latent Inhibition'
  spec.description   = 'Pre-exposure effect modeling for brain-modeled agentic AI — familiar stimuli resist new associations'
  spec.homepage      = 'https://github.com/LegionIO/lex-latent-inhibition'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-latent-inhibition'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-latent-inhibition'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-latent-inhibition'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-latent-inhibition/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-latent-inhibition.gemspec Gemfile LICENSE README.md]
  end
  spec.require_paths = ['lib']
end
