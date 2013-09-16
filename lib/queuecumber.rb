require "queuecumber/version"
require "ruby_ext/hash"
require "queuecumber/feature_queue"

module Queuecumber
  extend self
  
  def init(options = {})    
    @instance ||= FeatureQueue.new(options).tap do |fq|
      load_monkey_patches if fq.enabled?
    end
  end

  def reset
    @instance = nil
  end

  def instance
    @instance
  end

  private
  
  def load_monkey_patches
    require_relative './queuecumber/cucumber_ext/ast/features'
  end
end
