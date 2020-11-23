(import (scheme base) (scheme file) (scheme write))

(define (line . strings)
  (display (apply string-append strings))
  (newline))

(define (envar-lines alist)
  (for-each (lambda (pair) (line "export " (car pair) "=" (cdr pair)))
            alist))

;;;;

(define (service role user home envars)
  (let ((file (lambda (f) (string-append "roles/" role "/files/" f))))
    (with-output-to-file (file "run")
      (lambda ()
        (line "#! /bin/sh")
        (line "set -eu")
        (line "exec 2>&1")
        (envar-lines envars)
        (line "cd " home)
        (line "exec chpst -u " user " node server.js")))
    (with-output-to-file (file "log-run")
      (lambda ()
        (line "#! /bin/sh")
        (line "set -eu")
        (line "exec svlogd -ttt " home "/log")))))

(service "make_production_api"
         "production-api"
         "/production/api"
         '(("PORT" . "9000")))

(service "make_staging_api"
         "staging-api"
         "/staging/api"
         '(("PORT" . "9001")))
