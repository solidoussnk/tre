; tré – Copyright (c) 2009–2015 Sven Michael Klose <pixel@hugbox.org>

(defun unassigned-%stackarg? (x)
  (& (%stackarg? x) ..x))

(defun unassigned-%stack? (x)
  (& (%stack? x) ..x))

(defun unassigned-%vec? (x)
  (& (%vec? x) ...x))

(defun unassigned-%set-vec? (x)
  (& (%set-vec? x) ....x))

(defun place-assign-error (x v)
  (error "Can't assign place because the index in scoped vars for ~A is missing in ~A." v x))

(defun place-assign-stackarg (x)
  (let fi (get-funinfo .x.)
    (? (arguments-on-stack?)
       (integer (+ (length (funinfo-vars fi)) (- (length (funinfo-args fi)) (funinfo-arg-pos fi ..x.) 1)))
       (error "Cannot assign stack argument ~A." ..x.))))

(define-tree-filter place-assign-0 (x)
  (| (%quote? x)
     (%%native? x))  x
  (unassigned-%stackarg? x)    `(%stack ,(place-assign-stackarg x))
  (unassigned-%stack? x)       `(%stack ,(| (funinfoname-var-pos .x. ..x.)
                                            (place-assign-stackarg x)))
  (unassigned-%vec? x)         `(%vec ,(place-assign-0 .x.)
		                              ,(| (funinfoname-scoped-var-index ..x. ...x.)
                                          (place-assign-error x ...x.)))
  (unassigned-%set-vec? x)     `(%set-vec ,(place-assign-0 .x.)
		                                  ,(| (funinfoname-scoped-var-index ..x. ...x.)
                                              (place-assign-error x ...x.))
                                          ,(place-assign-0 ....x.))
  (named-lambda? x)            (copy-lambda x :body (place-assign-0 (lambda-body x)))
  (%slot-value? x)             `(%slot-value ,(place-assign-0 .x.) ,..x.))

(def-pass-fun place-assign x
  (place-assign-0 x))
