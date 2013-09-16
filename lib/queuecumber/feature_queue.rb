require 'forwardable'
require 'securerandom'

# Wouldn't it be great to have autload_relative symmetrical with
# require_relative?
adapter_loadpath = File.expand_path("/adapters", File.dirname(__FILE__))
$LOAD_PATH.unshift(adapter_loadpath) unless $LOAD_PATH.include?(adapter_loadpath)

autoload :SQSAdapter, "/home/dave/dev/queuecumber/lib/queuecumber/adapters/sqs"

module Queuecumber  
  class FeatureQueue
    extend Forwardable
    
    attr_reader :options
    attr_writer :env, :adapter, :name

    def_delegators :adapter, :empty!, :populate!, :delete!, :each
    
    def initialize(options = {})
      @options = options
    end

    def env
      @env ||= options[:env] || ENV
    end

    def adapter
      @adapter ||= options[:adapter] || SQSAdapter.new(name, options[:sqs_options])
    end

    def prefix
      @prefix ||= options[:prefix] || "QUEUECUMBER"
    end

    def name
      @name ||= options[:name] || "#{prefix}_#{SecureRandom.uuid}"
    end
    
    def enabled?
      !!(options[:enable] || YAML::load(env['QUEUECUMBER'] || ""))
    end

    def setup!
      empty!
      populate!(feature_file_indices)
    end

    # TODO: inject Cucumber runtime/configuration object
    def feature_file_dir
      @feature_file_dir ||= options[:feature_file_dir] || (Module.const_defined?(:Rails) && Rails.root || FileUtils.pwd)
    end

    # TODO: inject Cucumber runtime/configuration object
    def feature_file_indices
      total_number_of_features = Dir["#{feature_file_dir}/**/*.feature"].count
      feature_file_indices     = (0..total_number_of_features - 1).to_a.shuffle
    end
  end
end
