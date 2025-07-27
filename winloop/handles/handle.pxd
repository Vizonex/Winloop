cimport cython 

# NOTE: Uvloop expects you to use no_gc_clear 
# Reason beind doing so has to do with the debug 
# RuntimeError which hints at this and makes it 
# very clear to use it.
# so please do not remove this wrapper, thank you :)
@cython.no_gc_clear
cdef class UVHandle:
    cdef:
        uv.uv_handle_t *_handle
        Loop _loop
        readonly _source_traceback
        bint _closed
        bint _inited
        object context

        # Added to enable current UDPTransport implementation,
        # which doesn't use libuv handles.
        bint _has_handle

    # All "inline" methods are final

    cdef inline int _start_init(self, Loop loop) except -1
    cdef inline int _abort_init(self) except -1
    cdef inline _finish_init(self)

    cdef inline bint _is_alive(self) except -1
    cdef inline int _ensure_alive(self) except -1

    cdef _error(self, exc, throw)
    # in CPython it returns NULL on exception raised 
    # so let's define that an object of NONE is returning.
    cdef object _fatal_error(self, exc, throw, reason=?)
    cdef _warn_unclosed(self)

    cdef void _free(self) noexcept
    # TODO: Optimize to return an integer if 
    # exception handling of CPython can be better learned.
    cdef _close(self)


@cython.no_gc_clear
cdef class UVSocketHandle(UVHandle):
    cdef:
        # Points to a Python file-object that should be closed
        # when the transport is closing.  Used by pipes.  This
        # should probably be refactored somehow.
        object _fileobj
        object __cached_socket

    # All "inline" methods are final

    cdef _fileno(self)

    cdef _new_socket(self)
    cdef inline _get_socket(self)
    cdef inline _attach_fileobj(self, object file)

    cdef _open(self, int sockfd)
