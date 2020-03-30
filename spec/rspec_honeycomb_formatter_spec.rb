# frozen_string_literal: true

RSpec.describe RSpecHoneycombFormatter do # rubocop:disable RSpec/FilePath
  it 'has a version number' do
    expect(RSpecHoneycombFormatter::VERSION).not_to be nil
  end

  # test testcases
  # before(:each) do
  #   skip "Don't run tests"
  # end

  # it {
  #   actual = 'foo'
  #   expect(actual).to eq('bar')
  # }

  # pending do
  #   actual = 'features'
  #   expect(actual).to eq('more features')
  # end
end
