
cdef extern from "asyncio_types.h":
    """
/* part of src/winloop/includes/asyncio_types.pxd */
typedef enum fut_state FutureState;
"""
    ctypedef enum FutureState:
        STATE_PENDING = 0
        STATE_CANCELLED = 1
        STATE_FINISHED = 2

    ctypedef struct FutureObj:
        pass

    ctypedef struct TaskObj:
        pass

    ctypedef class _asyncio.Future [object FutureObj]:
        pass

    ctypedef class _asyncio.Task [object TaskObj]:
        pass
