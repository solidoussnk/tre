;;;; CODE GENERATION HELPERS

(defvar *php-by-reference?* nil)

(fn php-line (&rest x)
  `(,*php-indent* ,@x ,*php-separator*))

(fn php-dollarize (x)
  (? (symbol? x)
     (?
       (not x)      "NULL"
       (eq t x)     "TRUE"
       (number? x)  x
       (string? x)  x
	   `("$" ,x))
	 x))

(fn php-list (x)
  (pad (@ #'php-dollarize x) ", "))

(fn php-argument-list (x)
  (c-list (@ #'php-dollarize x)))

(define-codegen-macro-definer define-php-macro *php-transpiler*)

(defmacro define-php-infix (name)
  `(define-transpiler-infix *php-transpiler* ,name))


;;;; TRUTH

(transpiler-translate-symbol *php-transpiler* nil "NULL")
(transpiler-translate-symbol *php-transpiler* t "TRUE")


;;;; LITERAL SYMBOLS

(define-php-macro quote (x)
  (php-compiled-symbol x))


;;;; CONTROL FLOW

(define-php-macro %%tag (tag)
  `(%%native "_I_" ,tag ":" ,*php-newline*))

(fn php-jump (tag)
  `("goto _I_" ,tag))

(define-php-macro %%go (tag)
  (php-line (php-jump tag)))

(define-php-macro %%go-nil (tag val)
  (let v (php-dollarize val)
    (php-line "if (!" v " && !is_string (" v ") && !is_numeric (" v ") && !is_array (" v ")) " (php-jump tag))))

(define-php-macro %%go-not-nil (tag val)
  (let v (php-dollarize val)
    (php-line "if (!(!" v " && !is_string (" v ") && !is_numeric (" v ") && !is_array (" v "))) " (php-jump tag))))


;;;; FUNCTIONS

(fn codegen-php-function (x)
  (with (fi            (get-lambda-funinfo x)
         name          (funinfo-name fi)
		 num-locals    (length (funinfo-vars fi))
	     compiled-name (compiled-function-name name))
    (developer-note "Generating function ~A…~%" name)
    `(,*php-newline*
      ,(funinfo-comment fi)
	  "function " ,compiled-name ,@(php-argument-list (funinfo-args fi))
      "{" ,(code-char 10)
		 ,@(awhen (funinfo-globals fi)
             (php-line "global " (php-list !)))
         ,@(& *print-executed-functions?*
              `("echo \"" ,compiled-name "\\n\";"))
         ,@(lambda-body x)
       	 ,(php-line "return $" '~%ret)
      "}" ,*php-newline*)))

(define-php-macro function (&rest x)
  (? .x
     (codegen-php-function (. 'function x))
     `(%%native (%%string ,(obfuscated-identifier x.)))))

(define-php-macro %function-prologue (name) '(%%native ""))
(define-php-macro %function-epilogue (name) '(%%native ""))
(define-php-macro %function-return (name)   '(%%native ""))

(fn php-codegen-argument-filter (x)
  (php-dollarize x))

(define-php-macro %closure (name)
  (with (fi            (get-funinfo name)
         native-name  `(%%string ,(compiled-function-name-string name)))
    (? (funinfo-scope-arg fi)
  	   `(%%native "new __closure (" ,native-name "," ,(php-dollarize (funinfo-scope (funinfo-parent fi))) ")")
       native-name)))


;;;; ASSIGNMENTS

(fn %%native-without-reference? (val)
  (& (%%native? val)
     (string? .val.)
     (empty-string? .val.)))

(fn php-assignment-operator (val)
  (? (| (& (atom val) ; XXX required?
	  	   (symbol? val))
		(not (%%native-without-reference? val)))
     (? *php-by-reference?*
   	    " =& "
        " = ")
  	 " = "))
 
(fn php-%=-value (val)
  (?
    (& (cons? val)      ; XXX required?
       (eq 'tre_cons val.))
      `("new __cons (" ,(php-dollarize .val.) ", " ,(php-dollarize ..val.) ")")
    (| (not val)        ; XXX CONSTANT-LITERAL?
       (eq t val)
       (number? val)
       (string? val))
      (list val)
	(| (atom val)
       (& (%%native? val)
          (atom .val.)
          (not ..val)))
      (list "$" val)
	(codegen-expr? val)
	  (list val)
    `((,val. " " ,@(c-list (@ #'php-codegen-argument-filter .val))))))

(fn php-%=-0 (dest val)
  `((%%native
	    ,*php-indent*
	    ,@(? dest
			 `(,@(& (atom dest)
				    (list "$"))
			   ,dest
			   ,(php-assignment-operator val))
	         '(""))
        ,@(php-%=-value val)
        ,@(unless (& (not dest)
                     (%%native? val)
                     (not ..val))
            (list *php-separator*)))))

(define-php-macro %= (dest val)
  (? (& (not dest) (atom val))
     '(%%native "")
     (php-%=-0 dest val)))

(define-php-macro %set-local-fun (plc val)
  `(%%native ,(php-dollarize plc)
             ,(php-assignment-operator val)
             ,(php-dollarize val)))


;;;; VECTORS

(define-php-macro %make-scope (&rest elements)
  `(%%native "new __l ()" ""))

(define-php-macro %vec (v i)
  `(%%native ,(php-dollarize v) "->g (" ,(php-dollarize i) ")"))

(define-php-macro %set-vec (v i x)
  `(%%native ,*php-indent* ,(php-dollarize v) "->s (" ,(php-dollarize i) ", " ,(php-%=-value x) ")",*php-separator*))


;;;; NUMBERS

(defmacro define-php-binary (op replacement-op)
  (print-definition `(define-php-binary ,op ,replacement-op))
  (transpiler-add-plain-arg-fun *php-transpiler* op)
  `(define-expander-macro (transpiler-codegen-expander *php-transpiler*) ,op (&rest args)
     `(%%native ,,@(pad (@ #'php-dollarize args)
                ,(+ " " replacement-op " ")))))

(mapcar-macro x
    '((%%%+       "+")
      (%%%-       "-")
      (%%%*       "*")
      (%%%/       "/")
      (%%%mod     "%")

      (%%%==      "==")
      (%%%<       "<")
      (%%%>       ">")
      (%%%<=      "<=")
      (%%%>=      ">=")
      (%%%eq      "===")

      (%%%<<      "<<")
      (%%%>>      ">>")
      (%%%bit-or  "|")
      (%%%bit-and "&"))
  `(define-php-binary ,@x))

(define-php-binary %%%string+ ".")


;;;; ARRAYS

(fn php-array-subscript (indexes)
  (@ [`("[" ,(php-dollarize _) "]")] indexes))

(fn php-literal-array-element (x)
  (list (compiled-function-name '%%key) " (" (php-dollarize x.) ") => " (php-dollarize .x.)))

(fn php-literal-array-elements (x)
  (pad (@ #'php-literal-array-element x) ", "))

(define-php-macro %%%make-object (&rest elements)
  `(%%native "Array (" ,@(php-literal-array-elements (group elements 2)) ")"))

(define-php-macro make-array (&rest elements)
  `(%%native "new __array ()" ""))

(define-php-macro aref (arr &rest indexes)
  `(href ,arr ,@indexes))

(define-php-macro =-aref (val arr &rest indexes)
  `(=-href ,val ,arr ,@indexes))

(define-php-macro %aref (arr &rest indexes)
  `(%%native ,(php-dollarize arr) ,@(php-array-subscript indexes)))

(define-php-macro %aref-defined? (arr &rest indexes)
  `(%%native "isset (" ,(php-dollarize arr) ,@(php-array-subscript indexes) ")"))

(define-php-macro =-%aref (val &rest x)
  `(%%native (%aref ,@x)
             ,(php-assignment-operator val)
             ,(php-dollarize val)))


;;;; HASH TABLES

(define-php-macro href (h k)
  `(%%native "(is_a (" ,(php-dollarize h) ", '__l') || is_a (" ,(php-dollarize h) ", '__array')) ? "
                 ,(php-dollarize h) "->g(tre_T37T37key (" ,(php-dollarize k) ")) : "
                 "(isset (" ,(php-dollarize h) "[tre_T37T37key (" ,(php-dollarize k) ")]) ? "
                     ,(php-dollarize h) "[tre_T37T37key (" ,(php-dollarize k) ")] : "
                     "NULL)"))

(define-php-macro =-href (v h k)
  `(%%native "(is_a (" ,(php-dollarize h) ", '__l') || is_a (" ,(php-dollarize h) ", '__array')) ? "
                 ,(php-dollarize h) "->s(tre_T37T37key (" ,(php-dollarize k) ")," ,(php-dollarize v) ") : "
                 ,(php-dollarize h) "[tre_T37T37key (" ,(php-dollarize k) ")] = " ,(php-dollarize v)))

(define-php-macro hremove (h key)
  `(%%native "null; unset ($" ,h "[" ,(php-dollarize key) "])"))

(define-php-macro make-hash-table (&rest ignored-args)
  `(make-array))

(define-php-macro %%make-hash-table (&rest args)
  `(%%native "new __array (Array (" ,@(php-literal-array-elements (group args 2)) "))"))


;;;; OBJECTS

(define-php-macro %new (&rest x)
  (? x
     `(%%native "new " ,x. ,@(php-argument-list .x))
     `(%%native "[]")))

(define-php-macro delete-object (x)
  `(%%native "null; unset " ,x))

(define-php-macro %slot-value (x y)
  (? (cons? x)
	 (? (%%native? x)
        `(%%native ,(php-dollarize x) "->" ,y)
        `(%%native ,x "->" ,y))
	 `(%%native "$" ,x "->" ,y)))

(define-php-macro %php-class-head (name)
  `(%%native "class " ,name "{"))

(define-php-macro %php-class-tail ()
  `(%%native "}" ""))


;;;; GLOBAL VARIABLES

(define-php-macro %global (x)
  `(%%native "$GLOBALS['" ,(obfuscated-identifier x) "']"))


;;;; MISCELLANEOUS

(define-php-macro %%comment (&rest x)
  `(%%native "/* " ,@x " */" ,*newline*))
