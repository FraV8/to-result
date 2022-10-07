require 'minitest/autorun'
require 'mocha/minitest'
require 'byebug'

require './lib/to-result'
require './tests/support/fake_logger'

class ToResultTest < Minitest::Test
  include ToResultMixin

  def setup
    super
    @value = 'hello world!'
  end

  def teardown
    super

    # reset the configuration after each test
    ToResultMixin.configure { |c| c = {} }
  end

  def test_string
    assert ToResult { @value } == Success(@value)
  end

  def test_success
    expected = Success(@value)
    assert ToResult { expected } == Success(expected)
  end

  def test_exception
    expected = StandardError.new(@value)
    assert ToResult { raise expected } == Failure(expected)
  end

  def test_exception_included_in_exceptions_list
    expected = ArgumentError.new(@value)
    assert ToResult([ArgumentError]) { raise expected } == Failure(expected)
  end

  def test_exception_not_included_in_exceptions_list
    expected = NameError.new(@value)
    assert_raises(NameError) { ToResult([ArgumentError]) { raise expected } }
  end

  def test_yield_failure
    expected = Failure(@value)
    # this will raise a Dry::Monads::Do::Halt exception
    assert ToResult { yield expected } == expected
  end

  def test_yield_failure_exception
    expected = Failure(StandardError.new(@value))
    # this will raise a Dry::Monads::Do::Halt exception
    assert ToResult { yield expected } == expected
  end

  def test_on_error
    FakeLogger.expects(:log_error).once

    ToResultMixin.configure do |c|
      c.on_error = Proc.new { FakeLogger.log_error }
    end

    ToResult { raise StandardError.new(@value) }
  end
end
