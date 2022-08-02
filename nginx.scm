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
   (add-header "X-Frame-Options" "DENY")
   (add-header "X-Permitted-Cross-Domain-Policies" "none")
   (add-header "X-Xss-Protection" "1" "mode=block")))

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

(define (static-site subdomain)
  (https-server
   (list (string-append subdomain ".scheme.org"))
   (string-append "access_log"
                  " /production/" subdomain "/log/nginx/access.log;")
   (string-append "error_log"
                  " /production/" subdomain "/log/nginx/error.log;")
   (string-append "root"
                  " /production/" subdomain "/www;")))

;;;;

;; sudo certbot renew
;; sudo certbot certonly --nginx --cert-name alpha.servers.scheme.org -d alpha.servers.scheme.org -d api.scheme.org -d api.staging.scheme.org -d apps.scheme.org -d bigloo.scheme.org -d blog.scheme.org -d chez.scheme.org -d chibi.scheme.org -d chicken.scheme.org -d comm.scheme.org -d community.scheme.org -d conservatory.scheme.org -d cookbook.scheme.org -d cyclone.scheme.org -d doc.scheme.org -d docs.scheme.org -d docs.staging.scheme.org -d events.scheme.org -d faq.scheme.org -d files.scheme.org -d gauche.scheme.org -d get.scheme.org -d gitea.scheme.org -d groups.scheme.org -d jazz.scheme.org -d kawa.scheme.org -d learn.scheme.org -d list.scheme.org -d lists.scheme.org -d man.scheme.org -d mit.scheme.org -d mosh.scheme.org -d persist.scheme.org -d planet.scheme.org -d play.scheme.org -d r5rs.scheme.org -d r6rs.scheme.org -d r7rs.scheme.org -d registry.scheme.org -d research.scheme.org -d s7.scheme.org -d sagittarius.scheme.org -d scheme.org -d scm.scheme.org -d servers.scheme.org -d staging.scheme.org -d standards.scheme.org -d stklos.scheme.org -d test.scheme.org -d try.scheme.org -d video.scheme.org -d web.scheme.org -d wiki.scheme.org -d wiki.staging.scheme.org -d www.scheme.org -d www.staging.scheme.org -d ypsilon.scheme.org

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
         "gzip on;"
         "expires 1M;"
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
          '("www.staging.scheme.org" "staging.scheme.org")
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

         (static-site "apps")

         (static-site "planet")

         (static-site "community")

         (static-site "cookbook")

         (static-site "docs")

         (https-server
          '("docs.staging.scheme.org")
          "access_log /staging/docs/log/nginx/access.log;"
          "error_log  /staging/docs/log/nginx/error.log;"
          "root /staging/docs/www;")

         (https-server
          '("man.scheme.org")
          "access_log /production/man/log/nginx/access.log;"
          "error_log  /production/man/log/nginx/error.log;"
          "root /production/man/www;"

          "include /etc/nginx/mime.types;"
          (block "types"
                 "text/html 3scheme;"
                 "text/html 7scheme;"
                 "text/plain text;"))

         (static-site "registry")

         (static-site "persist")

         (static-site "comm")

         (static-site "test")

         ;; Named "web-topic" instead of "web" to avoid confusion with "www".
         (https-server
          '("web.scheme.org")
          "access_log /production/web-topic/log/nginx/access.log;"
          "error_log  /production/web-topic/log/nginx/error.log;"
          "root /production/web-topic/www;")

         (static-site "files")

         (static-site "conservatory")

         (static-site "containers")

         (static-site "events")

         (https-server
          '("get.scheme.org")
          "access_log /production/get/log/nginx/access.log;"
          "error_log  /production/get/log/nginx/error.log;"
          "root /production/get/www;"

          (block "location /v2/"
                 "proxy_pass http://localhost:5000;"
                 "proxy_set_header Host $host;"
                 "proxy_set_header X-Real-IP  $remote_addr;"
                 "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"))

         (static-site "groups")

         (static-site "learn")

         (static-site "lists")

         (static-site "research")

         (static-site "servers")

         (static-site "standards")

         (parameterize ((content-security-policy '()))
           (https-server
            '("try.scheme.org")
            "access_log /production/try/log/nginx/access.log;"
            "error_log  /production/try/log/nginx/error.log;"
            "root /production/try/www;"

            "gzip on;"
            "gzip_comp_level 6;"
            "gzip_types application/javascript;"))

         (static-site "video")

         (https-server
          '("gitea.scheme.org")
          "access_log /production/gitea/log/nginx/access.log;"
          "error_log  /production/gitea/log/nginx/error.log;"
          (block "location /"
                 "proxy_pass http://localhost:9030;"
                 "proxy_set_header Host $host;"
                 "proxy_set_header X-Real-IP  $remote_addr;"
                 "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"
                 "client_max_body_size 1G;"))

         (https-server
          '("wiki.staging.scheme.org")
          "access_log /staging/wiki/log/nginx/access.log;"
          "error_log  /staging/wiki/log/nginx/error.log;"
          (block "location /"
                 "proxy_pass http://localhost:9033;"
                 "proxy_set_header Host $host;"
                 "proxy_set_header X-Real-IP  $remote_addr;"
                 "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"))

         ;;

         (http-redirect-only-server
          "blog.scheme.org" "https://planet.scheme.org/")

         (http-redirect-only-server
          "doc.scheme.org" "https://docs.scheme.org/")

         (http-redirect-only-server
          "wiki.scheme.org" "http://community.schemewiki.org/")

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
          "bigloo.scheme.org" "https://www-sop.inria.fr/indes/fp/Bigloo/")

         (http-redirect-only-server
          "chez.scheme.org" "https://cisco.github.io/ChezScheme/")

         (http-redirect-only-server
          "chibi.scheme.org" "https://synthcode.com/scheme/chibi/")

         (http-redirect-only-server
          "chicken.scheme.org" "https://call-cc.org/")

         (http-redirect-only-server
          "cyclone.scheme.org" "https://justinethier.github.io/cyclone/")

         (http-redirect-only-server
          "gauche.scheme.org" "https://practical-scheme.net/gauche/")

         (http-redirect-only-server
          "jazz.scheme.org"
          ;; The "www." and "index.htm" are mandatory.
          "http://www.jazzscheme.org/index.htm")

         (http-redirect-only-server
          "kawa.scheme.org" "https://www.gnu.org/software/kawa/")

         (http-redirect-only-server
          "mit.scheme.org" "https://www.gnu.org/software/mit-scheme/")

         (http-redirect-only-server
          "mosh.scheme.org" "https://mosh.monaos.org/")

         (http-redirect-only-server
          "s7.scheme.org" "https://ccrma.stanford.edu/software/s7/")

         (http-redirect-only-server
          "sagittarius.scheme.org" "https://ktakashi.github.io/")

         (http-redirect-only-server
          "scm.scheme.org" "https://people.csail.mit.edu/jaffer/SCM")

         (http-redirect-only-server
          "stklos.scheme.org" "https://stklos.net/")

         (http-redirect-only-server
          "ypsilon.scheme.org"
          "http://www.littlewingpinball.com/doc/en/ypsilon/"))))
