require 'aws-sdk'

module Queuecumber
  class SQSAdapter
    attr_reader   :name
    attr_accessor :options
    
    def initialize(name, options = {})
      @name    = name
      @options = options || {}
    end

    def sqs
      sqs_options = options.except(:max_batch_size, :idle_timeout, :wait_time_seconds)
      @sqs ||= AWS::SQS.new(sqs_options)
    end
    
    def max_batch_size
      @max_batch_size ||= options[:max_batch_size] || 10
    end

    def idle_timeout
      @idle_timeout ||= options[:idle_timeout] || 10
    end

    def wait_time_seconds
      @wait_time_seconds ||= options[:wait_time_seconds] || 10
    end

    def queue
      @queue ||= (find || create!)
    end

    def cleanup!(prefix)
      sqs.queues.with_prefix(prefix).each do |q|
        debug "- Deleting #{q.url}"
        # SQS is eventually consistent: supress errors due to inconsistency
        q.delete rescue AWS::SQS::Errors::NonExistentQueue
      end
    end
    
    def create!
      sqs.queues.create(name)
    end

    def find
      sqs.queues.named(name)
    end

    def populate!(data)
      data.each_slice(max_batch_size) do |batch|
        queue.batch_send(batch.map(&:to_s))
      end
    end

    # Pull all messages off the queue and discard them
    def empty!
      each
    end

    def each(&proc)
      queue.poll(idle_timeout: idle_timeout, wait_time_seconds: wait_time_seconds) do |msg|
        index = msg.body.to_i
        yield index
      end      
    end
  end
end
