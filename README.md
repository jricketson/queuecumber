Queuecumber [![travis-ci](https://travis-ci.org/lonelyplanet/queuecumber.png)](https://travis-ci.org/lonelyplanet/queuecumber)
==================

Quicker cukes!

[![Code Climate](https://codeclimate.com/github/lonelyplanet/queuecumber.png)](https://codeclimate.com/github/lonelyplanet/queuecumber)

Queuecumber lets you distribute your cucumber test build step over
many servers/nodes/machines so you can run them in parallel.

All it does is push references to your feature files onto a queue (AWS
SQS by default). Each cucumber process you boot can then be configured
to work off the queue, splitting the total run time approximately
equally between them.

The benefits of a queue are:

 * you don't need to know in advance how many cucumber processes you
   will run
 * you don't need to maintain a store of how long each feature lasts
   to get an (approximate) balance across processes

It's simple to drop into an existing Jenkins setup.

## Usage

1) Configure Cucumber

    # in e.g. features/support/queuecumber.rb:

    Queuecumber.init(name: ENV['QUEUECUMBER'])

If you intend to run multiple Cucumber processes on the same machine,
you'll probably also need to ensure DB isolation (see 'parallel_tests'
below).

2) Populate the queue

     # In your Rails/project root directory:
     
     rake queuecumber:setup[my_queue]

3) Work off the queue

      # Run this in as many processes/machines as you want
      # from your Rails/project root directory:
      
      QUEUECUMBER=my_queue cucumber --your --normal --cucumber config

Unless the `QUEUECUMBER` environment variable is set, Cucumber will
run normally. This is probably what you want in dev.

### Jenkins

TODO

### parallel_tests

Queuecumber can replace [`parallel_tests`](https://github.com/grosser/parallel_tests) in CI,
but the two can interoperate.

Just run `rake queuecumber:parallel` with the same options as you pass
to `rake parallel:features`.

### AWS SQS

Queuecumber uses [AWS SQS](http://aws.amazon.com/sqs/) by default,
building on the [`aws-sdk` gem](http://docs.aws.amazon.com/AWSRubySDK/latest/).
You'll need your own valid AWS credentials to use SQS.

If you're running Queuecumber on an EC2 instance configured with a valid IAM
profile, no extra configuration is required. `aws-sdk` will
automatically interrogate the EC2 metadata provider for the credentials.

Otherwise, for example on your local dev machine, set `AWS_ACCESS_KEY_ID` and
`AWS_SECRET_ACCESS_KEY` ENV vars.

### Custom queue adapters

Pull requests welcome.

Alternatively, you can implement your own queue adapter locally:

    # lib/queuecumber/my_adapter.rb

    require 'queuecumber'
    
    module Queuecumber
      class MyAdapter

        def initialize(name, options = {})
          # to implement
        end

        def name
          # return queue name
        end
        
        def empty!
          # empty queue 
        end

        def cleanup!(prefix)
          # delete all queues matching /^#{prefix}/
        end

        def create!
          # create queue
        end

        def find
          # return queue if it exists, or falsey if it does not
        end

        def each(&proc)
          # yield feature index
        end

        def populate(feature_indices)
          # push each feature index onto the queue
        end
      end
    end

To use the custom adapter:

    # command-line

    rake queuecumber:

    # in e.g. features/support/queuecumber.rb:

    require 'lib/queuecumber/my_adapter'
    
    if name = ENV['QUEUECUMBER']
      my_adapter = Queuecumber::MyAdapter.new(name, some: options)
      Queuecumber.init(name: name, adapter: my_adapter)
    end

### Limitations

Unfortunately Cucumber does not expose its iterator over features. So
Queuecumber has to monkey-patch `Features#each` to yield the next feature
from the queue.

Secondly, populating the queue does not (yet) respect Cucumber
tags/filters. All it does is glob the `features` directory to get a
count of how many `.feature` files there are in total, and push a
reference to each one onto the queue.

That said, it does work and we have been using it successfully for
several months.

Ideas and improvements are very welcome! I expect Cucumber 2.0 will be
easier to work with.

## TODO

* expose initializer/options to Rake task
* add Jenkins master job code
* document options
* logging/debug

## Related projects

* [test-queue](https://github.com/tmm1/test-queue)
* [parallel_tests](https://github.com/grosser/parallel_tests)

## Author

[Dave Nolan](http://kapoq.com) / [lonelyplanet.com](http://www.lonelyplanet.com)
