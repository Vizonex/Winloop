from cpython.contextvars cimport PyContext_CopyCurrent
from cpython.list cimport PyList_GET_SIZE, PyList_New, PyList_Clear

from types import coroutine


# Cythonic version of the asyncio Future Object meant for researching into ways to make
# A asynchronous awaitable container object behave correctly while making less costly calls.
# This has positive effects on libraries like uvloop & winloop.
# uvloop maintainers have my permission to try this - Vizonex.

cdef object _get_loop(fut):
    # Tries to call Future.get_loop() if it's available.
    # Otherwise fallbacks to using the old '_loop' property.
    if isinstance(fut, Future):
        return fut.get_loop()
    try:
        return fut.get_loop()
    except AttributeError:
        return fut._loop

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

cdef bint __future_is_done(object fut) except -1:
    if isinstance(Future, fut):
        return (<Future>fut).done()
    elif isfuture(fut):
        return fut.done()
    else:
        raise RuntimeError("Not a Future")


cdef class UVTaskWaker:
    cdef UVTask task

    def __call__(self, object fut):
        self.task.__wake()

    @staticmethod
    cdef UVTaskWaker new(UVTask task):
        cdef UVTaskWaker waker = UVTaskWaker.__new__(UVTaskWaker)
        waker.task = task
        return waker


# suspends idle-handle and waits for something to wake it back up afterwards
cdef object __add_future_done_cb(UVTask task, object fut):
    if isinstance(fut, Future):
        (<Future>fut).add_done_callback(UVTaskWaker.new(task))
    else:
        fut.add_done_callback(UVTaskWaker.new(task))
    # suspend.
    task._idle_handle.stop()


cdef get_name(object coro):
    # Coroutines compiled with Cython sometimes don't have
    # proper __qualname__ or __name__.  While that is a bug
    # in Cython, asyncio shouldn't crash with an AttributeError
    # in its __repr__ functions.
    if hasattr(coro, '__qualname__') and coro.__qualname__:
        coro_name = coro.__qualname__
    elif hasattr(coro, '__name__') and coro.__name__:
        coro_name = coro.__name__
    else:
        # Stop masking Cython bugs, expose them in a friendly way.
        coro_name = f'<{type(coro).__name__} without __name__>'
    return f'{coro_name}()'



cdef _task_repr_info(UVTask task):
    cdef list info = []

    if task.cancelling() and not task.done():
        # replace status
        info.append('cancelling')

    info.append('name=%r' % task._name)

    info.append(f'coro=<{get_name(task._coro)}>')

    if task._fut_waiter is not None:
        info.append(f'wait_for={task._fut_waiter!r}')
    return info

cdef _task_get_stack(UVTask task, limit):
    cdef list frames = []
    if hasattr(task._coro, 'cr_frame'):
        # case 1: 'async def' coroutines
        f = task._coro.cr_frame
    elif hasattr(task._coro, 'gi_frame'):
        # case 2: legacy coroutines
        f = task._coro.gi_frame
    elif hasattr(task._coro, 'ag_frame'):
        # case 3: async generators
        f = task._coro.ag_frame
    else:
        # case 4: unknown objects
        f = None
    if f is not None:
        while f is not None:
            if limit is not None:
                if limit <= 0:
                    break
                limit -= 1
            frames.append(f)
            f = f.f_back
        frames.reverse()
    elif task._exc is not None:
        tb = task._exc.__traceback__
        while tb is not None:
            if limit is not None:
                if limit <= 0:
                    break
                limit -= 1
            frames.append(tb.tb_frame)
            tb = tb.tb_next
    return frames



# Nicknamed after libuv UVAsync & UVIdle as an unexposed companion for handling
# coroutine movement, it is considered faster than making a bunch of chained
# callbacks. loop.call_soon doesn't sound feasible (but awfully messy too).

