require 'forwardable'
require 'securerandom'
require 'cucumber'

module Qcuke
  # Wouldn't it be great to have autload_relative symmetrical with
  # require_relative?
  adapter_loadpath = File.expand_path("adapters", File.dirname(__FILE__))
  $LOAD_PATH.unshift(adapter_loadpath) unless $LOAD_PATH.include?(adapter_loadpath)

  autoload :SQSAdapter, File.join(adapter_loadpath, "sqs")

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
      @adapter ||= options[:adapter] || SQSAdapter.new(name, options[:adapter_options])
    end

    def prefix
      @prefix ||= options[:prefix] || "QCUKE"
    end

    def name
      @name ||= options[:name] || "#{prefix}_#{SecureRandom.uuid}"
    end

    def enabled?
      !!(options[:enable] || YAML::load(env['QCUKE'] || ""))
    end

    def setup!
      t = Time.now
      puts "emptying queue '#{name}' #{t}"
      empty!
      puts "calculating scenarios #{Time.now - t}"
      data = scenarios
      puts "scenarios #{Time.now - t}"

      puts "populating queue '#{name}'"
      populate!(data)
      puts "finished populating queue '#{name}'"
    end

    def scenarios
      Dir["#{feature_file_dir}/**/*.feature"].collect { |feature_path|
        Cucumber::FeatureFile.new(feature_path).parse([], {}).feature_elements.collect { |element|
          element.location.to_s
        }
      }.flatten
    end

    def cleanup!(target_prefix = nil)
      target_prefix ||= prefix
      adapter.cleanup!(target_prefix)
    end

    # TODO: inject Cucumber runtime/configuration object
    def feature_file_dir
      @feature_file_dir ||=
        options[:feature_file_dir] ||
        ENV['QCUKE_FEATURE_FILE_DIR'] ||
        (Module.const_defined?(:Rails) && Rails.root || FileUtils.pwd)
    end

    private

    def debug
      if ENV['QCUKE_DEBUG']
        puts "Initialized FeatureQueue:"
        %w(prefix name).each do |attr|
          puts "#{attr}: #{self.send(attr)}"
        end
      end
    end
  end
end
