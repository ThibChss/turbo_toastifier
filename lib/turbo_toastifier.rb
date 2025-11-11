# frozen_string_literal: true

require_relative 'turbo_toastifier/version'
require_relative 'turbo_toastifier/configuration'
require_relative 'turbo_toastifier/engine'
require_relative 'turbo_toastifier/flash/preparator'
require_relative 'turbo_toastifier/controller'
require_relative 'turbo_toastifier/controller/render'
require_relative 'turbo_toastifier/controller/redirect'
require_relative 'turbo_toastifier/controller/turbo_frame'
require_relative 'turbo_toastifier/view_helper'

module TurboToastifier
  class Error < StandardError; end
end
