(fn make-object (&rest x)
  (!= (%%%make-object)
    (@ (i (group x 2) !)
      (%=-aref .i. ! (? (symbol? i.)
                        (downcase (symbol-name i.))
                        i.)))))
