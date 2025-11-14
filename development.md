# Development Notes
 This is only for testing purposes as whenever the token expires our tests break!  DO NOT DO THIS IN PRODUCTION.

## Regenerating Long-Lived Tokens

To generate a reusable autosign token that stays valid for roughly ten years (315,532,800 seconds), follow these steps:

1. Ensure your `autosign.conf` includes the shared secret `secret`. For example:

   ```yaml
   ---
   jwt_token:
     secret: 'secret'
   ```
   Or auto generate using `bundle exec autosign config setup` and set the secret as above.

   Update the file at `/etc/autosign.conf` or wherever your environment loads autosign configuration.

2. Run the generator with the reusable flag and the long validity window:

   ```shell
   autosign generate -r -t 315532800 foo.example.com
   ```

   - `-r` marks the token as reusable.
   - `-t 315532800` sets the token validity to 315,532,800 seconds (≈10 years).

3. The command prints the CSR snippet containing the new JWT token, which you can drop into `csr_attributes.yaml` for the target node.

## Creating a CSR 

For fixtures or local testing, use the helper script to mint a CSR that embeds the JWT directly:

```shell
script/generate_csr_with_token.sh \
  --token "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJkYXRhIjoie1wiY2VydG5hbWVcIjpcImZvby5leGFtcGxlLmNvbVwiLFwicmVxdWVzdGVyXCI6XCIwYjllN2U3YjYxODVcIixcInJldXNhYmxlXCI6dHJ1ZSxcInZhbGlkZm9yXCI6MzE1NTMyODAwLFwidXVpZFwiOlwiNWRmNjRkYTctNWZkNy00YjJiLTkyYTYtODMzM2QyMmZiYjE5XCJ9IiwiZXhwIjoiMjA3ODQ0NTQzNCJ9.Ql1FJuzS4MJXaYMXPg_fzTniBLTVktQt2FMJYk3OXI_lhR5smjRr2BS1gSgPTOatlc_7ILsoBSRYbFxz24V-Pg" \
  --certname foo.example.com \
  --output fixtures
```

- The script writes `<certname>.key.pem` and `<certname>.csr.pem` into the chosen output directory.
- Use `--subject` if you need a full DN (`"/C=US/ST=CA/L=SF/O=Example/OU=IT/CN=foo.example.com"`).
- The embedded token appears in the CSR’s `challengePassword` attribute, matching the behavior Puppet expects.

