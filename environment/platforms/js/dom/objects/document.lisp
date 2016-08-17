; tré – Copyright (c) 2016 Sven Michael Klose <pixel@copei.de>

(defclass caroshi-html-document ()
  this)

(defmember caroshi-html-document
    document-element
    query-selector
    query-selector-all)

(defmethod caroshi-html-document get (css-selector)
  (query-selector css-selector))

(defmethod caroshi-html-document get-list (css-selector)
  (array-list (query-selector-all css-selector)))

(defmethod caroshi-html-document get-last (css-selector)
  (last (get-list css-selector)))

(defmethod caroshi-html-document get-nodes (css-selector)
  (new nodelist (get-list css-selector)))

(defmethod caroshi-html-document get-html ()
  document-element.outer-h-t-m-l)

(finalize-class caroshi-html-document)