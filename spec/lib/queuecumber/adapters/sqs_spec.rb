require 'spec_helper'
require 'queuecumber/adapters/sqs'

module Queuecumber
  class TestQueue < Array
    def poll(*args, &blk); each(&blk); end
  end
  
  class TestMessage
    attr_reader :body, :url
    
    def initialize(body)
      @body = body
    end
  end
  
  describe SQSAdapter do
    let(:adapter) { SQSAdapter.new("name") }
    let(:sqs)     { double "sqs", as_null_object: true }
    let(:queue)   { double "queue", url: "url" }

    describe "#sqs" do
      it "returns a new AWS::SQS object initialized with all the options except :max_batch_size, :idle_timeout, and :wait_time_seconds" do
        AWS::SQS.should_receive(:new).with({ foo: "bar" })
        a = SQSAdapter.new("name", foo: "bar", max_batch_size: 99, idle_timeout: 99, wait_time_seconds: 99)
        a.sqs
      end
    end

    %w(max_batch_size idle_timeout wait_time_seconds).each do |attr|
      context "##{attr}" do
        it "returns options[:#{attr}] if present" do
          adapter.options[attr.to_sym] = "some val"
          expect(adapter.send(attr)).to eq "some val"
        end

        it "defaults to 10" do
          expect(adapter.send(attr)).to eq 10
        end
      end
    end

    describe "#queue" do
      before do
        adapter.stub(sqs: sqs)
      end
                     
      it "finds the queue" do
        adapter.should_receive(:find).and_return(true)
        adapter.queue
      end
      
      context "if a queue with the same name exists" do
        before do
          adapter.stub(find: queue)
        end
        
        it "returns the existing queue" do
          expect(adapter.queue).to eq queue
        end
      end
      
      context "if a queue with the same name does not exist" do
        before do
          adapter.stub(find: false)
        end
      
        it "returns a newly-created queue" do
          adapter.should_receive(:create!).and_return(queue)
          expect(adapter.queue).to eq queue
        end
      end
    end

    describe "#cleanup!(prefix)" do
      let(:queues)          { double "sqs queues" }
      let(:my_prefix)       { "my prefix" }
      let(:queue_to_delete) { double "queue to delete", url: "url" }
      
      before do
        adapter.stub(sqs: sqs)
      end

      it "finds all queues with the given prefix" do
        sqs.should_receive(:queues).and_return(queues)
        queues.should_receive(:with_prefix).with(my_prefix).and_return([])
        adapter.cleanup!(my_prefix)
      end

      it "deletes each matching queue" do
        sqs.stub(queues: queues)
        queues.stub(with_prefix: Array(queue_to_delete))
        queue_to_delete.should_receive(:delete)
        adapter.cleanup!(my_prefix)        
      end

      it "supresses AWS::SQS::Errors::NonExistentQueue errors raised when SQS is in an inconsistent state" do
        sqs.stub(queues: queues)
        queues.stub(with_prefix: Array(queue_to_delete))
        queue_to_delete.stub(:delete).and_raise(AWS::SQS::Errors::NonExistentQueue)
        adapter.cleanup!(my_prefix)        
      end
    end
    
    describe "#find" do
      let(:queues) { double "sqs queues" }
      
      before do
        adapter.stub(sqs: sqs)
      end
      
      it "uses the SQS api to find the named queue" do
        sqs.should_receive(:queues).and_return(queues)
        queues.should_receive(:named).with("name").and_return(queue)
        expect(adapter.find).to eq queue        
      end
    end

    describe "#create!" do
      let(:queues) { double "sqs queues" }
      
      before do
        adapter.stub(sqs: sqs)
      end
      
      it "uses the SQS api to create the named queue" do
        sqs.should_receive(:queues).and_return(queues)
        queues.should_receive(:create).with("name").and_return(queue)
        expect(adapter.create!).to eq queue
      end
    end

    describe "#populate!(data)" do
      let(:data) { [1, 2, 3] }

      before do
        adapter.stub(queue: queue, max_batch_size: 99)
      end
      
      it "iterates over :max_batch_size slices of data" do
        data.should_receive(:each_slice).with(99)
        adapter.populate!(data)
      end

      it "stringifies the data items and batch_sends them to the queue" do
        queue.should_receive(:batch_send).with(%w(1 2 3))
        adapter.populate!(data)        
      end
    end

    describe "#empty!" do
      it "calls #each, discarding the yielded data" do
        adapter.should_receive(:each)
        adapter.empty!
      end
    end
    
    describe "#each" do
      let(:queue) { TestQueue.new }
      let(:data)  { %w(1 2 3).map { |b| TestMessage.new(b) } }

      before do
        adapter.stub(queue: queue, idle_timeout: 12, wait_time_seconds: 34)
        queue.push(*data)
      end
      
      it "polls the queue with the configured idle_timeout and wait_time_seconds" do
        queue.should_receive(:poll).with(hash_including(idle_timeout: 12, wait_time_seconds: 34))
        adapter.each
      end

      it "casts each queue message body to integer and yields it" do
        expect { |b| adapter.each(&b) }.to yield_successive_args(1, 2, 3)     
      end
    end
  end
end
