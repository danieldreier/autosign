Feature: Generate autosign key
  In order to sign puppet certificates automatically
  I want to generate autosign keys programatically
  So I don't have to use static strings as keys

  Scenario: Generate new token
    Given a pre-shared key of "secret"
      And a hostname of "foo.example.com"
      And a file named "autosign.conf" with:
      """
      ---
      jwt_token:
        validity: '7200'
        secret: 'secret'
      """
    When I run `chmod 600 autosign.conf`
     And I run `autosign --config autosign.conf generate foo.example.com`
    Then the output should contain "Autosign token for: foo.example.com"
     And the output should contain "valid until"
     And the exit status should be 0

  Scenario: Generate new token using the --bare flag
    Given a pre-shared key of "secret"
      And a hostname of "foo.example.com"
      And a file named "autosign.conf" with:
      """
      ---
      jwt_token:
        validity: '7200'
        secret: 'secret'
      """
    When I run `chmod 600 autosign.conf`
     And I run `autosign --config autosign.conf generate --bare foo.example.com`
    Then the output should be a JSON web token
     And the output should not contain "Autosign token for: foo.example.com"
     And the output should not contain "valid until"
     And the exit status should be 0

  Scenario: Generate new reusable token
    Given a pre-shared key of "secret"
      And a hostname of "foo.example.com"
      And a file named "autosign.conf" with:
      """
      ---
      jwt_token:
        validity: '7200'
        secret: 'secret'
      """
    When I run `chmod 600 autosign.conf`
    When I run `autosign --config autosign.conf generate foo.example.com --reusable`
    Then the output should contain "Autosign token for: foo.example.com"
     And the output should contain "valid until"
     And the exit status should be 0

  Scenario: Validate a token
    Given a pre-shared key of "secret"
      And a hostname of "foo.example.com"
      And a file named "autosign.conf" with:
      """
      ---
      jwt_token:
        secret: 'secret'
      """
    When I run `chmod 600 autosign.conf`
    When I run `autosign --config autosign.conf validate --certname "foo.example.com" "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJkYXRhIjoie1wiY2VydG5hbWVcIjpcImZvby5leGFtcGxlLmNvbVwiLFwicmVxdWVzdGVyXCI6XCI0MzFkZGI3NjlkZDNcIixcInJldXNhYmxlXCI6dHJ1ZSxcInZhbGlkZm9yXCI6MzE1NTMyODAwLFwidXVpZFwiOlwiZGMyNWMzNzctNzFmNC00MjdkLWE3OWItNDNiZjVhODA5OGMyXCJ9IiwiZXhwIjoiMjA3ODQ0MDgzNCJ9.jnOsrHaHht47YKU1ixmiuX8LjvvPumX05En3deKg4A9z4UZJFDbXPNGcb2QeVw8fvpqUK0c-aotLvtnXZIvYGw"`
    Then the output should contain "token validated successfully"
     And the exit status should be 0

  Scenario: Not validate a bad token
    Given a pre-shared key of "secret"
      And a hostname of "foo.example.com"
      And a file named "autosign.conf" with:
      """
      ---
      jwt_token:
        secret: 'secret'
      """
    When I run `chmod 600 autosign.conf`
    When I run `autosign --config autosign.conf validate --certname "foo.example.com" "invalid_token"`
    Then the exit status should be 1

  Scenario: Not validate an expired token
    Given a pre-shared key of "secret"
      And a hostname of "foo.example.com"
      And a file named "autosign.conf" with:
      """
      ---
      jwt_token:
        secret: 'secret'
      """
    When I run `chmod 600 autosign.conf`
    When I run `autosign --config autosign.conf validate --certname "foo.example.com" "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJkYXRhIjoie1wiY2VydG5hbWVcIjpcImZvby5leGFtcGxlLmNvbVwiLFwicmVxdWVzdGVyXCI6XCJEYW5pZWxzLU1hY0Jvb2stUHJvLTIubG9jYWxcIixcInJldXNhYmxlXCI6ZmFsc2UsXCJ2YWxpZGZvclwiOjEsXCJ1dWlkXCI6XCJlNjI1Y2I1Ny02NzY5LTQwMzQtODNiZS0zNzkxNmQ5YmMxMDRcIn0iLCJleHAiOiIxNDM2NDY2MzAyIn0.UXEDEbRqEWx5SdSpQjfowU56JubY5Yz2QN6cckby2es-g2P_n2lyAS6AwFeliBXyCDyVUelIT3g1QP4TdB9EEA"`
    Then the exit status should be 1
