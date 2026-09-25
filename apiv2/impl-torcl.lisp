;;;; Native synchronization SPI for the in-progress TorCL backend.
;;;; ASDF activation waits for the thread/atomic/weak-table prerequisites.

(in-package :bordeaux-threads-2)

(deftype native-lock () 'torcl-thread:mutex)
(deftype native-recursive-lock () 'torcl-thread:mutex)
(deftype condition-variable () 'torcl-thread:condition-variable)

(defun %make-lock (name)
  (torcl-thread:make-mutex :name name))

(defun %acquire-lock (lock waitp timeout)
  (torcl-thread:grab-mutex lock :waitp waitp :timeout timeout))

(defun %release-lock (lock)
  (torcl-thread:release-mutex lock))

(defmacro %with-lock ((place timeout) &body body)
  `(torcl-thread:with-mutex (,place :timeout ,timeout) ,@body))

(defun %make-recursive-lock (name)
  (torcl-thread:make-mutex :name name :recursive t))

(defun %acquire-recursive-lock (lock waitp timeout)
  (torcl-thread:grab-mutex lock :waitp waitp :timeout timeout))

(defun %release-recursive-lock (lock)
  (torcl-thread:release-mutex lock))

(defmacro %with-recursive-lock ((place timeout) &body body)
  `(torcl-thread:with-mutex (,place :timeout ,timeout) ,@body))

(defun %make-condition-variable (name)
  (torcl-thread:make-condition-variable :name name))

(defun %condition-wait (condition-variable lock timeout)
  ;; TorCL returns with the mutex owned even when the wait times out.
  (torcl-thread:condition-wait condition-variable lock :timeout timeout))

(defun %condition-notify (condition-variable)
  (torcl-thread:condition-notify condition-variable))

(defun %condition-broadcast (condition-variable)
  (torcl-thread:condition-broadcast condition-variable))
