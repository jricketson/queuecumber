require 'cucumber'

module Cucumber
  module Ast
    class Features
      def count
        @features.count
      end

      def feature_queue=(fq)
        @feature_queue = fq
      end

      def feature_queue
        @feature_queue ||= Queuecumber.instance
      end
      
      #
      # Monkey-patch to iterate over features pulled from the feature queue
      #
      def each(&proc)
        feature_queue.each do |feature_index|
          if feature = @features[feature_index]
            puts "\nRunning '#{feature.title}'"
            yield feature
          else # presumably cucumber has filtered it out
            puts "\nSkipped file #{feature_index}"
          end
        end
      end
    end
  end
end