cdef class UVTask:


    def __init__(
        self,
        object coro,
        Loop loop,
        object name=None,
        object context=None
    ) -> None:
        self._base = Future(loop=loop)
        self._log_destroy_pending = True
        if not aio_iscoroutine(coro):
            self._log_destroy_pending = False
            raise TypeError(f"a coroutine was expected, got {coro!r}")

        self._num_cancels_requested = 0
        self._must_cancel = False
        self._coro = coro
        if name is None:
            self._name = f'UVTask-{loop._uv_task_counter.next()}'
        else:
            self._name = str(name)

        # print("copying context")
        if context is None:
            self._context = Context_CopyCurrent()
        else:
            self._context = context

        self._loop = loop
        # print("preparing idle")
        self._idle_handle = UVIdle.new(
            loop,
            new_MethodHandle(loop, "task.__step", <method_t>self.__step, self._context, self))

        # print("starting idle")
        # held onto if we get a future that needs to be awaited.
        self._held_future = None
        self._exc = None
        aio__register_task(self)
        self._idle_handle.start()
        # print("idle ran")

    # TODO: __repr__


    def result(self):
        return self._base.result()

    def exception(self):
        return self._base.exception()

    def add_done_callback(self, fn, *, context=None):
        return self._base.add_done_callback(fn, context=context)

    cpdef Py_ssize_t remove_done_callback(self, fn):
        return self._base.remove_done_callback(fn)

    cdef object __cancel(self):
        self._idle_handle.stop()
        self._base.cancel()

    cdef object __set_result(self, object result):
        self._idle_handle.stop()
        self._base.set_result(result)

    cdef object __set_exception(self, object exc):
        self._idle_handle.stop()
        self._exc = exc
        self._base.set_exception(exc)

    # sections are split up to be less confusing than
    # asyncio.Task and it's C extension.
    cdef object __coro_send(self):
        return self._coro.send(None)

    cdef object __coro_throw(self, object exc):
        return self._coro.throw(exc)


    cdef object __wake(self):

        if self._held_future:
            try:
                self._held_future.result()
            except BaseException as e:
                # this may also be cancellation so bring it to us
                # for the next UV Callback.
                self._exc = e

            # reset held future
            self._held_future = None
        # restart with new system.
        self._idle_handle.start()

    cdef object __step(self):
        cdef object exc = self._exc

        if self._base.done():
            raise aio_InvalidStateError(
                f'_step(): already done: {self!r}, {exc!r}'
            )
        if self._must_cancel:
            if not isinstance(exc, aio_CancelledError):
                exc = self._base._make_cancelled_error()
            self._must_cancel = False

        aio__enter_task(self._loop, self)
        try:
            if exc is not None:
                result = self.__coro_throw(exc)
            else:
                result = self.__coro_send()
        except StopIteration as exc:
            if self._must_cancel:
                self._must_cancel = False
                self.__cancel()
            else:
                self.__set_result(exc.value)
        except aio_CancelledError as exc:
            self._base._cancelled_exc = exc
            self._exc = exc
            self.__cancel()

        except (KeyboardInterrupt, SystemExit) as exc:
            self.__set_exception(exc)
            raise

        except BaseException as exc:
            self.__set_exception(exc)
            return
        else:
            blocking = getattr(result, '_asyncio_future_blocking', None)
            if blocking is not None:
                # Yielded Future must come from Future.__iter__().
                if result.get_loop() != self._loop:
                    self._exc = RuntimeError(
                        f'Task {self!r} got Future '
                        f'{result!r} attached to a different loop')

                elif blocking:
                    if result is self:
                        self._exc = RuntimeError(
                            f'Task cannot await on itself: {self!r}')

                    else:
                        result._asyncio_future_blocking = False
                        __add_future_done_cb(self, result)

                        self._held_future = result
                        if self._must_cancel:
                            if self._held_future.cancel(
                                    msg=self._base._cancel_message):
                                self._must_cancel = False
                else:
                    self._exc = RuntimeError(
                        f'yield was used instead of yield from '
                        f'in task {self!r} with {result!r}')

            elif result is None:
                # Bare yield relinquishes control for one event loop iteration.
                # unlike asyncio just wait for the next idle cycle...
                return

            elif Inspect_IsGenerator(result):
                # Yielding a generator is just wrong.
                self._exc = RuntimeError(
                    f'yield was used instead of yield from for '
                    f'generator in task {self!r} with {result!r}')

            else:
                # Yielding something else is an error.
                self._exc = RuntimeError(f'Task got bad yield: {result!r}')

        finally:
            aio__leave_task(self._loop, self)


    cpdef bint done(self):
        return self._base.done()

    cpdef bint cancelled(self):
        return self._base.cancelled()

    cpdef object cancel(self, msg=None):
        """Request that this task cancel itself.

        This arranges for a CancelledError to be thrown into the
        wrapped coroutine on the next cycle through the event loop.
        The coroutine then has a chance to clean up or even deny
        the request using try/except/finally.

        Unlike Future.cancel, this does not guarantee that the
        task will be cancelled: the exception might be caught and
        acted upon, delaying cancellation of the task or preventing
        cancellation completely.  The task may also return a value or
        raise a different exception.

        Immediately after this method is called, Task.cancelled() will
        not return True (unless the task was already cancelled).  A
        task will be marked as cancelled when the wrapped coroutine
        terminates with a CancelledError exception (even if cancel()
        was not called).

        This also increases the task's count of cancellation requests.
        """
        self._base.__log_traceback = False
        if self.done():
            return False
        self._num_cancels_requested += 1
        # These two lines are controversial.  See discussion starting at
        # https://github.com/python/cpython/pull/31394#issuecomment-1053545331
        # Also remember that this is duplicated in _asynciomodule.c.
        # if self._num_cancels_requested > 1:
        #     return False
        if self._held_future is not None:
            if self._held_future.cancel(msg=msg):
                # Leave self._held_future; it may be a Task that
                # catches and ignores the cancellation so we may have
                # to cancel it again later.
                return True
        # It must be the case that self.__step is already scheduled.
        self._must_cancel = True
        self._cancel_message = msg
        return True

    cpdef Py_ssize_t cancelling(self):
        """Return the count of the task's cancellation requests.

        This count is incremented when .cancel() is called
        and may be decremented using .uncancel().
        """
        return self._num_cancels_requested

    cpdef Py_ssize_t uncancel(self):
        """Decrement the task's count of cancellation requests.

        This should be called by the party that called `cancel()` on the task
        beforehand.

        Returns the remaining number of cancellation requests.
        """
        if self._num_cancels_requested > 0:
            self._num_cancels_requested -= 1
        return self._num_cancels_requested

    def get_stack(self, *, limit=None):
        """Return the list of stack frames for this task's coroutine.

        If the coroutine is not done, this returns the stack where it is
        suspended.  If the coroutine has completed successfully or was
        cancelled, this returns an empty list.  If the coroutine was
        terminated by an exception, this returns the list of traceback
        frames.

        The frames are always ordered from oldest to newest.

        The optional limit gives the maximum number of frames to
        return; by default all available frames are returned.  Its
        meaning differs depending on whether a stack or a traceback is
        returned: the newest frames of a stack are returned, but the
        oldest frames of a traceback are returned.  (This matches the
        behavior of the traceback module.)

        For reasons beyond our control, only one stack frame is
        returned for a suspended coroutine.
        """
        return _task_get_stack(self, limit)

    # TODO:
    def print_stack(self, *, limit=None, file=None):
        raise NotImplementedError("UVTask.print_stack is not figured out yet.")

    def __await__(self):
        return __future_iter(self._base).__await__()

    def __iter__(self):
        yield from __future_iter(self._base)

    def set_result(self, object result):
        raise RuntimeError('Task does not support set_result operation')

    def set_exception(self, object exception):
        raise RuntimeError('Task does not support set_exception operation')

    property _exception:
        def __get__(self):
            return self._exc

    # XXX: Python itself begs for these items.
    property _future_waiter:
        def __get__(self):
            return self._held_future

    property _fut_waiter:
        def __get__(self):
            return self._held_future

    property _asyncio_future_blocking:
        def __get__(self):
            return self._base._asyncio_future_blocking

        def __set__(self, value):
            setattr(self._base, "_asyncio_future_blocking", value)

    property _source_traceback:
        def __get__(self):
            return self._base._source_traceback

    def __del__(self):

        if self._base.state == _PENDING and self._log_destroy_pending:
            context = {
                'task': self,
                'message': 'Task was destroyed but it is pending!',
            }
            if self._source_traceback:
                context['source_traceback'] = self._source_traceback
            self._loop.call_exception_handler(context)

        self._idle_handle._close()
