; tré – Copyright (c) 2006–2015 Sven Michael Klose <pixel@hugbox.org>

(defvar *tagbody-replacements*)

(defun init-compiler-macros ()
  (= *tagbody-replacements* nil))

(define-expander 'compiler :pre  #'init-compiler-macros)

(defmacro define-compiler-macro (name args &body x)
  (print-definition `(define-compiler-macro ,name ,args))
  `(define-expander-macro (expander-get 'compiler) ,name ,args ,@x))

(defun compiler-macroexpand (x)
  (expander-expand 'compiler x))

(define-compiler-macro cond (&rest args)
  (with-compiler-tag end-tag
    `(%%block
       ,@(mapcan [with-compiler-tag next
                   (when _.
                     `(,@(unless (t? _.)
                           `((%= ~%ret ,_.)
                             (%%go-nil ,next ~%ret)))
				       ,@(!? (wrap-atoms ._)
				             `((%= ~%ret (%%block ,@!))))
                       (%%go ,end-tag)
                       ,@(unless (t? _.)
                           (list next))))]
			     args)
       ,end-tag
	   (identity ~%ret))))

(define-compiler-macro progn (&body body)
  (!? body
      `(%%block ,@(wrap-atoms !))))

(define-compiler-macro setq (&rest args)
  `(%%block ,@(@ [`(%= ,_. ,._.)]
                 (group args 2))))

(defun make-? (body)
  (with (tests (group body 2)
         end   (car (last tests)))
    (unless body
      (error "Body is missing."))
    `(cl:cond
       ,@(? (sole? end)
            (+ (butlast tests) (list (. t end)))
            tests))))

(define-compiler-macro ? (&body body)
  (make-? body))

; XXX the expression expansion should be redone from scratch and then it should be able to deal with this.
(defun compress-%%blocks (body)
  (mapcan [? (%%block? _)
             ._
             (list _)]
          body))

(define-compiler-macro %%block (&body body)
   (?
     .body            `(%%block ,@(compress-%%blocks body))
     (vm-jump? body.) `(%%block ,body.)
     body.            body.))

(define-compiler-macro function (&rest x)
  `(function ,x. ,@(!? .x
                       (compress-%%blocks !))))


;; TAGBODY

(define-expander 'tagbodyexpand)
(defvar *tagbody-replacements* nil)

(defun tag-replacement (tag)
  (cdr (assoc tag *tagbody-replacements* :test #'eq)))

(defun tagbodyexpand (body)
  (with-temporary *tagbody-replacements* nil
    (@ [? (atom _)
          (acons! _ (make-compiler-tag) *tagbody-replacements*)]
       body)
    `(%%block
       ,@(@ [| (& (atom _)
                   (tag-replacement _))
               _]
            (expander-expand 'tagbodyexpand body))
       (identity nil))))

(define-expander-macro (expander-get 'tagbodyexpand) go (tag)
  (!? (tag-replacement tag)
      `(%%go ,!)
      (error "Can't find tag ~A in TAGBODY." tag)))

(define-expander-macro (expander-get 'tagbodyexpand) tagbody (&body body)
  (tagbodyexpand body))

(define-compiler-macro tagbody (&body body)
  (tagbodyexpand body))


;; BLOCK

(define-expander 'blockexpand)
(defvar *blocks* nil)

(defun blockexpand (name body)
  (? body
	 (with-compiler-tag end-tag
	   (with-temporary *blocks* (. (. name end-tag) *blocks*)
         (with (b     (expander-expand 'blockexpand body)
                head  (butlast b)
                tail  (last b)
                ret   `(%%block
                         ,@head
                         ,@(? (vm-jump? tail.)
                              tail
                              `((%= ~%ret ,@tail)))))
           (append ret `(,end-tag
                         (identity ~%ret))))))
    `(identity nil)))

(define-expander-macro (expander-get 'blockexpand) return-from (block-name expr)
  (| *blocks*
     (error "RETURN-FROM outside BLOCK."))
  (!? (assoc block-name *blocks* :test #'eq)
     `(%%block
        (%= ~%ret ,expr)
        (%%go ,.!))
     (error "RETURN-FROM unknown BLOCK ~A." block-name)))

(define-expander-macro (expander-get 'blockexpand) block (name &body body)
  (blockexpand name body))

(define-compiler-macro block (name &body body)
  (blockexpand name body))
