;;;;; tré – Copyright (c) 2008–2013 Sven Michael Klose <pixel@copei.de>

(defun print-html-script (out script
                          &key (title nil)
                               (no-cache? nil)
                               (strict? t)
                               (copyright-title nil) (copyright-href nil))
  (with-default-stream o out
    (format o (+ (doctype-html-5) "~%"))
    (princ (lml2xml `(html
                       (head
                         (title ,title)
                         (meta :http-equiv "Content-Type" :content "text/html; charset=utf-8")
                         ,@(& no-cache
                              `((meta :http-equiv "pragma" :content "no-cache")))
                         ,@(& (| copyright-title
                                 copyright-href)
                              `((link :rel "copyright"
                                      ,@(!? copyright-title
                                            `(:title ,(escape-string !)))
                                      ,@(!? copyright-href
                                            `(:href  ,(escape-string !))))))
                         (script :type "text/javascript"
                           "<!--"
                           ,@(& strict?
                                `("\"use strict\";"))
                           ,script
                           "//-->"))))
           o)))

(defun make-html-script (pathname script
                         &key (title nil)
                              (no-cache? nil)
                              (strict? t)
                              (copyright-title nil) (copyright-href nil))
  (with-output-file o pathname
    (print-html-script o script ,@(keyword-copiers 'title 'no-cache? 'strict? 'copyright-title 'copyright-href))))