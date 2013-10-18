unless ARGV.any? {|a| a =~ /^gems/} # Don't load anything when running the gems:* tasks
  require 'qcuke'

  def init(*args); Qcuke.init(*args); end

  namespace :qcuke do
    desc "Delete all queues with given prefix (defaults to 'QCUKE')"
    task :cleanup, [:prefix] do |_, options|
      init(options).cleanup!(options[:prefix])
    end

    desc "Find-or-create named cucumber queue, empty it, populate it"
    task :setup, [:name, :feature_file_dir, :profile, :tags] do |_, options|
      init(options).setup!
    end

    desc "Run features off the queue in parallel with [num_cpus]"
    task :parallel, [:count, :pattern, :options] do |t, args|
      require 'parallel_tests'
      require 'parallel_tests/qcuke/runner'

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

