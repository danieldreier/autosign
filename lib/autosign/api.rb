# the purpose of this class is to set up logging, configuration, etc and
# provide an easy abstraction for the CLI, puppet function, and any other
# tooling to use to interact with this gem.

module Autosign
  class Api
    def initialize(settings = {})
      puts "settings: " + settings.to_s
      @config = Autosign::Config.new(settings)
    end
  end
end
