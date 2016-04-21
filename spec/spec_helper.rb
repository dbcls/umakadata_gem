$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'umakadata'
require 'umakadata/linkset'

RSpec.configure do |config|
  original_stderr = $stderr
  original_stdout = $stdout

  # Redirect stderr and stdout to /dev/null
  config.before(:all) do
    $stderr = File.open(File::NULL, "w")
    $stdout = File.open(File::NULL, "w")
  end

  # Restore original output
  config.after(:all) do
    $stderr = original_stderr
    $stdout = original_stdout
  end
end
