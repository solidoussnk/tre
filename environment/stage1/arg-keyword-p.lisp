(%defun %arg-keyword? (x)
  (| (eq x '&rest)
     (eq x '&body)
     (eq x '&optional)
     (eq x '&key)))
