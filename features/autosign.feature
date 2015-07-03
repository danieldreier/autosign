Feature: Generate autosign key
  In order to sign puppet certificates automatically
  I want to generate autosign keys programatically
  So I don't have to use static strings as keys

  Scenario Outline: Generate new token
    Given a pre-shared key of "secret"
      And a hostname of "<HOSTNAME>"
      And the current time is <TIME>
    When I run `autosign generate --hostname <HOSTNAME> --valid-for <VALIDFOR> --<ONETIME>`
    Then the output should contain exactly "<TOKEN>"
    And the exit status should be 0

    Examples:
      | TIME       | VALIDFOR | EXITCODE | ONETIME  | HOSTNAME        | TOKEN |
      | 1435000001 | 3600     | 0        | onetime  | foo.example.com | eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJkYXRhIjoiZGF0YSIsImV4cCI6MTQzNTAwMzYwMX0.LF7MoeE_3UzV5NOHDRKrazBa1-b-js8Mrq-ioMI2eNLoJOzQZo8tOo0a4gqtBh2OcuOXORpIeD-fm7u6SvvsVw |
      | 1435000001 | 900      | 0        | reusable | foo.example.com | eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJkYXRhIjoiZGF0YSIsImV4cCI6MTQzNTAwMDkwMX0.XjHS9TtyWXGHJh7-2kycW2VeXbErDmz8dAhUfGQHLyH1QLJ6xFaTOUYc0b3C7oQuV19dFfEabVSTJw7xk5UrTg |

  Scenario Outline: Validate token
    Given a static token file containing:
      """
      HUNTER2
      """
      And a pre-shared key of "<SIGNING_PSK>"
      And the current time is <TIME>
    When I run `autosign validate --token <TOKEN> --hostname <HOSTNAME>`
    Then the exit status should be <EXITCODE>
    And  the output should contain "Successfully validated"

    Examples:
      | TIME       | EXITCODE | SIGNING_PSK | HOSTNAME          | TOKEN |
      | 1435000002 | 0        | secret      | foo.example.com   | eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJkYXRhIjoiZGF0YSIsImV4cCI6MTQzNTAwMzYwMX0.LF7MoeE_3UzV5NOHDRKrazBa1-b-js8Mrq-ioMI2eNLoJOzQZo8tOo0a4gqtBh2OcuOXORpIeD-fm7u6SvvsVw |
      | 1435000001 | 0        | any         | bar.example.com   | HUNTER2 |
      | 1436000000 | 1        | secret      | foo.example.com   | eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJkYXRhIjoiZGF0YSIsImV4cCI6MTQzNTAwMzYwMX0.LF7MoeE_3UzV5NOHDRKrazBa1-b-js8Mrq-ioMI2eNLoJOzQZo8tOo0a4gqtBh2OcuOXORpIeD-fm7u6SvvsVw |
      | 1435000002 | 1        | secret      | false.example.com | eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJkYXRhIjoiZGF0YSIsImV4cCI6MTQzNTAwMzYwMX0.LF7MoeE_3UzV5NOHDRKrazBa1-b-js8Mrq-ioMI2eNLoJOzQZo8tOo0a4gqtBh2OcuOXORpIeD-fm7u6SvvsVw |
      | 1435000002 | 0        | secret      | foo.example.com   | eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJkYXRhIjoiZGF0YSIsImV4cCI6MTQzNTAwMzYwMX0.LF7MoeE_3UzV5NOHDRKrazBa1-b-js8Mrq-ioMI2eNLoJOzQZo8tOo0a4gqtBh2OcuOXORpIeD-fm7u6SvvsVw |
      | 1435000001 | 1        | any         | bar.example.com   | BADKEY  |

  Scenario: Generate a csr_attributes.yaml file
    Given an ETCROOT of "etc"
      And a puppet confdir of $ETCROOT/puppetlabs/puppet
    When I run `autosign setup agent --psk hunter2`
    Then the /etc/puppetlabs/puppet/csr_attributes.yaml file should contain 'challengePassword: "hunter2"'
    And the exit status should be 0

  Scenario: Configure puppet server for autosigning
    Given a puppet confdir of /etc/puppetlabs/puppet
      And an autosign install path of /usr/local/bin/autosign
    When I run `autosign setup server --shared_secret hunter2`
    Then the /etc/puppetlabs/puppet/autosign.yaml file should contain 'presharedkey: "hunter2"'
      And the /etc/puppetlabs/puppet/puppet.conf file should contain 'autosign = /usr/local/bin/autosign'
      And the exit status should be 0


  Scenario Outline: Validate X509 CSR
    Given I use a fixture named "<CSR_FIXTURE>"
    When I run `autosign`
    # see http://stackoverflow.com/questions/12170071/writing-to-stdin-with-aruba-cucumber
    And I pipe in the file "<CSR_FIXTURE>"
    Then the exit status should be <EXITCODE>

    Examples:
      | CSR_FIXTURE     | EXITCODE |
      | passing.csr     | 0        |
      | expired.csr     | 1        |
      | malformed.csr   | 1        |
      | cn-mismatch.csr | 1        |

  Scenario: create a file
    Given a file named "etc/example.txt" with:
      """
      hello world
      """
    When I run `cat etc/example.txt`
    Then the output should contain exactly "hello world"

Scenario: Changing the environment
  Given a mocked "/etc/puppetlabs/foo" directory
  When I run `env`
#  Then the output should contain:
#    """
#    etc
#    """
  Then a "/etc/puppetlabs/foo" file should exist
