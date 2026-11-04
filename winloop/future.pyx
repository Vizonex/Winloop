from cpython.contextvars cimport PyContext_CopyCurrent
from cpython.list cimport PyList_GET_SIZE, PyList_New, PyList_Clear

from types import coroutine


# Cythonic version of the asyncio Future Object meant for researching into ways to make
# A asynchronous awaitable container object behave correctly while making less costly calls.
# This has positive effects on libraries like uvloop & winloop.
# uvloop maintainers have my permission to try this - Vizonex.


@coroutine
def __future_iter(Future fut):
    while fut.state == _PENDING:
        if not fut._asyncio_future_blocking:
            fut._asyncio_future_blocking = True
            yield fut
            continue
        raise RuntimeError("await wasn't used with future")
    result = fut.result()
    return result

cdef class Future:

    def __init__(self, *, Loop loop):
        self.state = _PENDING
        self._result = None
        self._exception = None
        self._source_traceback = None
        self._cancel_message = None
        self._cancelled_exc = None
        self.__log_traceback = False

        self.__callbacks = PyList_New(0)


        self._loop = loop
        if self._loop.get_debug():
            self._source_traceback = extract_stack()
        self._init = True

    @property
    def _state(self):
        # compatibility with python futures
        if self.state == _PENDING:
            return "PENDING"
        elif self.state == _CANCELLED:
            return "CANCELLED"
        return "FINISHED"


    @property
    def loop(self):
        return self._loop

    def __repr__(self):
        return aio__future_repr(self)

    def __del__(self):
        cdef dict context
        cdef object exc
        if not self.__log_traceback:
            # set_exception() was not called, or result() or exception()
            # has consumed the exception
            return
        exc = self._exception
        context = {
            'message':
                f'{self.__class__.__name__} exception was never retrieved',
            'exception': exc,
            'future': self,
        }
        if self._source_traceback:
            context['source_traceback'] = self._source_traceback
        self._loop.call_exception_handler(context)

    __class_getitem__ = classmethod(types_GenericAlias)

    @property
    def _log_traceback(self):
        self.ensure_alive()
        return self.__log_traceback

    @_log_traceback.setter
    def _log_traceback(self, val):
        if val:
            raise ValueError('_log_traceback can only be set to False')
        self.__log_traceback = False

    cdef object ensure_alive(self):
        if self._loop is None:
            raise RuntimeError("Future object is not initialized.")

    cpdef Loop get_loop(self):
        """Return the event loop the Future is bound to."""
        self.ensure_alive()
        return self._loop

    cpdef object _make_cancelled_error(self):
        """Create the CancelledError to raise if the Future is cancelled.

        This should only be called once when handling a cancellation since
        it erases the saved context exception value.
        """
        if self._cancelled_exc is not None:
            exc = self._cancelled_exc
            self._cancelled_exc = None
            return exc

        if self._cancel_message is None:
            exc = aio_CancelledError()
        else:
            exc = aio_CancelledError(self._cancel_message)
        exc.__context__ = self._cancelled_exc
        # Remove the reference since we don't need this anymore.
        self._cancelled_exc = None
        return exc

    cpdef object cancel(self, object msg=None):
        """Cancel the future and schedule callbacks.

        If the future is already done or cancelled, return False.  Otherwise,
        change the future's state to cancelled, schedule the callbacks and
        return True.
        """
        self.ensure_alive()
        self.__log_traceback = False
        if self.state != _PENDING:
            return False
        self.state = _CANCELLED
        self._cancel_message = msg
        self._schedule_callbacks()
        return True

    @property
    def _callbacks(self):
        self.ensure_alive()
        return self.__callbacks


    cpdef object _schedule_callbacks(self):
        """Internal: Ask the event loop to call all callbacks.

        The callbacks are scheduled to be called as soon as possible. Also
        clears the callback list.
        """

        if not PyList_GET_SIZE(self.__callbacks):
            return
        callbacks = self.__callbacks[:]
        PyList_Clear(self.__callbacks)
        for callback, ctx in callbacks:
            self._loop.call_soon(callback, self, context=ctx)

    cpdef bint cancelled(self) noexcept:
        """Return True if the future was cancelled."""
        return self.state == _CANCELLED

    # Don't implement running(); see http://bugs.python.org/issue18699

    cpdef bint done(self) noexcept:
        """Return True if the future is done.

        Done means either that a result / exception are available, or that the
        future was cancelled.
        """
        return self.state != _PENDING

    cpdef object result(self):
        """Return the result this future represents.

        If the future has been cancelled, raises CancelledError.  If the
        future's result isn't yet available, raises InvalidStateError.  If
        the future is done and has an exception set, this exception is raised.
        """
        if self.state == _CANCELLED:
            exc = self._make_cancelled_error()
            raise exc
        if self.state != _FINISHED:
            raise aio_InvalidStateError('Result is not ready.')
        self.__log_traceback = False
        if self._exception is not None:
            raise self._exception.with_traceback(self._exception_tb)
        return self._result

    cpdef object exception(self):
        """Return the exception that was set on this future.

        The exception (or None if no exception was set) is returned only if
        the future is done.  If the future has been cancelled, raises
        CancelledError.  If the future isn't done yet, raises
        InvalidStateError.
        """
        if self.state == _CANCELLED:
            exc = self._make_cancelled_error()
            raise exc
        if self.state != _FINISHED:
            raise aio_InvalidStateError('Exception is not set.')
        self.__log_traceback = False
        return self._exception

    # TODO: Remove context=None limitation
    def add_done_callback(self, fn, *, context=None):
        """Add a callback to be run when the future becomes done.

        The callback is called with a single argument - the future object. If
        the future is already done when this is called, the callback is
        scheduled with call_soon.
        """
        if self.state != _PENDING:
            self._loop._call_soon(fn, self, context=context)
        else:
            self.__callbacks.append((fn, PyContext_CopyCurrent() if context is None else context))

    # New method not in PEP 3148.

    cpdef Py_ssize_t remove_done_callback(self, object fn) except -1:
        """Remove all instances of a callback from the "call when done" list.

        Returns the number of callbacks removed.
        """
        self.ensure_alive()
        cdef Py_ssize_t removed_count
        cdef list filtered_callbacks = [(f, ctx)
                              for (f, ctx) in self.__callbacks
                              if f != fn]
        if removed_count := (PyList_GET_SIZE(self.__callbacks) - PyList_GET_SIZE(filtered_callbacks)):
            self.__callbacks[:] = filtered_callbacks
        return removed_count

    # So-called internal methods (note: no set_running_or_notify_cancel()).

    cpdef object set_result(self, object result):
        """Mark the future done and set its result.

        If the future is already done when this method is called, raises
        InvalidStateError.
        """
        self.ensure_alive()
        if self.state != _PENDING:
            raise aio_InvalidStateError(f'{self._state}: {self!r}')
        self._result = result
        self.state = _FINISHED
        self._schedule_callbacks()

    cpdef object set_exception(self, object exception):
        """Mark the future done and set an exception.

        If the future is already done when this method is called, raises
        InvalidStateError.
        """
        self.ensure_alive()
        if self.state != _PENDING:
            raise aio_InvalidStateError(f'{self._state}: {self!r}')
        if isinstance(exception, type):
            exception = exception()
        if type(exception) is StopIteration:
            raise TypeError("StopIteration interacts badly with generators "
                            "and cannot be raised into a Future")
        self._exception = exception
        self._exception_tb = (<BaseException>exception).__traceback__
        self.state = _FINISHED
        self._schedule_callbacks()
        self.__log_traceback = True

    def __await__(self):
        return __future_iter(self).__await__()

    def __iter__(self):
        return __future_iter(self)
