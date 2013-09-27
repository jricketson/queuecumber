require 'spec_helper'

module Qcuke
  describe Qcuke do
    before do
      Qcuke.reset
    end
    
    describe ".init" do
      let(:options) { Hash.new }
      
      it "initializes a new FeatureQueue with the given options" do
        FeatureQueue.should_receive(:new).with(options).and_call_original
        Qcuke.init(options)
      end

      it "checks whether the FeatureQueue is enabled" do
        FeatureQueue.any_instance.should_receive(:enabled?)
        Qcuke.init
      end

      it "returns the FeatureQueue" do
        Qcuke.init.should be_a(FeatureQueue)
      end

      context "when the FeatureQueue is enabled" do
        before do
          FeatureQueue.any_instance.stub(:enabled? => true)
        end
        
        it "loads the monkey patches" do
          Qcuke.should_receive(:require_relative).with('./qcuke/cucumber_ext/ast/features')
          Qcuke.init
        end
      end

      context "when the FeatureQueue is not enabled" do
        before do
          FeatureQueue.any_instance.stub(:enabled? => false)
        end
        
        it "does not load the monkey patches" do
          Qcuke.should_not_receive(:require_relative).with('./qcuke/cucumber_ext/ast/features')
          Qcuke.init
        end
      end

      context "called second and subsequent times" do
        it "returns the same instance of FeatureQueue" do
          first_fq = Qcuke.init
          Qcuke.init.should eq first_fq
        end
      end
    end

    describe ".instance" do
      it "returns the FeatureQueue instance initialized in .init" do
        fq = Qcuke.init
        Qcuke.instance.should eq fq
      end
    end

    describe ".reset" do
      it "nulls the instance" do
        Qcuke.init
        Qcuke.reset
        Qcuke.instance.should be_nil
      end
    end
  end
end
