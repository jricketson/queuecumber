require 'spec_helper'

module Queuecumber
  describe Queuecumber do
    before do
      Queuecumber.reset
    end
    
    describe ".init" do
      let(:options) { Hash.new }
      
      it "initializes a new FeatureQueue with the given options" do
        FeatureQueue.should_receive(:new).with(options).and_call_original
        Queuecumber.init(options)
      end

      it "checks whether the FeatureQueue is enabled" do
        FeatureQueue.any_instance.should_receive(:enabled?)
        Queuecumber.init
      end

      it "returns the FeatureQueue" do
        Queuecumber.init.should be_a(FeatureQueue)
      end

      context "when the FeatureQueue is enabled" do
        before do
          FeatureQueue.any_instance.stub(:enabled? => true)
        end
        
        it "loads the monkey patches" do
          Queuecumber.should_receive(:require_relative).with('./queuecumber/cucumber_ext/ast/features')
          Queuecumber.init
        end
      end

      context "when the FeatureQueue is not enabled" do
        before do
          FeatureQueue.any_instance.stub(:enabled? => false)
        end
        
        it "does not load the monkey patches" do
          Queuecumber.should_not_receive(:require_relative).with('./queuecumber/cucumber_ext/ast/features')
          Queuecumber.init
        end
      end

      context "called second and subsequent times" do
        it "returns the same instance of FeatureQueue" do
          first_fq = Queuecumber.init
          Queuecumber.init.should eq first_fq
        end
      end
    end

    describe ".instance" do
      it "returns the FeatureQueue instance initialized in .init" do
        fq = Queuecumber.init
        Queuecumber.instance.should eq fq
      end
    end

    describe ".reset" do
      it "nulls the instance" do
        Queuecumber.init
        Queuecumber.reset
        Queuecumber.instance.should be_nil
      end
    end
  end
end
