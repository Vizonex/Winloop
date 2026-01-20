cdef class UVRequest:
    cdef:
        uv.uv_req_t *request
        bint done
        Loop loop

    cdef on_done(self)
    cdef cancel(self)





# Based off concurrent.futures.thread._WorkItem and Future
# this is a backup alternative so that some resources from
# using a default executor are eliminated.
cdef class UVWork(UVRequest):
    cdef:
        object fut # asyncio.Future[...]
        object fn
        object args
        object result
        object exc

    cdef void run(self) noexcept with gil


   