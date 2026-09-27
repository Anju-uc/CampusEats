## Local campus proof testing

The order endpoint requires a short-lived, server-issued campus proof. Set
`CAMPUS_ACCESS_SECRET` and `CAMPUS_ID` in the backend environment only.

For local testing, use the server-only CLI issuer:

```text
node scripts/create-campus-proof.js <firebase-uid>
```

It prints a proof containing the UID, campus ID, issue time, expiry, and a
single-use identifier. Do not expose the secret or turn this into a public
HTTP endpoint. The proof is sent to the backend as
`X-Campus-Access-Proof`.
