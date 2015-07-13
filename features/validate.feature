Feature: Validate autosign key
  In order to sign puppet certificates automatically
  I want to validate autosign keys programatically
  So that I only grant access to allowed systems without needing manual authorization

  Scenario: Validate a certificate signing request
    Given I set the environment variables to:
      | variable               | value  |
      | AUTOSIGN_TESTMODE      | true   |
      | AUTOSIGN_TEST_SECRET   | secret |
      | AUTOSIGN_TEST_LOGLEVEL | info   |
      | AUTOSIGN_TEST_JOURNALFILE | /tmp/autosign_journal |
    When I run `rm -f /tmp/autosign_journal`
     And I run `autosign-validator i-7672fe81` interactively
     And I pipe in the file "../../fixtures/i-7672fe81.pem"
    Then the output should contain "token validated successfully"
    Then the exit status should be 0

  Scenario: Do not validate a certificate signing request whose certname does not match the certificate
    When I run `autosign-validator wrong-certname.example.com` interactively
     And I pipe in the file "../../fixtures/i-7672fe81.pem"
    Then the exit status should be 1
