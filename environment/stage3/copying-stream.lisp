; tré – Copyright (c) 2005–2006,2008,2010–2013,2015 Sven Michael Klose <pixel@hugbox.org>

(defstruct copying-stream-info
  in
  out
  (recorded-in  (make-queue))
  (recorded-out (make-queue)))

(defun make-copying-stream (&key (in nil) (out nil))
  (make-stream
      :user-detail (make-copying-stream-info :in in :out out)
      :fun-in #'((str)
                  (let info (stream-user-detail str)
                    (aprog1 (read-char (copying-stream-info-in info))
                      (enqueue (copying-stream-info-recorded-in info) !))))
      :fun-out #'((x str)
                   (let info (stream-user-detail str)
                     (enqueue (copying-stream-info-recorded-out info) x)
                     (princ x (copying-stream-info-out info))))
	  :fun-eof #'((str)
                   (stream-fun-eof (copying-stream-info-in (stream-user-detail str))))))

(defun copying-stream-recorded-in (str)
  (list-string (queue-list (copying-stream-info-recorded-in (stream-user-detail str)))))

(defun copying-stream-recorded-out (str)
  (list-string (queue-list (copying-stream-info-recorded-out (stream-user-detail str)))))