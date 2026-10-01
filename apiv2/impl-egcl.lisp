;;;; Native thread and synchronization SPI for EGCL.

(in-package :bordeaux-threads-2)

(deftype native-thread () 'fixnum)

(defun %make-thread (function name)
  (egcl-thread:make-thread function :name name))

(defun %current-thread ()
  (egcl-thread:current-thread))

(defun %thread-name (thread)
  (egcl-thread:thread-name thread))

(defun %join-thread (thread)
  (egcl-thread:join-thread thread))

(defun %thread-yield ()
  (egcl-thread:thread-yield))

(defun %all-threads ()
  (egcl-thread:all-threads))

(mark-not-implemented 'interrupt-thread)
(defun %interrupt-thread (thread function)
  (declare (ignore thread function))
  (signal-not-implemented 'interrupt-thread))

(mark-not-implemented 'destroy-thread)
(defun %destroy-thread (thread)
  (declare (ignore thread))
  (signal-not-implemented 'destroy-thread))

(mark-not-implemented 'with-timeout)
(defmacro with-timeout ((timeout) &body body)
  (declare (ignore timeout body))
  `(signal-not-implemented 'with-timeout))

(defun %thread-alive-p (thread)
  (egcl-thread:thread-alive-p thread))

(deftype native-lock () 'egcl-thread:mutex)
(deftype native-recursive-lock () 'egcl-thread:mutex)
(deftype condition-variable () 'egcl-thread:condition-variable)

(defun %make-lock (name)
  (egcl-thread:make-mutex :name name))

(defun %acquire-lock (lock waitp timeout)
  (egcl-thread:grab-mutex lock :waitp waitp :timeout timeout))

(defun %release-lock (lock)
  (egcl-thread:release-mutex lock))

(defmacro %with-lock ((place timeout) &body body)
  `(egcl-thread:with-mutex (,place :timeout ,timeout) ,@body))

(defun %make-recursive-lock (name)
  (egcl-thread:make-mutex :name name :recursive t))

(defun %acquire-recursive-lock (lock waitp timeout)
  (egcl-thread:grab-mutex lock :waitp waitp :timeout timeout))

(defun %release-recursive-lock (lock)
  (egcl-thread:release-mutex lock))

(defmacro %with-recursive-lock ((place timeout) &body body)
  `(egcl-thread:with-mutex (,place :timeout ,timeout) ,@body))

(defun %make-condition-variable (name)
  (egcl-thread:make-condition-variable :name name))

(defun %condition-wait (condition-variable lock timeout)
  ;; EGCL returns with the mutex owned even when the wait times out.
  (egcl-thread:condition-wait condition-variable lock :timeout timeout))

(defun %condition-notify (condition-variable)
  (egcl-thread:condition-notify condition-variable))

(defun %condition-broadcast (condition-variable)
  (egcl-thread:condition-broadcast condition-variable))
