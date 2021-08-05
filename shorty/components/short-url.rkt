#lang racket/base

(require deta
         koyo/database
         koyo/url
         gregor
         racket/format
         racket/port
         racket/random
         racket/contract
         racket/string
         threading)


(provide
 (schema-out short-url)
 lookup-short-url
 short-url-link
 create-short-url!
 list-short-urls)

(define (generate-code)
  (with-output-to-string
    (lambda ()
      (for ([b (crypto-random-bytes 4)])
        (display (~a (number->string b 16)
                     #:align 'right
                     #:left-pad-string "0"
                     #:width 2))))))

(define-schema short-url
  #:table "short_urls"
  ([id id/f #:primary-key #:auto-increment]
   [code string/f]
   [url string/f #:contract non-empty-string? #:wrapper string-trim]
   [user-id integer/f]
   [(create-at (now/moment)) datetime-tz/f]))

(define/contract (short-url-link u)
  (-> short-url? string?)
  (make-application-url (short-url-code u)))

(define/contract (lookup-short-url db code)
  (-> database? string? (or/c #f short-url?))
  (with-database-connection [conn db]
    (lookup conn (~> (from short-url #:as su)
                     (where (= su.code ,code))))))

(define/contract (list-short-urls db user-id)
  (-> database? id/c (listof short-url?))
  (with-database-connection [conn db]
    (for/list ([u (in-entities conn (~> (from short-url #:as su)
                                        (where (= su.user-id ,user-id))
                                        (order-by ([su.create-at #:desc]))))])
      u)))



(define/contract (create-short-url! db url user-id)
  (-> database? string? id/c short-url?)
  (with-database-connection [conn db]
    (insert-one! conn (make-short-url
                       #:code (generate-code)
                       #:url url
                       #:user-id user-id))))
