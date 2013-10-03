unless ARGV.any? {|a| a =~ /^gems/} # Don't load anything when running the gems:* tasks
  require 'queuecumber'

  def init(*args); Queuecumber.init(*args); end

  namespace :queuecumber do
    desc "Delete all queues with given prefix (defaults to 'QUEUECUMBER')"
    task :cleanup, [:prefix] do |_, options|
      init(options).cleanup!(options[:prefix])
    end

    desc "Find-or-create named cucumber queue, empty it, populate it"
    task :setup, [:name, :feature_file_dir] do |_, options|
      init(options).setup!
    end
  end
end
