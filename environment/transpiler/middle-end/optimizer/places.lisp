; tré – Copyright (c) 2008–2014,2016 Sven Michael Klose <pixel@copei.de>

(define-optimizer optimize-places
  (& (%=? a)
     (%=? d.)
     (eq .a. (caddr d.))
     (not (will-be-used-again? .d .a.)))
    (. `(%= ,(cadr d.) ,(caddr a))
       (optimize-places .d))
  (& (%=? a)
     (%=? d.)
     (atom (caddr a))
     (cons? (caddr d.))
     (tree-find .a. (caddr d.) :test #'eq)
     (not (will-be-used-again? .d .a.)))
    (. (replace-tree .a. ..a.
                     `(%= ,(cadr d.) ,(caddr d.))
                     :test #'eq)
       (optimize-places .d))
  (& (%=? a)
     (not (will-be-used-again? d .a.)))
    (. `(%= nil ,..a.)
       (optimize-places d)))
