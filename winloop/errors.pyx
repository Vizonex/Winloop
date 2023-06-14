# cython:langauge_level = 3
from libc.string cimport strerror 
# from includes._stdlib cimport *
from .includes cimport uv , system

cdef str __strerr(int errno):
    return strerror(errno).decode()

cdef __convert_python_error(int uverr):
    # XXX Won't work for Windows: 
    # From libuv docs:
    #      Implementation detail: on Unix error codes are the
    #      negated errno (or -errno), while on Windows they
    #      are defined by libuv to arbitrary negative numbers.

    # NOTE (Vizonex): I DEBUNKED IT. IT CAN! As long as we can find it's actual Diagnosis...
    # by substituting the 'UV_E' macros to Just 'E' we can then find the errors we need and 
    # then diagnose them... 

    # TODO VERIFY THAT THE ERRORS ARE CORRECTLY MAPPED!!!

    cdef int oserr = -uverr

    exc = OSError

    if uverr in (uv.EACCES, uv.EPERM):
        exc = PermissionError

    elif uverr in (uv.EAGAIN, uv.EALREADY):
        exc = BlockingIOError

    elif uverr in (uv.EPIPE, uv.UV__ESHUTDOWN):
        exc = BrokenPipeError

    elif uverr == uv.ECONNABORTED:
        exc = ConnectionAbortedError

    elif uverr == uv.ECONNREFUSED:
        exc = ConnectionRefusedError

    elif uverr == uv.ECONNRESET:
        exc = ConnectionResetError

    elif uverr == uv.EEXIST:
        exc = FileExistsError

    elif uverr in (uv.ENOENT, uv.UV__ENOENT):
        exc = FileNotFoundError

    elif uverr == uv.EINTR:
        exc = InterruptedError

    elif uverr == uv.EISDIR:
        exc = IsADirectoryError

    elif uverr == uv.ESRCH:
        exc = ProcessLookupError

    elif uverr == uv.ETIMEDOUT:
        exc = TimeoutError

    return exc(oserr, __strerr(oserr))


cdef int __convert_socket_error(int uverr) noexcept:
    cdef int sock_err = 0

    if uverr == uv.UV__EAI_ADDRFAMILY:
        sock_err = socket_EAI_ADDRFAMILY

    elif uverr == uv.EAI_AGAIN:
        sock_err = socket_EAI_AGAIN

    elif uverr == uv.EAI_BADFLAGS:
        sock_err = socket_EAI_BADFLAGS

    elif uverr == uv.UV__EAI_BADHINTS:
        sock_err = socket_EAI_BADHINTS

    elif uverr == uv.UV__EAI_CANCELED:
        sock_err = socket_EAI_CANCELED

    elif uverr == uv.EAI_FAIL:
        sock_err = socket_EAI_FAIL

    elif uverr == uv.EAI_FAMILY:
        sock_err = socket_EAI_FAMILY

    elif uverr == uv.EAI_MEMORY:
        sock_err = socket_EAI_MEMORY

    elif uverr == uv.EAI_NODATA:
        sock_err = socket_EAI_NODATA

    elif uverr == uv.EAI_NONAME:
        sock_err = socket_EAI_NONAME

    elif uverr == uv.UV__EAI_OVERFLOW:
        sock_err = socket_EAI_OVERFLOW

    elif uverr == uv.UV__EAI_PROTOCOL:
        sock_err = socket_EAI_PROTOCOL

    elif uverr == uv.EAI_SERVICE:
        sock_err = socket_EAI_SERVICE

    elif uverr == uv.EAI_SOCKTYPE:
        sock_err = socket_EAI_SOCKTYPE

    return sock_err


cdef convert_error(int uverr):
    cdef int sock_err

    if uverr == uv.ECANCELED:
        return aio_CancelledError()

    sock_err = __convert_socket_error(uverr)
    if sock_err:
        msg = system.gai_strerror(sock_err).decode('utf-8')
        return socket_gaierror(sock_err, msg)

    return __convert_python_error(uverr)
