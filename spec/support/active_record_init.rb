# frozen_string_literal: true

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define do
  # define schema here
end

ActiveRecord::Base.logger = Logger.new($stdout) if ENV["LOG"]
