# frozen_string_literal: true

module ActiveRecordSlottedCounters # :nodoc:
  class Railtie < ::Rails::Railtie # :nodoc:
    initializer "extend ActiveRecord with  ActiveRecordSlottedCounters" do |_app|
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.send :include, ActiveRecordSlottedCounters::HasSlottedCounter
      end
    end
  end
end
