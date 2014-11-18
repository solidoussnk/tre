;;;;; tré – Copyright (c) 2014 Sven Michael Klose <pixel@hugbox.org>

(defun directory-tree (pathname)
  (print pathname)
  (let d (%directory pathname)
    (when (number? d)
      (? (== 13 d)
         (return nil))
      (error (%strerror d)))
    (filter [with (p  (string-concat pathname "/" _)
                   s  (stat p))
              (& (number? s)
                 (error (%strerror s)))
              (= (dirent-name s) _)
              (& (| (string== "." _)
                    (string== ".." _))
                 (return s))
              (& (eq (dirent-type s) 'directory)
                 (not (dirent-symbolic-link? s))
                 (= (dirent-list s) (directory-tree p)))
              s]
            d)))