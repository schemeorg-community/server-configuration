(import (scheme base) (scheme write) (srfi 1))

(define (display-lines lines)
  (for-each (lambda (line) (display line) (newline))
            lines))

(define (flatten-all x)
  (if (list? x)
      (append-map flatten-all x)
      (list x)))

(define (string-join strings delimiter)
  (if (null? strings)
      ""
      (fold (lambda (s so-far) (string-append so-far delimiter s))
            (car strings) (cdr strings))))

(define (indent string)
  (string-append (make-string 4 #\space) string))

(define (block head . body)
  (append (list (string-append head " {"))
          (map indent (flatten-all body))
          (list "}")))

(define (alist-change alist key val)
  (map (lambda (pair) (if (equal? key (car pair)) (cons key val) pair))
       alist))

(define (add-header name . params)
  (if (null? params)
      '()
      (list
       (string-join (list "add_header"
                          name
                          (string-append "\"" (string-join params "; ") "\"")
                          "always;")
                    " "))))

;;;;

(define letsencrypt-etc #f)
(define certificate-hostname #f)

(define blocked-features
  '("accelerometer"
    "ambient-light-sensor"
    "autoplay"
    "camera"
    "display-capture"
    "document-domain"
    "encrypted-media"
    "fullscreen"
    "geolocation"
    "gyroscope"
    "layout-animations"
    "magnetometer"
    "microphone"
    "midi"
    "payment"
    "picture-in-picture"
    "speaker"
    "usb"
    "vibrate"
    "vr"))

(define content-security-policy
  (make-parameter
   '(("default-src" "'self'")
     ("style-src"   "'self'" "'unsafe-inline'")
     ("script-src"  "'self'" "'unsafe-inline'")
     ("upgrade-insecure-requests"))))

(define (encode-csp-directive directive) (string-join directive " "))

(define (https-security-header-lines)
  (append
   (apply add-header "Content-Security-Policy"
          (map encode-csp-directive (content-security-policy)))
   (apply add-header "Feature-Policy"
          (map (lambda (feature) (string-append feature " 'none'"))
               blocked-features))
   (add-header "Referrer-Policy" "no-referrer")
   (add-header "Strict-Transport-Security"
               "max-age=31536000"
               "includeSubDomains")
   (add-header "X-Content-Type-Options" "nosniff")
   (add-header "X-Frame-Options" "SAMEORIGIN")
   (add-header "X-Permitted-Cross-Domain-Policies" "none")
   (add-header "X-Xss-Protection" "1" "mode=block")))

(define (default-servers)
  (list (block "server"
               "server_name _;"
               "listen 80 default_server;"
               "listen [::]:80 default_server;"
               "return 444;")
        (block "server"
               "server_name _;"
               "listen 443 default_server;"
               "listen [::]:443 default_server;"
               "ssl_reject_handshake on;")))

(define (http->https-redirect-server primary alias)
  (block "server"
         (string-append "server_name " alias ";")
         "listen [::]:80;"
         "listen 80;"
         (string-append "return 301 https://" primary "$request_uri;")))

(define (https-redirect-server primary alias)
  (block "server"
         (string-append "server_name " alias ";")
         "listen [::]:443 ssl;"
         "listen 443 ssl;"
         (string-append "include " letsencrypt-etc "/options-ssl-nginx.conf;")
         (https-security-header-lines)
         (string-append "return 301 https://" primary "$request_uri;")))

(define (https-only-server hostname . lines)
  (apply block
         "server"
         (string-append "server_name " hostname ";")
         "listen [::]:443 ssl;"
         "listen 443 ssl;"
         (string-append "include " letsencrypt-etc "/options-ssl-nginx.conf;")
         (https-security-header-lines)
         lines))

(define (https-server hostnames . lines)
  (let ((primary (car hostnames))
        (aliases (cdr hostnames)))
    (append (apply https-only-server primary lines)
            (append-map (lambda (hostname)
                          (https-redirect-server primary hostname))
                        aliases)
            (append-map (lambda (hostname)
                          (http->https-redirect-server primary hostname))
                        hostnames))))

(define (http-redirect-only-server hostname redirect-to)
  (append
   (http->https-redirect-server hostname hostname)
   (block
    "server"
    (string-append "server_name " hostname ";")
    "listen [::]:443 ssl;"
    "listen 443 ssl;"
    (string-append "include " letsencrypt-etc "/options-ssl-nginx.conf;")
    (https-security-header-lines)
    (block "location = /"
           (string-append "return 301 " redirect-to ";")))))

(define (log-directives hostname)
  (list (string-append "access_log /var/log/nginx/" hostname "_access.log;")
        (string-append "error_log /var/log/nginx/" hostname "_error.log;")))

(define (static-site subdomain . body)
  (let ((hostname (string-append subdomain ".scheme.org")))
    (apply
     https-server
     (list hostname)
     (append
      (log-directives hostname)
      (list (string-append "root /production/" subdomain "/www;"))
      body))))

;;;;

(set! letsencrypt-etc "/etc/letsencrypt")
(set! certificate-hostname "tuonela.scheme.org")

(define cors
  (list "add_header 'Access-Control-Allow-Origin' '*';"
        "add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';"
        "add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';"))

(display-lines
 (append
  (block "events")
  (block "http"

         "include /etc/nginx/mime.types;"
         (block "types"

                ;; Unix manual pages in troff format.
                "text/plain 1;"
                "text/plain 2;"
                "text/plain 3;"
                "text/plain 4;"
                "text/plain 5;"
                "text/plain 6;"
                "text/plain 7;"
                "text/plain 8;"
                "text/plain 9;"

                "text/plain diff;"
                "text/plain patch;"

                "text/plain pose;"  ; Portable S-expressions

                "text/plain text;")
         "default_type application/octet-stream;"

         "charset utf-8;"
         "charset_types text/plain;"

         "sendfile on;"
         "gzip on;"

         ;; An "expires" time of one month is way too long for some
         ;; things, especially planet and gitea.

         ;; TODO: Perhaps we should specify "expires" per subdomain?

         ;;"expires 1M;"

         "server_tokens off;"
         "ssl_stapling on;"
         "ssl_stapling_verify on;"
         (string-append "ssl_certificate " letsencrypt-etc
                        "/live/" certificate-hostname "/fullchain.pem;")
         (string-append "ssl_certificate_key " letsencrypt-etc
                        "/live/" certificate-hostname "/privkey.pem;")
         (string-append "ssl_dhparam " letsencrypt-etc
                        "/ssl-dhparams.pem;")

         (default-servers)

         (let ((server "tuonela.scheme.org"))
           (https-server (list server)
                         (log-directives server)
                         "root /production/server/www;"))

         ;; (https-server
         ;;  '("api.scheme.org")
         ;;  "access_log /var/log/nginx/api.scheme.org_access.log;"
         ;;  "error_log  /var/log/nginx/api.scheme.org_error.log;"
         ;;  (block "location /"
         ;;         "proxy_pass http://127.0.0.1:9000;"
         ;;         (apply block "if ($request_method = 'OPTIONS')"
         ;;                (append cors
         ;;                        (list "add_header 'Access-Control-Max-Age' 1728000;"
         ;;                              "add_header 'Content-Type' 'text/plain; charset=utf-8';"
         ;;                              "add_header 'Content-Length' 0;"
         ;;                              "return 204;")))
         ;;         (apply block "if ($request_method = 'POST')"
         ;;                (append cors
         ;;                        (list "add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range';")))
         ;;         (apply block "if ($request_method = 'GET')"
         ;;                (append cors
         ;;                        (list "add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range';")))))

         ;; (https-server
         ;;  '("api.staging.scheme.org")
         ;;  "access_log /staging/api/log/nginx/access.log;"
         ;;  "error_log  /staging/api/log/nginx/error.log;"
         ;;  (block "location /"
         ;;         "proxy_pass http://127.0.0.1:9001;"))

         (static-site "planet")

         (static-site "books")

         (static-site "chat")

         (static-site "community")

         (static-site "cookbook")

         (static-site "docs")

         (https-server
          '("docs.staging.scheme.org")
          (log-directives "docs.staging.scheme.org")
          "root /staging/docs/www;")

         (https-server
          '("get.staging.scheme.org")
          (log-directives "get.staging.scheme.org")
          "root /staging/get/www;")

         (static-site "man"

                      "include /etc/nginx/mime.types;"
                      (block "types"
                             "text/html 1;"
                             "text/html 3scm;"
                             "text/html 7scm;")

                      (block "location /raw"

                             "include /etc/nginx/mime.types;"
                             (block "types"
                                    "text/plain 1;"
                                    "text/plain 3scm;"
                                    "text/plain 7scm;")))

         (static-site "registry")

         (static-site "persist")

         (static-site "comm")

         (static-site "test")

         (static-site "web")

         (static-site "files")

         (static-site "conservatory")

         (static-site "containers")

         (static-site "events")

         (static-site
          "get"

          (block "location /v2/"
                 "proxy_pass http://localhost:5000;"
                 "proxy_set_header Host $host;"
                 "proxy_set_header X-Real-IP  $remote_addr;"
                 "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"))

         (static-site "groups")

         (static-site "research")

         (static-site "standards")

         (parameterize ((content-security-policy '()))
           (static-site
            "try"

            "gzip on;"
            "gzip_comp_level 6;"
            "gzip_types application/javascript;"))

         (static-site "video")

         (parameterize ((content-security-policy
                         (alist-change (content-security-policy)
                                       "script-src"
                                       '("'self'"
                                         "'unsafe-inline'"
                                         "'unsafe-eval'"))))
           (https-server
            '("gitea.scheme.org")
            (log-directives "gitea.scheme.org")
            (block "location /"
                   "proxy_pass http://localhost:4040;"
                   "proxy_set_header Host $host;"
                   "proxy_set_header X-Real-IP  $remote_addr;"
                   "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"
                   "client_max_body_size 1G;")))

         (block "map $go_scheme_source $go_scheme_target"
                "include /production/go/nginx/map.conf;")
         (static-site
          "go"
          (block "location ~ ^/([a-z0-9][a-z0-9-]*)$"
                 "set $go_scheme_source $1;"
                 (block "if ($go_scheme_target)"
                        "return 301 $go_scheme_target;")))

         (https-server
          '("wiki.staging.scheme.org")
          (log-directives "wiki.staging.scheme.org")
          (block "location /"
                 "proxy_pass http://localhost:9033;"
                 "proxy_set_header Host $host;"
                 "proxy_set_header X-Real-IP  $remote_addr;"
                 "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"))

         (https-server
          '("www.schemeworkshop.org" "schemeworkshop.org")
          (log-directives "www.schemeworkshop.org")
          "root /production/workshop/www;")

         (https-server
          '("www.staging.schemeworkshop.org")
          (log-directives "www.staging.schemeworkshop.org")
          "root /staging/workshop/www;")

         ;;

         (http-redirect-only-server
          "blog.scheme.org" "https://planet.scheme.org/")

         (http-redirect-only-server
          "doc.scheme.org" "https://docs.scheme.org/")

         (http-redirect-only-server
          "play.scheme.org" "https://try.scheme.org/"))))
