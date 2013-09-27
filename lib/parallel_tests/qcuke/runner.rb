require 'parallel_tests/cucumber/runner'

module ParallelTests
  module Qcuke
    class Runner < ParallelTests::Cucumber::Runner
      class << self
        def name
          'cucumber'
        end

        def tests_in_groups(tests, num_groups, options={})
          tests = find_tests(tests, options).select(&:present?)
          # ParallelTests::CLI#run_tests_in_parallel uses Array#index
          # to determine which number process it's launching - so each
          # member of the array of groups needs to be distinct,
          # otherwise #index will always return 0 and TEST_ENV_NUMBER
          # will always set to be 0
          num_groups.times.map { |i| tests.rotate(i) }
        end

        def determine_executable
          "bundle exec cucumber"
        end
      end
    end
  end
end

