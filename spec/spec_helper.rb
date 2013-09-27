require 'qcuke'

module Qcuke
  class TestQueue < Array
    def poll(*args, &blk); each(&blk); end
  end
  
  class TestMessage
    attr_reader :body, :url
    
    def initialize(body)
      @body = body
    end
  end
end

RSpec.configure do |config|
  config.order = "random"
end
