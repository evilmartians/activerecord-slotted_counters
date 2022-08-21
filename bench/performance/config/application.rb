# frozen_string_literal: true

require File.expand_path("../boot", __FILE__)

require "rails"
require "active_record/railtie"
require "activerecord-slotted_counters"

module Dummy
  class Application < Rails::Application
    config.eager_load = false
  end
end
