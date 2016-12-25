(defmacro push (elm expr)
  `(= ,expr (. ,elm ,expr)))

(defmacro pop (expr)
  `(let ret (car ,expr)
     (= ,expr (cdr ,expr))
     ret))

(defun pop! (args)
  (let ret args.
    (= args. .args.
       .args ..args)
    ret))
