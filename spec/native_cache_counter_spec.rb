# frozen_string_literal: true

require_relative "spec_helper"

require "database_cleaner"
DatabaseCleaner.strategy = :deletion

RSpec.describe "ActiveRecord::CounterCache" do
  before(:each) do
    DatabaseCleaner.clean
  end

  include_examples "test ActiveRecord::CounterCache interface", WithNativeCounter::Article, WithNativeCounter::Comment
end
