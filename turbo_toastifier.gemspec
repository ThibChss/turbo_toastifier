# frozen_string_literal: true

require_relative "lib/turbo_toastifier/version"

Gem::Specification.new do |spec|
  spec.name = "turbo_toastifier"
  spec.version = TurboToastifier::VERSION
  spec.authors = ["Thibault C."]
  spec.email = ["thibault.chassine@sline.io"]

  spec.summary = 'A Rails gem for beautiful toast notifications using Turbo and Stimulus'
  spec.description = 'TurboToastifier provides a simple way to display flash messages as toast notifications in Rails applications using Turbo Streams and Stimulus controllers.'
  spec.homepage = 'https://github.com/ThibChss/turbo_toastifier'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'rails', '>= 7.0'
  spec.add_dependency 'stimulus-rails', '>= 1.0'
  spec.add_dependency 'turbo-rails', '>= 1.0'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
