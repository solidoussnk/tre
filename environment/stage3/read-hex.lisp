; tré – Copyright (c) 2008–2009,2012–2016 Sven Michael Klose <pixel@hugbox.org>

(defun read-hex (str)
  (with (rec #'((v)
				    (!? (& (peek-char str)
                           (alet (char-upcase (peek-char str))
                             (& (hex-digit-char? !)
                                !)))
					    {(read-char str)
					     (rec (number+ (* v 16)
						               (- (char-code !)
                                          (? (digit-char? !)
							                 (char-code #\0)
							                 (- (char-code #\A) 10)))))]
					    v)))
    (| (hex-digit-char? (peek-char str))
	   (error "Illegal character '~A' at begin of hexadecimal number." (peek-char str)))
	(prog1
      (rec 0)
	  (& (symbol-char? (peek-char str))
		 (error "Illegal character '~A' in hexadecimal number." (peek-char str))))))
