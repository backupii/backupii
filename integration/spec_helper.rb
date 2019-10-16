# frozen_string_literal: true

require "backup"

Dir[File.expand_path("support/**/*.rb", __dir__)].each { |f| require f }

RSpec.configure do |c|
  c.include BackupSpec::ExampleHelpers
end
