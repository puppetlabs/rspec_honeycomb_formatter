# frozen_string_literal: true

require 'rspec_honeycomb_formatter/version'
require 'rspec/core/formatters'
require 'honeycomb-beeline'

Honeycomb.configure do |config|
end
process_span = Honeycomb.start_span(name: File.basename($PROGRAM_NAME))
process_span.add_field('process.full_name', $PROGRAM_NAME)
process_span.add_field('process.args', ARGV)
at_exit do
  if $ERROR_INFO&.is_a?(SystemExit)
    process_span.add_field('process.exit_code', $ERROR_INFO.status)
  elsif $ERROR_INFO
    process_span.add_field('process.exit_code', $ERROR_INFO.class.name)
  else
    process_span.add_field('process.exit_code', 'unknown')
  end
  process_span.send
end

# A custom formatter for RSpec that posts messages to https://honeycomb.io for analysis
class RSpecHoneycombFormatter
  ::RSpec::Core::Formatters.register self, :start,
                                     :example_group_started, :example_group_finished,
                                     :example_started, :example_passed, :example_failed, :example_pending, :message,
                                     :stop, :start_dump, :seed

  def initialize(_output)
    @group_stack = []
  end

  def start(notification)
    @start_span = Honeycomb.start_span(name: 'rspec')
    @start_span.add_field('rspec.example_count', notification.count)
    @start_span.add_field('rspec.load_time_ms', notification.load_time * 1000)
  end

  def stop(notification)
    @start_span.add_field('rspec.failed_count', notification.failed_examples.size)
    @start_span.add_field('rspec.pending_count', notification.pending_examples.size)
    @start_span.send
  end

  def start_dump(notification)
    # puts "start_dump: #{notification}"
  end

  def example_group_started(notification)
    @group_stack.push(group_span = Honeycomb.start_span(name: notification.group.description))
    group_span.add_field('rspec.type', 'group')
    group_span.add_field('rspec.file_path', notification.group.file_path)
    group_span.add_field('rspec.location', notification.group.location)
  end

  def example_group_finished(_notification)
    group_span = @group_stack.pop
    group_span.send
  end

  def example_started(notification)
    @example_span = Honeycomb.start_span(name: 'unknown')
    @example_span.add_field('rspec.type', 'example')
    @example_span.add_field('rspec.file_path', notification.example.file_path)
    @example_span.add_field('rspec.location', notification.example.location)
  end

  def example_passed(notification)
    @example_span.add_field('rspec.result', 'passed')
    @example_span.add_field('name', notification.example.description)
    @example_span.add_field('rspec.description', notification.example.description)
    @example_span.send
  end

  def example_failed(notification)
    @example_span.add_field('rspec.result', 'failed')
    @example_span.add_field('name', notification.example.description)
    @example_span.add_field('rspec.description', notification.example.description)
    @example_span.add_field('rspec.message', strip_ansi(notification.message_lines.join("\n")))
    @example_span.add_field('rspec.backtrace', notification.formatted_backtrace.join("\n"))
    @example_span.send
  end

  def example_pending(notification)
    @example_span.add_field('rspec.result', 'pending')
    @example_span.add_field('name', notification.example.description)
    @example_span.add_field('rspec.description', notification.example.description)
    @example_span.add_field('rspec.message', strip_ansi(notification.message_lines.join("\n")))
    @example_span.add_field('rspec.backtrace', notification.formatted_backtrace.join("\n"))
    @example_span.send
  end

  def seed(notification)
    @start_span.add_field('rspec.seed', notification.seed) if notification.seed_used?
  end

  def message(notification)
    puts "message: #{notification}"
  end

  private

  def strip_ansi(string)
    string.gsub(%r{\e\[([\d;]+)m}, '')
  end
end
