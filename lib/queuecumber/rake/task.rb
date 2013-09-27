unless ARGV.any? {|a| a =~ /^gems/} # Don't load anything when running the gems:* tasks
  require 'queuecumber'

  def init(*args); Queuecumber.init(*args); end
  
  namespace :queuecumber do
    desc "Delete all queues with given prefix (defaults to 'QUEUECUMBER')"
    task :cleanup, [:prefix] do |_, options|
      init(options).cleanup!(options[:prefix])
    end

    desc "Find-or-create named cucumber queue, empty it, populate it"
    task :setup, [:name] do |_, options|
      init(options).setup!
    end

    desc "Run features off the queue in parallel with [num_cpus]"
    task :parallel, [:count, :pattern, :options] do |t, args|
      require 'parallel_tests'
      
      count, pattern, options = ParallelTests::Tasks.parse_args(args)
      cli = ParallelTests::CLI.new.run([
                                        "--type", "test",
                                        "features",
                                        "--type", "qcuke",
                                        "-n", count.to_s,
                                        "--pattern", pattern,
                                        "--test-options", options
                                       ])
    end
  end
end

