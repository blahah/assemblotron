require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start

def capture_stdout(&block)
  original_stdout = $stdout
  $stdout = fake = StringIO.new
  begin
    yield
  ensure
    $stdout = original_stdout
  end
  fake.string
end

require 'minitest/autorun'
require 'minitest/reporters'
require 'shoulda-context'
require 'assemblotron'

# We want clean error messages through the logger, no ugly backtraces
# because the user doesn't care about them, unless they specifically ask for
# them with --loglevel debug

module Minitest
  module Reporters
    class BaseReporter < Minitest::StatisticsReporter
      def print_info(e, name=true)
        print "#{e.exception.class.to_s}: " if name
        print e.message
        puts filter_backtrace(e.backtrace)[1]
      end
    end
  end
end

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
