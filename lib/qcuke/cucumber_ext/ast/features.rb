require 'cucumber'

module Cucumber
  module Ast
    class Features
      def self.feature_queue=(fq)
        @feature_queue = fq
      end

      def self.feature_queue
        @feature_queue ||= Qcuke.instance
      end

      def count
        @features.count
      end

      def feature_queue
        self.class.feature_queue
      end

      #
      # Monkey-patch to iterate over features pulled from the feature queue
      #
      def each(&proc)
        feature_queue.each do |feature_string|
          puts "getting #{feature_string} from queue"
          feature = FeatureFile.new(feature_string).parse([], {})
          puts "\nRunning '#{feature.title}'"
          yield feature
        end
      end
    end
  end
end
