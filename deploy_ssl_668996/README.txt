Cloudflare Origin SSL for *.668996.xyz / 668996.xyz
====================================================

Files:
  668996.xyz.pem  - Origin Certificate
  668996.xyz.key  - Private Key  (KEEP SECRET)

Location (already under nginx install root):
  nginx-1.23.3\deploy_ssl_668996\

Deploy / activate on this server:
  1. Copy both files into conf\:
       conf\668996.xyz.pem
       conf\668996.xyz.key
  2. Use template nginx_668996.xyz.conf as conf\nginx.conf:
       ssl_certificate      conf/668996.xyz.pem;
       ssl_certificate_key  conf/668996.xyz.key;
  3. From nginx-1.23.3\:  nginx.exe -t  then  reload.bat / ./reload.sh
  4. Cloudflare SSL mode: Full (strict)
     Note: Origin cert is trusted by Cloudflare proxy only.
     For DNS-only (grey cloud), use a public CA cert (e.g. Let's Encrypt).

Security:
  - Do NOT commit 668996.xyz.key to git / gitee / github
  - Do NOT send the private key in chat
  - If the key was leaked, create a NEW Origin Certificate in Cloudflare

This folder is for portable deploy only.
