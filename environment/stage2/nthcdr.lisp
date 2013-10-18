;;;;; tré – Copyright (c) 2007,2011–2013 Sven Michael Klose <pixel@copei.de>

(functional nthcdr)

(defun nthcdr (idx lst)
  (when lst
    (? (zero? idx)
       lst
       (nthcdr (-- idx) (cdr lst)))))

(define-test "NTHCDR basically works"
  ((nthcdr 1 '(1 2 3 4)))
  '(2 3 4))
