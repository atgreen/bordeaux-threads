;;;; Native threads and synchronization for EGCL.

(in-package #:bordeaux-threads)

(deftype thread () 'fixnum)

(defun %make-thread (function name)
  (egcl-thread:make-thread function :name name))

(defun current-thread ()
  (egcl-thread:current-thread))

(defun threadp (object)
  ;; EGCL's temporary native-thread ABI is a fixnum handle. A first-class
  ;; descriptor will eventually make this predicate narrower.
  (typep object 'fixnum))

(defun thread-name (thread)
  (egcl-thread:thread-name thread))

(defun thread-yield ()
  (egcl-thread:thread-yield))

(defun all-threads ()
  (egcl-thread:all-threads))

(defun thread-alive-p (thread)
  (egcl-thread:thread-alive-p thread))

(defun join-thread (thread)
  (egcl-thread:join-thread thread))

;; EGCL does not yet support asynchronous interruption. Override the portable
;; helper so it fails before creating a timer thread that it cannot stop.
(defmacro with-timeout ((timeout) &body body)
  (declare (ignore timeout body))
  `(error (make-threading-support-error)))

(deftype lock () 'egcl-thread:mutex)
(deftype recursive-lock () 'egcl-thread:mutex)

(defun lock-p (object)
  (egcl-thread:mutex-p object))

(defun recursive-lock-p (object)
  (egcl-thread:mutex-p object))

(defun make-lock (&optional name)
  (egcl-thread:make-mutex :name name))

(defun acquire-lock (lock &optional (wait-p t))
  (egcl-thread:grab-mutex lock :waitp wait-p))

(defun release-lock (lock)
  (egcl-thread:release-mutex lock))

(defmacro with-lock-held ((place) &body body)
  `(egcl-thread:with-mutex (,place) ,@body))

(defun make-recursive-lock (&optional name)
  (egcl-thread:make-mutex :name name :recursive t))

(defun acquire-recursive-lock (lock)
  (egcl-thread:grab-mutex lock))

(defun release-recursive-lock (lock)
  (egcl-thread:release-mutex lock))

(defmacro with-recursive-lock-held ((place &key timeout) &body body)
  `(egcl-thread:with-mutex (,place :timeout ,timeout) ,@body))

(defun make-condition-variable (&key name)
  (egcl-thread:make-condition-variable :name name))

(defun condition-wait (condition-variable lock &key timeout)
  ;; EGCL reacquires the mutex on both notification and timeout.
  (egcl-thread:condition-wait condition-variable lock :timeout timeout))

(defun condition-notify (condition-variable)
  (egcl-thread:condition-notify condition-variable))

(mark-supported)
