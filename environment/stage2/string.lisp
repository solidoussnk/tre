; tré – Copyright (c) 2005–2009,2011–2015 Sven Michael Klose <pixel@copei.de>

(functional string-concat string== upcase downcase list-string string-list queue-string)

(defun string<= (a b)
  (with (la  (length a)
         lb  (length b))
    (dotimes (i la (<= la lb))
      (& (> (elt a i)
            (elt b i))
         (return nil)))))

(defun string-list (x)
  (let* ((l (length x))
		 (s))
    (do ((i (-- l) (-- i)))
		((< i 0))
      (= s (push (elt x i) s)))
	s))

(defun queue-string (x)
  (apply #'string-concat (@ [?
                              (string? _)    _
                              (character? _) (string _)]
                            (queue-list x))))

(define-test "ELT on string returns char"
  ((character? (elt "LISP" 0)))
  t)

(define-test "ELT on string returns right char"
  ((== #\L (elt "LISP" 0)))
  t)

(define-test "STRING== works"
  ((& (string== "abc" "abc")
      (not (string== "ABC" "abc"))
      (not (string== "abc" "abcd"))
      (not (string== "abcd" "abc"))))
  t)

(define-test "LIST-STRING works"
  ((string== (list-string '(#\L #\I #\S #\P))
	        "LISP"))
  t)

(define-test "STRING-LIST works"
  ((equal (string-list "LISP") '(#\L #\I #\S #\P)))
  t)
