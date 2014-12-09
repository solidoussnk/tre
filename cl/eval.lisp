;;;;; tré – Copyright (c) 2014 Sven Michael Klose <pixel@copei.de>

(in-package :tre-core)

(defvar *quasiquoteexpand-hook* nil)
(defvar *dotexpand-hook* nil)

(defun function-expr? (x)
  (and (consp x)
       (eq 'function (car x))
       (not (atom (cadr x)))
       (not (eq 'lambda (caadr x)))))

(defun make-lambdas (x)
  (cond
    ((atom x)                  (? (eq '&body x)
                                  '&rest
                                  x))
    ((eq 'quote (car x))       x)
    ((function-expr? (car x))  `(labels ((~local-var-fun ,@(make-lambdas (cadar x))))
                                  (~local-var-fun ,@(make-lambdas (cdr x)))))
;    ((function-expr? x)        `(let ((~anonymous-fun #'(lambda ,@(make-lambdas (cadr x)))))
;                                  (setf (gethash ~anonymous-fun *function-atom-sources*) ',(cadr x))
;                                  ~anonymous-fun))
    ((function-expr? x)        `#'(lambda ,@(make-lambdas (cadr x))))
    (t (mapcar #'make-lambdas x))))

(defun tre2cl (x)
  (make-lambdas (early-macroexpand (car (backquote-expand (list x))))))

(defun %eval (x)
  (eval (tre2cl x)))
