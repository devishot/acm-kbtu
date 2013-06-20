# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
AcmKbtu::Application.initialize!

Time::DATE_FORMATS[:well_datetime] = "%d-%b  %H:%M"