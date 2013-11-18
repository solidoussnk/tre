;;;;; tré – Copyright (c) 2009,2012–2013 Sven Michael Klose

(defmacro define-file-ending-predicate (name)
  (let sname (string-downcase (symbol-name name))
    `(defun ,($ name '-suffix?) (x)
	   (== ,(+ "." sname)
		   (x.substr (- (length x) ,(++ (length sname))))))))

(mapcan-macro x
	'(html php css)
  `((define-file-ending-predicate ,x)))
