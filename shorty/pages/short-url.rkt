#lang racket/base

(require forms
         koyo/haml
         koyo/continuation
         koyo/database
         koyo/url
         racket/contract
         racket/match
         web-server/dispatchers/dispatch
         web-server/http
         "../components/user.rkt"
         "../components/auth.rkt"
         "../components/template.rkt"
         "../components/short-url.rkt")

(provide
 create-short-url-page
 short-url-redirect-page
 short-urls-page)

(define/contract ((short-url-redirect-page db) req code)
  (-> database? (-> request? string? response?))
  (define u (lookup-short-url db code))
  (unless u
    (next-dispatcher))
  (redirect-to (short-url-url u)))

(define/contract ((short-urls-page db) req)
  (-> database? (-> request? response?))
  (page
   (haml
    (.container
     (:h1 "Your short urls")
     (:button "Create url")
     (:table
      (:thead
       (:th "Code")
       (:th "Destination")
       (:th "Link"))
      (:body
       ,@(for/list ([u (in-list (list-short-urls db (user-id (current-user))))])
           (haml
            (:tr
             (:td (short-url-code u))
             (:td (short-url-url u))
             (:td (:a ([:href (short-url-link u)])
                      (short-url-link u))))))))))))

(define short-uri-form
  (form* ([url (ensure binding/text (required) (shorter-than 500))])
         url))

(define/contract ((create-short-url-page db) req)
  (-> database? (-> request? response?))
  (let loop ([req req])
    (send/suspend/dispatch/protect
     (lambda (embed/url)
       (match (form-run short-uri-form req)
         [(list 'passed url _)
          (define the-url (create-short-url! db url (user-id (current-user))))
          (redirect-to (reverse-uri 'short-urls-page))]
         [(list _ _ rw)
          (page
           (haml
            (.container
             (:h1 "Create short url")
             (:form
              ([:action (embed/url loop)]
               [:method "POST"])
              (:label
               "URL:"
               (rw "url" (widget-text)))
              ,@(rw "url" (widget-errors))
              (:button
               ([:type "submit"])
               "Create Short URL")))))])))))
