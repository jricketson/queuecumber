require 'spec_helper'
require 'queuecumber/cucumber_ext/ast/features'

module Cucumber
  module Ast
    describe Features do
      let(:features) { Features.new }
      let(:queue)    { Queuecumber::TestQueue.new }
      let(:feature)  { double "feature", title: "my feature" }

      describe ".feature_queue" do
        let(:instance) { double "instance" }
            
        it "by default returns Queuecumber.instance" do
          Queuecumber.should_receive(:instance).and_return(instance)
          expect(Features.feature_queue).to eq instance
        end
      end
      
      describe "#feature_queue" do
        it "returns the class's feature queue" do
          Features.should_receive(:feature_queue).and_return(queue)
          expect(features.feature_queue).to eq queue
        end
      end
      
      describe "#each" do
        before do
          features.stub(feature_queue: queue)
          features.instance_variable_set(:@features, [feature])
        end
        
        it "iterates over the feature queue" do
          queue.should_receive(:each)
          features.each { |_| }
        end

        context "when cucumber has loaded a matching feature" do
          before do
            queue << 0
          end
          
          it "yields the matching feature" do
            expect { |b| features.each(&b) }.to yield_with_args(feature)
          end
        end

        context "when cucumber has loaded a matching feature" do
          before do
            queue << 1
          end
          
          it "does not yield" do
            expect { |b| features.each(&b) }.not_to yield_control
          end
        end
      end
    end
  end
end
