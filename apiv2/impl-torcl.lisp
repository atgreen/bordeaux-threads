;;;; Native thread and synchronization SPI for TorCL.

(in-package :bordeaux-threads-2)

(deftype native-thread () 'fixnum)

(defun %make-thread (function name)
  (torcl-thread:make-thread function :name name))

(defun %current-thread ()
  (torcl-thread:current-thread))

(defun %thread-name (thread)
  (torcl-thread:thread-name thread))

(defun %join-thread (thread)
  (torcl-thread:join-thread thread))

(defun %thread-yield ()
  (torcl-thread:thread-yield))

(defun %all-threads ()
  (torcl-thread:all-threads))

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
  (torcl-thread:thread-alive-p thread))

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
