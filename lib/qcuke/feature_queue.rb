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

    def profile
      @profile ||= options[:profile] || 'default'
    end

    def tags
      @tags ||= (options[:tags] || '').split('&') || []
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
      tag_arguments = tags.map {|tag| "--tag #{tag}"}.join(' ')
      json = `bundle exec cucumber -d -f json -p #{profile} #{tag_arguments} #{feature_file_dir}`
      features = JSON.parse(json)
      features.map do |feature|
        feature['elements'].map do |element|
          next unless ['Scenario', 'Scenario Outline'].include? element['keyword']
          num_steps = element['steps'].count
          { name: "#{strip_pwd(feature['uri'])}:#{element['line']}", num_steps: num_steps }
        end
      end.flatten.compact.sort_by {|s| -s[:num_steps]}.map{|s| s[:name]}
   end

    def strip_pwd(path)
      path.start_with?(pwd) ? path[pwd.length+1..-1] : path
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
