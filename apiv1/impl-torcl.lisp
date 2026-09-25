;;;; Native synchronization for TorCL. Thread lifecycle integration is pending;
;;;; this file is not selected by ASDF until the complete backend is validated.

(in-package #:bordeaux-threads)

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
