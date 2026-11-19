
cdef enum fut_state:
    _PENDING = 0
    _CANCELLED = 1
    _FINISHED = 2

cdef class Future:
    cdef:
        object __weakref__
        fut_state state
        public object _result
        public object _exception
        public Loop _loop
        public object _source_traceback
        public object _cancel_message
        public object _cancelled_exc
        public object _exception_tb

        list __callbacks
        public bint _asyncio_future_blocking
        bint __log_traceback
        bint _init

    cdef object ensure_alive(self)
    cpdef Loop get_loop(self)
    cpdef object _make_cancelled_error(self)
    cpdef object cancel(self, object msg=*)
    cpdef object _schedule_callbacks(self)
    cpdef bint cancelled(self) noexcept
    cpdef bint done(self) noexcept
    cpdef object result(self)
    cpdef object exception(self)
    cpdef object set_result(self, object result)
    cpdef Py_ssize_t remove_done_callback(self, object fn) except -1
    cpdef object set_result(self, object result)
    cpdef object set_exception(self, object exception)


cdef class UVTask:
    cdef:
        # XXX: Using a base object instead of a subclass due to the nature
        # of cython doing unwanted things when moving coroutine frames.
        object __weakref__
        Future _base
        readonly object _coro
        object _context
        object _held_future
        object _exc
        str _name
        public Loop _loop
        UVIdle _idle_handle
        public bint _log_destroy_pending
        bint _must_cancel
        bint _suspended
        Py_ssize_t _num_cancels_requested


    cpdef Py_ssize_t remove_done_callback(self, fn)
    cdef object __cancel(self)
    cdef object __set_result(self, object result)
    cdef object __set_exception(self, object exc)
    cdef object __coro_send(self)
    cdef object __coro_throw(self, object exc)
    cdef object __wake(self)
    cdef object __step(self)
    cpdef bint done(self)
    cpdef bint cancelled(self)
    cpdef object cancel(self, msg=*)
    cpdef Py_ssize_t cancelling(self)
    cpdef Py_ssize_t uncancel(self)
