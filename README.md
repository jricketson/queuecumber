Queuecumber [![travis-ci](https://secure.travis-ci.org/lonelyplanet/queuecumber.png)](https://secure.travis-ci.org/lonelyplanet/queuecumber)
==================

Faster cukes!

Queuecumber lets you distribute your cucumber test build step over
many servers/nodes/machines so you can run them in parallel.

All it does is push references to your feature files onto a queue (AWS
SQS by default). Each cucumber process you boot can then be configured
to work off the queue, splitting the total run time approximately
equally between them.

## Usage

1) Populate the queue

     # In your Rails/project root directory:
     
     rake queuecumber:setup[my_queue]

2) Work off the queue

      # Run this in as many processes/machines as you want
      # from your Rails/project root directory:
      
      QUEUECUMBER=my_queue cucumber --your --normal --cucumber config

Unless the `QUEUECUMBER` environment variable is set, cucumber will
run normally. This is probably what you want in dev.

### Jenkins

### parallel_tests

### AWS SQS

### Limitations

## Installation

Add this line to your application's Gemfile:

    gem 'queuecumber'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install queuecumber

Then add `features/support/queuecumber.rb`:

    Queuecumber.init(name: ENV['QUEUECUMBER'])

This line is responsible for initializing a `FeatureQueue` with the
correct name, and monkey-patching Cucumber.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## TODO

* write documentation
* add Jenkins master job code
* add `parallel_test` helper
* expose options to Rake task
* logging/debug
