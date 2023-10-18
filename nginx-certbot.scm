#! /usr/bin/env gosh

(import (scheme base) (scheme file) (scheme read) (scheme write)
        (srfi 1) (srfi 13) (srfi 132) (srfi 193))

(define (read-all)
  (let loop ((xs '()))
    (let ((x (read)))
      (if (eof-object? x) (reverse xs) (loop (cons x xs))))))

(define (write-line x) (write-string x) (newline))

(define (sort-unique strings)
  (list-delete-neighbor-dups string=? (list-sort string<? strings)))

;;

(define domains '("scheme.org" "schemers.org"))

(define source-file (string-append (script-directory) "nginx.scm"))

(define source-code (with-input-from-file source-file read-all))

(define (grovel x)
  (cond ((and (string? x)
              (any (lambda (domain) (string-suffix? domain x)) domains)
              (not (string-prefix? "." x))
              (not (string-contains x "/")))
         (list x))
        ((and (list? x)
              (>= (length x) 2)
              (equal? 'static-site (first x))
              (string? (second x)))
         (list (string-append (second x) ".scheme.org")))
        ((pair? x)
         (append (grovel (car x))
                 (grovel (cdr x))))
        (else
         '())))

(define subdomains (sort-unique (append-map grovel source-code)))

(write-line "sudo certbot renew")
(write-line
 (string-join
  (cons "sudo certbot certonly --nginx --cert-name alpha.servers.scheme.org"
        (map (lambda (subdomain) (string-append "  -d " subdomain))
             subdomains))
  " \\\n"))
