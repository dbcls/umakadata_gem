require 'bundler/setup'
require 'webmock/rspec'

require 'umakadata'

GEM_ROOT = File.expand_path('..', __dir__)

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def suppress_stderr
  original_stderr = $stderr.clone

  ret = nil
  begin
    $stderr.reopen(File.new('/dev/null', 'w'))
    ret = yield
  rescue StandardError => e
    $stderr.reopen(original_stderr)
    raise e
  ensure
    $stderr.reopen(original_stderr)
  end

  ret
end
