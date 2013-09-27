require 'cucumber'

module Cucumber
  module Ast
    class Features
      def self.feature_queue=(fq)
        @feature_queue = fq
      end
      
      def self.feature_queue
        @feature_queue ||= Queuecumber.instance
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
        feature_queue.each do |feature_index|
          # If there is no matching feature, presumably it has been
          # filtered out by cucumber tags
          if feature = @features[feature_index]
            yield feature
          end
        end
      end
    end
  end
end
