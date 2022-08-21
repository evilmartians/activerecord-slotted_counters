# frozen_string_literal: true

require "active_record"
require "activerecord_slotted_counters/version"
require "activerecord_slotted_counters/railtie" if defined?(Rails::Railtie)

require "activerecord_slotted_counters/has_slotted_counter"
require "activerecord_slotted_counters/model"
require "activerecord_slotted_counters/class_methods"
require "activerecord_slotted_counters/instance_methods"
