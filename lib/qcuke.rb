require "qcuke/version"
require "ruby_ext/hash"
require "qcuke/feature_queue"

module Qcuke
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
    require_relative './qcuke/cucumber_ext/ast/features'
  end
end
