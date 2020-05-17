
require_relative "../lib/autosign"
require 'coveralls'
Coveralls.wear!
@fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

# Generate X509 CSR (certificate signing request) with SAN (Subject Alternative Name) extension and sign it with the RSA key
# common_name, organization, country, state_name, locality, _domain_list = []
# Usage example
# generate_csr({
#   common_mame: 'acme.com',
#   organization: 'ACME Corp.',
#   country: 'US',
#   state_name: 'California',
#   locality: 'San Francisco',
#   csr_attributes: {'challengePassword' => 'sdfasdfds'}
# }
# )
def generate_csr(opts)
  # create signing key
  signing_key = OpenSSL::PKey::RSA.new 2048

  # create certificate subject
  subject = OpenSSL::X509::Name.new [
    ['CN', opts[:common_name]],
    ['O', opts[:organization]],
    ['C', opts[:country]],
    ['ST', opts[:state_name]],
    ['L', opts[:locality]]
  ]

  # create CSR
  csr = OpenSSL::X509::Request.new
  csr.version = 0
  csr.subject = subject
  csr.public_key = signing_key.public_key
  
  if opts[:csr_attributes]
    opts[:csr_attributes].each do |oid, value|
      encoded = OpenSSL::ASN1::PrintableString.new(value.to_s)
  
      attr_set = OpenSSL::ASN1::Set.new([encoded])
      csr.add_attribute(OpenSSL::X509::Attribute.new(oid, attr_set))
    end
  end

  # sign CSR with the signing key
  csr.sign signing_key, OpenSSL::Digest::SHA256.new

  csr.to_pem
end


RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

# The settings below are suggested to provide a good initial experience
# with RSpec, but feel free to customize to your heart's content.
=begin
  # These two settings work together to allow you to limit a spec run
  # to individual examples or groups you care about by tagging them with
  # `:focus` metadata. When nothing is tagged with `:focus`, all examples
  # get run.
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options. We recommend
  # you configure your source control system to ignore this file.
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Limits the available syntax to the non-monkey patched syntax that is
  # recommended. For more details, see:
  #   - http://myronmars.to/n/dev-blog/2012/06/rspecs-new-expectation-syntax
  #   - http://www.teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
  #   - http://myronmars.to/n/dev-blog/2014/05/notable-changes-in-rspec-3#new__config_option_to_disable_rspeccore_monkey_patching
  config.disable_monkey_patching!

  # This setting enables warnings. It's recommended, but in some cases may
  # be too noisy due to issues in dependencies.
  config.warnings = true

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = 'doc'
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed
=end
end
