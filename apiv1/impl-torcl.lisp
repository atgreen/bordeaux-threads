;;;; Native threads and synchronization for TorCL.

(in-package #:bordeaux-threads)

(deftype thread () 'fixnum)

(defun %make-thread (function name)
  (torcl-thread:make-thread function :name name))

(defun current-thread ()
  (torcl-thread:current-thread))

(defun threadp (object)
  ;; TorCL's temporary native-thread ABI is a fixnum handle. A first-class
  ;; descriptor will eventually make this predicate narrower.
  (typep object 'fixnum))

(defun thread-name (thread)
  (torcl-thread:thread-name thread))

(defun thread-yield ()
  (torcl-thread:thread-yield))

(defun all-threads ()
  (torcl-thread:all-threads))

(defun thread-alive-p (thread)
  (torcl-thread:thread-alive-p thread))

(defun join-thread (thread)
  (torcl-thread:join-thread thread))

;; TorCL does not yet support asynchronous interruption. Override the portable
;; helper so it fails before creating a timer thread that it cannot stop.
(defmacro with-timeout ((timeout) &body body)
  (declare (ignore timeout body))
  `(error (make-threading-support-error)))

(deftype lock () 'torcl-thread:mutex)
(deftype recursive-lock () 'torcl-thread:mutex)

(defun lock-p (object)
  (torcl-thread:mutex-p object))

(defun recursive-lock-p (object)
  (torcl-thread:mutex-p object))

(defun make-lock (&optional name)
  (torcl-thread:make-mutex :name name))

(defun acquire-lock (lock &optional (wait-p t))
  (torcl-thread:grab-mutex lock :waitp wait-p))

(defun release-lock (lock)
  (torcl-thread:release-mutex lock))

(defmacro with-lock-held ((place) &body body)
  `(torcl-thread:with-mutex (,place) ,@body))

(defun make-recursive-lock (&optional name)
  (torcl-thread:make-mutex :name name :recursive t))

(defun acquire-recursive-lock (lock)
  (torcl-thread:grab-mutex lock))

(defun release-recursive-lock (lock)
  (torcl-thread:release-mutex lock))

(defmacro with-recursive-lock-held ((place &key timeout) &body body)
  `(torcl-thread:with-mutex (,place :timeout ,timeout) ,@body))

(defun make-condition-variable (&key name)
  (torcl-thread:make-condition-variable :name name))

(defun condition-wait (condition-variable lock &key timeout)
  ;; TorCL reacquires the mutex on both notification and timeout.
  (torcl-thread:condition-wait condition-variable lock :timeout timeout))

(defun condition-notify (condition-variable)
  (torcl-thread:condition-notify condition-variable))

(mark-supported)
