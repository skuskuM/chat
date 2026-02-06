# Nginx Basic Authorization Header

This repo includes an example `nginx.conf` that sets a Basic auth
`Authorization` header on proxied requests.

## Usage

1. Compute the base64 for `user:password`:
   ```bash
   echo -n 'user:password' | base64
   ```
2. Replace `<base64-user-pass>` in `nginx.conf` with the output.
3. Update the `upstream backend` host/port to your service.

The config preserves an incoming `Authorization` header if one is already
present; otherwise it supplies the Basic auth header.