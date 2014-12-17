;;;;; tré – Copyright (c) 2008,2010,2012–2014 Sven Michael Klose <pixel@copei.de>

(defun token-is-quote? (x)
  (in? x 'quote 'backquote 'quasiquote 'quasiquote-splice 'accent-circonflex))

(defun %read-closing-bracket? (x)
  (in? x 'bracket-close 'square-bracket-close 'curly-bracket-close))

(defun special-char? (x)
  (in=? x #\( #\)
          #\[ #\]
          #\{ #\}
          #\' #\` #\, #\: #\; #\" #\# #\^))

(defun symbol-char? (x)
  (& (> x 32)
     (not (special-char? x))))

(defun skip-comment (str)
  (let-when c (read-char str)
	(? (in=? c 10)
	   (skip-spaces str)
	   (skip-comment str))))

(defun skip-spaces (str)
 (let-when c (peek-char str)
   (when (== #\; c)
     (skip-comment str))
   (when (whitespace? c)
     (read-char str)
     (skip-spaces str))))

(defun get-symbol-0 (str)
  (let c (char-upcase (peek-char str))
    (? (== #\; c)
       (progn
         (skip-comment str)
         (get-symbol-0 str))
       (& (symbol-char? c)
          (cons (char-upcase (read-char str))
                (get-symbol-0 str))))))

(defun get-symbol (str)
  (let-when c (peek-char str)
    (unless (special-char? c)
      (get-symbol-0 str))))

(defun get-symbol-and-package (str)
  (skip-spaces str)
  (let sym (get-symbol str)
	(? (== (peek-char str) #\:)
	   (values (| sym t) (& (read-char str)
				            (get-symbol str)))
	   (values nil sym))))

(defun read-string-0 (str)
  (let c (read-char str)
    (unless (== c #\")
      (cons (? (== c #\\)
               (read-char str)
               c)
         (read-string-0 str)))))

(defun read-string (str)
  (list-string (read-string-0 str)))

(defun read-comment-block (str)
  (while (not (& (== #\| (read-char str))
			     (== #\# (peek-char str))))
	     (read-char str)
    nil))

(defun list-number? (x)
  (& (| (& (cdr x)
           (| (== #\- (car x))
              (== #\. (car x))))
        (digit-char? (car x)))
     (? (cdr x)
        (every [| (digit-char? _)
                  (== #\. _)]
               (cdr x))
        t)))

(defun read-token (str)
  (with ((pkg sym) (get-symbol-and-package str))
	(values (? (& sym
                  (not (cdr sym))
                  (== #\. (car sym)))
		       'dot
		       (? sym
                  (? (list-number? sym)
                     'number
			         'symbol)
			      (case (read-char str) :test #'character==
			        #\(	 'bracket-open
			        #\)	 'bracket-close
			        #\[	 'square-bracket-open
			        #\]	 'square-bracket-close
			        #\{	 'curly-bracket-open
			        #\}	 'curly-bracket-close
			        #\'	 'quote
			        #\`	 'backquote
			        #\^	 'accent-circonflex
			        #\"	 'dblquote
			        #\,	 (? (== #\@ (peek-char str))
				            (& (read-char str) 'quasiquote-splice)
				            'quasiquote)
			        #\#	(case (read-char str) :test #'character==
				          #\\  'char
				          #\x  'hexnum
				          #\'  'function
				          #\|  (read-comment-block str)
				          (error "Invalid character after '#'."))
			        -1	'eof)))
		     pkg sym)))

(defun read-slot-value (x)
  (? x
     (? (cdr x)
        `(slot-value ,(read-slot-value (butlast x)) ',(make-symbol (car (last x))))
        (? (string? (car x))
           (make-symbol (car x))
           (car x)))))

(defun read-symbol-or-slot-value (sym pkg)
  (alet (filter [& _ (list-string _)]
                (split #\. sym))
    (? (& (cdr !) (car !) (car (last !)))
       (read-slot-value !)
       (make-symbol (list-string sym)
                    (?
                      (not pkg)   nil
                      (eq t pkg)  *keyword-package*
                      (find-package (list-string pkg)))))))

(defun read-atom (str token pkg sym)
  (case token :test #'eq
    'dblquote  (read-string str)
    'char      (read-char str)
    'number    (with-stream-string s (list-string sym)
                 (read-number s))
    'hexnum    (read-hex str)
	'function  `(function ,(read-expr str))
    'symbol    (read-symbol-or-slot-value sym pkg)
	(error "Syntax error: token ~A, sym ~A." token sym)))

(defun read-quote (str token)
  (list token (read-expr str)))

(defun read-set-listprop (str)
  (alet (stream-input-location str)
    (= *default-listprop* (cons (stream-location-id !)
                                (cons (memorized-number (stream-location-column !))
                                      (memorized-number (stream-location-line !)))))))

(defun read-list (str token pkg sym)
  (| token (error "Missing closing bracket."))
  (unless (%read-closing-bracket? token)
    (cons (with-temporary *default-listprop* *default-listprop*
            (case token :test #'eq
              'bracket-open        (read-cons-slot str)
              'square-bracket-open (cons 'square (read-cons-slot str))
              'curly-bracket-open  (cons 'curly (read-cons-slot str))
              (? (token-is-quote? token)
                 (read-quote str token)
                 (read-atom str token pkg sym))))
          (with-temporary *default-listprop* *default-listprop*
            (with ((token pkg sym) (read-token str))
              (? (eq 'dot token)
                 (with (x                (read-expr str)
                        (token pkg sym)  (read-token str))
                   (| (%read-closing-bracket? token)
                      (error "Only one value allowed after dotted cons."))
                   x)
                 (read-list str token pkg sym)))))))

(defun read-cons (str)
  (with ((token pkg sym) (read-token str))
    (? (eq token 'dot)
       (cons 'cons (read-cons str))
	   (read-list str token pkg sym))))

(defun read-cons-slot (str)
  (read-set-listprop str)
  (with-temporary *default-listprop* *default-listprop*
    (alet (read-cons str)
      (? (== #\. (peek-char str))
         (progn
           (read-char str)
           (with ((token pkg sym) (read-token str))
             (read-slot-value (list ! (list-string sym)))))
         !))))

(defun read-expr (str)
  (with ((token pkg sym) (read-token str))
    (case token :test #'eq
      nil                   nil
      'eof                  nil
      'bracket-open         (read-cons-slot str)
      'square-bracket-open  (cons 'square (read-cons-slot str))
      'curly-bracket-open   (cons 'curly (read-cons-slot str))
      (? (token-is-quote? token)
         (read-quote str token)
         (read-atom str token pkg sym)))))

(defun read (&optional (str *standard-input*))
  (skip-spaces str)
  (& (peek-char str)
	 (read-expr str)))

(defun read-all (str)
  (skip-spaces str)
  (& (peek-char str)
     (cons (read str)
           (read-all str))))
