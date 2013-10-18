require 'aws-sdk'

module Qcuke
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
      sqs.queues.create(name, visibility_timeout: 36000).tap do |q|
        debug "- Created queue '#{q.url}'"
      end
    end

    def find
      debug "- Finding queue '#{name}'"
      sqs.queues.named(name).tap do |q|
        debug "  #{q.url}"
      end
    rescue AWS::SQS::Errors::NonExistentQueue
        debug "  not found"
      nil
    end

    def populate!(data)
      debug "- Populating queue with #{data.count} messages"
      data.each_slice(max_batch_size) do |batch|        
        queue.batch_send(batch.map(&:to_s))
      end
    end

    # Pull all messages off the queue and discard them
    def empty!
      queue.poll(idle_timeout: 1, wait_time_seconds: wait_time_seconds) do |_|
        #throw it away
      end
    end

    def each(&proc)
      queue.poll(initial_timeout: 240, idle_timeout: idle_timeout, wait_time_seconds: wait_time_seconds) do |msg|
        index = msg.body.to_i
        yield index
      end      
    end

    private

    def debug(msg)
      puts(msg) if ENV['QCUKE_DEBUG']
    end
  end
end
