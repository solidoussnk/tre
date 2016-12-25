(defun make-levenshtein (row column)
  (with (width  (length row)
         height (length column)
         w      (integer++ width)
         h      (integer++ height)
         m      (make-array w h))
;    (dotimes (i w)
;      (= (aref m i) (make-array)))
    (dotimes (i w)
      (dotimes (j h)
        (= (aref m i j ) 0)))
    (dotimes (i w)
      (= (aref m i 0) i))
    (dotimes (j h)
      (= (aref m 0 j ) j))
    (dotimes (jc height) 
      (dotimes (ic width) 
        (with (i (integer++ ic)
               j (integer++ jc))
          (= (aref m i j)
             (min (integer+ (aref m ic jc)
                  (? (== (elt row ic) (elt column jc))
                     0
                     1))
                  (integer+ (aref m ic j) 1)
                  (integer+ (aref m i jc) 1))))))
    m))

(defun levenshtein (row column)
  (aref (make-levenshtein row column) (length row) (length column)))
