(import (scheme base) (scheme write) (srfi 1))

(define (display-lines lines)
  (for-each (lambda (line) (display line) (newline))
            lines))

(define (flatten-once list_)
  (append-map (lambda (x) (if (pair? x) x (list x)))
              list_))

(define (string-join strings delimiter)
  (if (null? strings)
      ""
      (fold (lambda (s so-far) (string-append so-far delimiter s))
            (car strings) (cdr strings))))

(define (indent string)
  (string-append (make-string 4 #\space) string))

(define (block head . body)
  (cons (string-append head " {")
        (append (map indent (flatten-once body))
                (list "}"))))

(define (alist-change alist key val)
  (map (lambda (pair) (if (equal? key (car pair)) (cons key val) pair))
       alist))

(define (add-header-always name . params)
  (string-join (list "add_header"
                     name
                     (string-append "\"" (string-join params "; ") "\"")
                     "always;")
               " "))

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
  (list
   (apply add-header-always "Content-Security-Policy"
          (map encode-csp-directive (content-security-policy)))
   (apply add-header-always "Feature-Policy"
          (map (lambda (feature) (string-append feature " 'none'"))
               blocked-features))
   (add-header-always "Referrer-Policy" "no-referrer")
   (add-header-always "Strict-Transport-Security"
                      "max-age=31536000"
                      "includeSubDomains")
   (add-header-always "X-Content-Type-Options" "nosniff")
   (add-header-always "X-Frame-Options" "DENY")
   (add-header-always "X-Permitted-Cross-Domain-Policies" "none")
   (add-header-always "X-Xss-Protection" "1" "mode=block")))

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

;;;;

;; sudo certbot renew
;; sudo certbot certonly --nginx -d alpha.servers.scheme.org -d api.scheme.org -d api.staging.scheme.org -d blog.scheme.org -d chat.scheme.org -d chicken.scheme.org -d comm.scheme.org -d containers.scheme.org -d cyclone.scheme.org -d doc.scheme.org -d doc.staging.scheme.org -d docs.scheme.org -d events.scheme.org -d faq.scheme.org -d files.scheme.org -d gauche.scheme.org -d implementations.scheme.org -d list.scheme.org -d lists.scheme.org -d mit.scheme.org -d persist.scheme.org -d planet.scheme.org -d play.scheme.org -d r5rs.scheme.org -d r6rs.scheme.org -d r7rs.scheme.org -d registry.scheme.org -d research.scheme.org -d s7.scheme.org -d sagittarius.scheme.org -d scheme.org -d servers.scheme.org -d standards.scheme.org -d stklos.scheme.org -d test.scheme.org -d try.scheme.org -d web.scheme.org -d www.scheme.org -d www.staging.scheme.org

(set! letsencrypt-etc "/etc/letsencrypt")
(set! certificate-hostname "alpha.servers.scheme.org")

(define cors
  (list "add_header 'Access-Control-Allow-Origin' '*';"
        "add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';"
        "add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';"))

(display-lines
 (append
  (block "events")
  (block "http"
         "include /etc/nginx/mime.types;"
         "default_type application/octet-stream;"
         "sendfile on;"
         "server_tokens off;"
         "ssl_stapling on;"
         "ssl_stapling_verify on;"
         (string-append "ssl_certificate " letsencrypt-etc
                        "/live/" certificate-hostname "/fullchain.pem;")
         (string-append "ssl_certificate_key " letsencrypt-etc
                        "/live/" certificate-hostname "/privkey.pem;")
         (string-append "ssl_dhparam " letsencrypt-etc
                        "/ssl-dhparams.pem;")
         (https-server
          '("alpha.servers.scheme.org")
          "access_log /production/alpha.servers/log/nginx/access.log;"
          "error_log  /production/alpha.servers/log/nginx/error.log;"
          "root /production/alpha.servers/www;")

         (https-server
          '("www.scheme.org" "scheme.org")
          "access_log /production/www/log/nginx/access.log;"
          "error_log  /production/www/log/nginx/error.log;"
          "root /production/www/www;")

         (https-server
          '("www.staging.scheme.org")
          "access_log /staging/www/log/nginx/access.log;"
          "error_log  /staging/www/log/nginx/error.log;"
          "root /staging/www/www;")

         (https-server
          '("api.scheme.org")
          "access_log /production/api/log/nginx/access.log;"
          "error_log  /production/api/log/nginx/error.log;"
          (block "location /"
                 "proxy_pass http://127.0.0.1:9000;"
                 (apply block "if ($request_method = 'OPTIONS')"
                        (append cors
                                (list "add_header 'Access-Control-Max-Age' 1728000;"
                                      "add_header 'Content-Type' 'text/plain; charset=utf-8';"
                                      "add_header 'Content-Length' 0;"
                                      "return 204;")))
                 (apply block "if ($request_method = 'POST')"
                        (append cors
                                (list "add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range';")))
                 (apply block "if ($request_method = 'GET')"
                        (append cors
                                (list "add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range';")))))

         (https-server
          '("api.staging.scheme.org")
          "access_log /staging/api/log/nginx/access.log;"
          "error_log  /staging/api/log/nginx/error.log;"
          (block "location /"
                 "proxy_pass http://127.0.0.1:9001;"))

         (https-server
          '("planet.scheme.org")
          "access_log /production/planet/log/nginx/access.log;"
          "error_log  /production/planet/log/nginx/error.log;"
          "root /production/planet/www;")

         (https-server
          '("chat.scheme.org")
          "access_log /production/chat/log/nginx/access.log;"
          "error_log  /production/chat/log/nginx/error.log;"
          "root /production/chat/www;")

         (https-server
          '("doc.scheme.org")
          "access_log /production/doc/log/nginx/access.log;"
          "error_log  /production/doc/log/nginx/error.log;"
          "root /production/doc/www;")

         (https-server
          '("doc.staging.scheme.org")
          "access_log /staging/doc/log/nginx/access.log;"
          "error_log  /staging/doc/log/nginx/error.log;"
          "root /staging/doc/www;")

         (https-server
          '("registry.scheme.org")
          "access_log /production/registry/log/nginx/access.log;"
          "error_log  /production/registry/log/nginx/error.log;"
          "root /production/registry/www;")

         (https-server
          '("persist.scheme.org")
          "access_log /production/persist/log/nginx/access.log;"
          "error_log  /production/persist/log/nginx/error.log;"
          "root /production/persist/www;")

         (https-server
          '("comm.scheme.org")
          "access_log /production/comm/log/nginx/access.log;"
          "error_log  /production/comm/log/nginx/error.log;"
          "root /production/comm/www;")

         (https-server
          '("test.scheme.org")
          "access_log /production/test/log/nginx/access.log;"
          "error_log  /production/test/log/nginx/error.log;"
          "root /production/test/www;")

         ;; Named "web-topic" instead of "web" to avoid confusion with "www".
         (https-server
          '("web.scheme.org")
          "access_log /production/web-topic/log/nginx/access.log;"
          "error_log  /production/web-topic/log/nginx/error.log;"
          "root /production/web-topic/www;")

         (https-server
          '("files.scheme.org")
          "access_log /production/files/log/nginx/access.log;"
          "error_log  /production/files/log/nginx/error.log;"
          "root /production/files/www;")

         (https-server
          '("containers.scheme.org")
          "access_log /production/containers/log/nginx/access.log;"
          "error_log  /production/containers/log/nginx/error.log;"
          "root /production/containers/www;")

         (https-server
          '("events.scheme.org")
          "access_log /production/events/log/nginx/access.log;"
          "error_log  /production/events/log/nginx/error.log;"
          "root /production/events/www;")

         (https-server
          '("implementations.scheme.org")
          "access_log /production/implementations/log/nginx/access.log;"
          "error_log  /production/implementations/log/nginx/error.log;"
          "root /production/implementations/www;")

         (https-server
          '("lists.scheme.org")
          "access_log /production/lists/log/nginx/access.log;"
          "error_log  /production/lists/log/nginx/error.log;"
          "root /production/lists/www;")

         (https-server
          '("research.scheme.org")
          "access_log /production/research/log/nginx/access.log;"
          "error_log  /production/research/log/nginx/error.log;"
          "root /production/research/www;")

         (https-server
          '("servers.scheme.org")
          "access_log /production/servers/log/nginx/access.log;"
          "error_log  /production/servers/log/nginx/error.log;"
          "root /production/servers/www;")

         (https-server
          '("standards.scheme.org")
          "access_log /production/standards/log/nginx/access.log;"
          "error_log  /production/standards/log/nginx/error.log;"
          "root /production/standards/www;")

         (parameterize ((content-security-policy
                         (alist-change (content-security-policy)
                                       "script-src"
                                       '("'self'"
                                         "'unsafe-inline'"
                                         "'unsafe-eval'"))))
           (https-server
            '("try.scheme.org")
            "access_log /production/try/log/nginx/access.log;"
            "error_log  /production/try/log/nginx/error.log;"
            "root /production/try/www;"

            "gzip on;"
            "gzip_comp_level 6;"
            "gzip_types application/javascript;"))

         ;;

         (http-redirect-only-server
          "blog.scheme.org" "https://planet.scheme.org/")

         (http-redirect-only-server
          "docs.scheme.org" "https://doc.scheme.org/")

         (http-redirect-only-server
          "faq.scheme.org" "http://community.schemewiki.org/?scheme-faq")

         (http-redirect-only-server
          "list.scheme.org" "https://lists.scheme.org/")

         (http-redirect-only-server
          "play.scheme.org" "https://try.scheme.org/")

         (http-redirect-only-server
          "r5rs.scheme.org" "http://schemers.org/Documents/Standards/R5RS/")

         (http-redirect-only-server
          "r6rs.scheme.org" "http://www.r6rs.org/")

         (http-redirect-only-server
          "r7rs.scheme.org" "http://r7rs.org/")

         ;;

         (http-redirect-only-server
          "chicken.scheme.org" "https://call-cc.org/")

         (http-redirect-only-server
          "cyclone.scheme.org" "https://justinethier.github.io/cyclone/")

         (http-redirect-only-server
          "gauche.scheme.org" "https://practical-scheme.net/gauche/")

         (http-redirect-only-server
          "mit.scheme.org" "https://www.gnu.org/software/mit-scheme/")

         (http-redirect-only-server
          "s7.scheme.org" "https://ccrma.stanford.edu/software/s7/")

         (http-redirect-only-server
          "sagittarius.scheme.org" "https://ktakashi.github.io/")

         (http-redirect-only-server
          "stklos.scheme.org" "https://stklos.net/"))))
