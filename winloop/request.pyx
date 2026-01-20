cdef class UVRequest:
    """A base class for all libuv requests (uv_getaddrinfo_t, etc).

    Important: it's a responsibility of the subclass to call the
    "on_done" method in the request's callback.

    If "on_done" isn't called, the request object will never die.
    """

    def __cinit__(self, Loop loop, *_):
        self.request = NULL
        self.loop = loop
        self.done = 0
        Py_INCREF(self)

    cdef on_done(self):
        self.done = 1
        Py_DECREF(self)

    cdef cancel(self):
        # Most requests are implemented using a threadpool.  It's only
        # possible to cancel a request when it's still in a threadpool's
        # queue.  Once it's started to execute, we have to wait until
        # it finishes and calls its callback (and callback *must* call
        # UVRequest.on_done).

        cdef int err

        if self.done == 1:
            return

        if UVLOOP_DEBUG:
            if self.request is NULL:
                raise RuntimeError(
                    '{}.cancel: .request is NULL'.format(
                        self.__class__.__name__))

            if self.request.data is NULL:
                raise RuntimeError(
                    '{}.cancel: .request.data is NULL'.format(
                        self.__class__.__name__))

            if <UVRequest>self.request.data is not self:
                raise RuntimeError(
                    '{}.cancel: .request.data is not UVRequest'.format(
                        self.__class__.__name__))

        # We only can cancel pending requests.  Let's try.
        err = uv.uv_cancel(self.request)
        if err < 0:
            if err == uv.UV_EBUSY:
                # Can't close the request -- it's executing (see the first
                # comment).  Loop will have to wait until the callback
                # fires.
                pass
            elif err == uv.UV_EINVAL:
                # From libuv docs:
                #
                #     Only cancellation of uv_fs_t, uv_getaddrinfo_t,
                #     uv_getnameinfo_t and uv_work_t requests is currently
                #     supported.
                return
            else:
                ex = convert_error(err)
                self.loop._handle_exception(ex)


cdef class UVWork(UVRequest):
    cdef cancel(self):
        UVRequest.cancel(self)
        # if successful do the same on the future object's end.
        if not self.fut.cancelled():
            self.fut.cancel()
   
    cdef void run(self) noexcept with gil:
        cdef object result
        try:
            # if the eventloop fires the task but we cancelled previously
            # it's best to try exiting now instead of later...
            if self.fut.cancelled():
                return
            try:
                result = self.fn(*self.args)
            except BaseException as exc:
                self.exc = exc
            else:
                self.result = result
        except BaseException as ex:
            # if anything else fails. We don't have to be a sitting duck
            # and let it slide. we can handle it as soon as possible...
            self.exc = exc
        
    def __cinit__(self, Loop loop, object fut, object fn, object args):
        self.request = <uv.uv_req_t*>PyMem_RawMalloc(sizeof(uv.uv_work_t))
        if self.request == NULL:
            raise MemoryError

        self.loop = loop
        self.done = 0
        self.fn = fn
        self.args = args
        self.result = None
        self.exc = None
        self.fut = fut

        self.request.data = <void*>self

        # UV_EINVAL will never happen because our callback exists...
        uv.uv_queue_work(self.loop.uvloop, <uv.uv_work_t*>self.request, __on_work_cb, __on_after_work_cb)
        Py_INCREF(self)
 
    def __dealloc__(self):
        if self.request != NULL:
            PyMem_RawFree(self.request)
        


cdef void __on_work_cb(uv.uv_work_t* req) noexcept with gil:
    (<UVWork>req.data).run()

cdef void __on_after_work_cb(uv.uv_work_t* req, int err) noexcept with gil:
    cdef object ex
    cdef UVWork work = (<UVWork>req.data)
    try:
        if err == uv.UV_ECANCELED:
            if not work.fut.cancelled():
                work.fut.cancel()

        elif err != 0:
            ex = convert_error(err)
            work.fut.set_exception(ex)

        if work.exc is not None:
            work.fut.set_exception(work.exc)
        else:
            work.fut.set_result(work.result)
    except BaseException as e:
        work.loop._handle_exception(e)
    finally:
        work.on_done()



