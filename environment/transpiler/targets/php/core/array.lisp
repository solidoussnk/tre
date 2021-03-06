(fn array? (x)
  (| (is_a x "__array")
     (& (is_array x)
        (is_int (key x)))))

(fn %array-push (arr x)
  (%= (%%native "$" arr "[]") x)
  x)

(fn array-push (arr x)
  (? (is_a x "__array")
     (arr.p x)
     (%array-push arr x))
  x)

(fn list-array (x)
  (let a (make-array)
    (@ (i x a)
      (a.p i))))

(fn list-phphash (x)
  (!= (%%%make-object)
    (@ (i x !)
      (%= (%%native "$" ! "[]") i))))

(fn aref (a k)
  (? (is_array a)
     (%aref a k)
     (href a k)))

(fn (= aref) (v a k)
  (? (is_array a)
     (=-%aref v a k)
     (=-href v a k)))
