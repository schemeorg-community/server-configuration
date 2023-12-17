#! /usr/bin/env gosh

(import (scheme base) (scheme file) (scheme read) (scheme write)
        (srfi 1) (srfi 13) (srfi 132) (srfi 193))

(define (read-all)
  (let loop ((xs '()))
    (let ((x (read)))
      (if (eof-object? x) (reverse xs) (loop (cons x xs))))))

(define (echo . strings) (for-each write-string strings) (newline))

(define (sort-unique strings)
  (list-delete-neighbor-dups string=? (list-sort string<? strings)))

;;

(define main-domain "scheme.org")

(define domains (list main-domain "schemeworkshop.org"))

(define server "tuonela.scheme.org")

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

(define subdomains
  (cons server (delete server (sort-unique (append-map grovel source-code)))))

(echo "sudo certbot renew")
(echo
 (string-join
  (cons (string-append "sudo certbot certonly --nginx --cert-name "
                       server)
        (map (lambda (subdomain) (string-append "  -d " subdomain))
             subdomains))
  " \\\n"))
