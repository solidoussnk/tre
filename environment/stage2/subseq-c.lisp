(defun string-subseq (seq start &optional (end 99999))
  (unless (== start end)
    (alet (length seq)
      (when (< start !)
        (when (>= end !)
          (= end !))
        (with (l  (- end start)
               s  (make-string 0))
          (dotimes (x l s)
            (= s (string-concat s (string (elt seq (number+ start x)))))))))))
