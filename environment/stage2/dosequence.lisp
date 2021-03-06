(defmacro dosequence ((v seq &rest result) &body body)
  (with-gensym (evald-seq idx)
    `(let ,evald-seq ,seq
       (when ,evald-seq
         (dotimes (,idx (length ,evald-seq) ,@result)
           (let ,v (elt ,evald-seq ,idx)
             ,@body))))))

(defmacro adosequence (params &body body)
  (let p (? (atom params)
            (list params)
            params)
    `(dosequence (! ,p. ,.p.)
       ,@body)))
