(js-type-predicate %number? "number")

(defun number (x)         (parse-float x 10))
(defun string-integer (x) (parse-int x 10))
(defun number-integer (x) (*math.floor x))

(defun integer? (x)
  (& (%number? x)
     (%%%== (parse-int x 10) (parse-float x 10))))
