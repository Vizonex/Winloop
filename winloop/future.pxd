
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
