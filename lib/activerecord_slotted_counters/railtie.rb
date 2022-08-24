# frozen_string_literal: true

module ActiveRecordSlottedCounters # :nodoc:
  class Railtie < ::Rails::Railtie # :nodoc:
    config.app_generators do
      # TODO can I use slotted_counters:install naming without relative import?
      require_relative '../../lib/generators/slotted_counters/install_generator.rb'
    end

    initializer "extend ActiveRecord with  ActiveRecordSlottedCounters" do |_app|
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.include ActiveRecordSlottedCounters::HasSlottedCounter
      end
    end
  end
end
