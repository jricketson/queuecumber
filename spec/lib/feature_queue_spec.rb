require 'spec_helper'
require 'queuecumber/adapters/sqs'

module Queuecumber
  class TestAdapter
    attr_accessor :data

    def initialize
      @data = Array.new
    end
    
    def empty!
      @data.clear
    end

    def populate!(new_data)
      @data = @data + new_data
    end      
  end
  
  describe FeatureQueue do
    let(:fq)   { FeatureQueue.new }
    let(:name) { "name" }
    
    describe "#options" do
      let(:my_options) { Hash.new }
      let(:fq)         { FeatureQueue.new(my_options) }
      
      it "returns initialized options" do
        expect(fq.options).to eq my_options
      end
    end

    describe "#env" do
      let(:my_env) { double "env" }
      
      it "defaults to ENV" do
        expect(fq.env).to eq ENV
      end

      it "returns options[:env] if present" do
        fq.options[:env] = my_env
        expect(fq.env).to eq my_env
      end
    end

    describe "#adapter" do
      let(:my_adapter)  { double "adapter" }

      context "when options[:adapter] is not present" do
        let(:sqs_options) { Hash.new }
        
        before do
          fq.options[:sqs_options] = sqs_options
          fq.stub(name: name)
        end

        it "defaults to new SQSAdapter initialized with the queue name and options[:sqs_options]" do
          SQSAdapter.should_receive(:new).with(name, sqs_options).and_return(my_adapter)
          expect(fq.adapter).to eq my_adapter
        end
      end

      context "when options[:adapter] is present" do
        before do
          fq.options[:adapter] = my_adapter
        end
        
        it "returns options[:adapter]" do
          expect(fq.adapter).to eq my_adapter
        end
      end        
    end

    describe "#prefix" do
      context "when options[:prefix] is present" do
        before do
          fq.options[:prefix] = "my_prefix"
        end
        
        it "returns options[:prefix]" do
          expect(fq.prefix).to eq "my_prefix"
        end
      end

      context "when options[:prefix] is not present" do
        it "defaults to 'QUEUECUMBER'" do
          expect(fq.prefix).to eq "QUEUECUMBER"
        end
      end
    end
    
    describe "#name" do
      context "when options[:name] is present" do
        before do
          fq.options[:name] = name
        end

        it "returns options[:name]" do
          expect(fq.name).to eq name
        end
      end

      context "when options[:name] is not present" do
        before do
          fq.stub(prefix: "my_prefix")
          SecureRandom.stub(uuid: "uuid")
        end
          
        it "returns '$PREFIX_$UUID'" do
          expect(fq.name).to eq "my_prefix_uuid"
        end
      end
    end

    describe "#enabled?" do
      context "when options[:enable] is present" do
        before do
          fq.options[:enable] = true
        end
        
        it "returns options[:enable] cast to boolean" do
          expect(fq.enabled?).to be_true
        end
      end

      context "when options[:enable] is not present" do
        before do
          fq.stub(env: Hash.new)
        end
        
        [nil, '', false, "false"].each do |v|
          it "returns false if env['QUEUECUMBER'] is \"#{v}\"" do
            fq.env['QUEUECUMBER'] = v
            expect(fq).not_to be_enabled
          end
        end

        ['on', "true", "1"].each do |v|
          it "returns true if env['QUEUECUMBER'] is \"#{v}\"" do
            fq.env['QUEUECUMBER'] = v
            expect(fq).to be_enabled
          end
        end
      end
    end

    describe "#setup!" do
      let(:test_adapter) { TestAdapter.new.tap { |ta| ta.data = [1, 2, 3] } }
      let(:feature_file_indices) { [9, 10, 11] }
      
      before do
        fq.stub(adapter: test_adapter)
        fq.stub(feature_file_indices: feature_file_indices)
      end
      
      it "calls adapter#empty!, then adapter#populate! with the feature_file_indices" do
        test_adapter.should_receive(:empty!).and_call_original
        test_adapter.should_receive(:populate!).with([9, 10, 11]).and_call_original
        fq.setup!
        test_adapter.data.should eq feature_file_indices
      end
    end

    describe "#delete!" do
      let(:my_adapter) { double "adapter" }
      
      before do
        fq.stub(adapter: my_adapter)
      end

      it "delegates to the adapter" do
        my_adapter.should_receive(:delete!)
        fq.delete!
      end
    end

    describe "#cleanup!" do
      let(:my_adapter) { double "adapter" }
      let(:my_prefix)  { "my prefix" }
      
      before do
        fq.stub(adapter: my_adapter, prefix: my_prefix)
      end

      it "delegates to the adapter" do
        my_adapter.should_receive(:cleanup!).with(my_prefix)
        fq.cleanup!(my_prefix)
      end
    end

    describe "#each" do
      let(:my_adapter) { double "adapter" }
      
      before do
        fq.stub(adapter: my_adapter)
      end

      it "delegates to the adapter" do
        my_adapter.should_receive(:each)
        fq.each
      end
    end

    describe "#feature_file_dir" do
      context "when options[:feature_file_dir] is present" do
        before do
          fq.options[:feature_file_dir] = "ffd"
        end
        
        it "returns options[:feature_file_dir]" do
          expect(fq.feature_file_dir).to eq "ffd"
        end
      end

      context "when options[:feature_file_dir] is present" do
        context "when Rails loaded" do
          let(:rails) { double }
          
          before do
            stub_const("Rails", rails)
          end

          it "returns Rails.root" do
            Rails.should_receive(:root).and_return("rails_root")
            expect(fq.feature_file_dir).to eq("rails_root")
          end
        end

        context "when Rails is not loaded" do
          before do
            FileUtils.stub(pwd: "pwd")
          end
          
          it "returns name of the current directory" do
            expect(fq.feature_file_dir).to eq "pwd"
          end
        end
      end
    end
    
    describe "#feature_file_indices" do
      it "returns a shuffled array of integers from 0..(1 - total number of feature files)" do
        Dir.stub(:[]).and_return(%w(feature1 feature2))
        expect(fq.feature_file_indices).to match_array([0, 1])
      end
    end
  end
end
