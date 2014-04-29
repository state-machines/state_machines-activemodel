
require 'state_machines/integrations/active_model'
Dir['./spec/support/**/*.rb'].sort.each { |f| require f }
I18n.enforce_available_locales = true
RSpec.configure do |config|
  config.raise_errors_for_deprecations!
end

