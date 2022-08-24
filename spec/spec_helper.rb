# frozen_string_literal: true

begin
  require "pry-byebug"
rescue LoadError
end
ENV["RAILS_ENV"] = "test"

require "active_record"
require "activerecord-slotted_counters"

# TODO is it ok?
ActiveRecord::Base.include ActiveRecordSlottedCounters::HasSlottedCounter

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec

  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.order = :random
  Kernel.srand config.seed

  config.before(:each, db: true) do
    ActiveRecord::Base.connection.begin_transaction(joinable: false)
  end

  config.append_after(:each, db: true) do |ex|
    ActiveRecord::Base.connection.rollback_transaction
  end
end
