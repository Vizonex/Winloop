import asyncio as __asyncio
import sys as _sys
import threading as _threading
import typing as _typing
import warnings as _warnings

if _sys.version_info < (3, 14):
    from asyncio.events import BaseDefaultEventLoopPolicy as __BasePolicy
else:
    # Python Deprecates EventLoopPolicy in 3.14
    # SEE: https://github.com/python/cpython/issues/131148
    # We will watch closely to determine what else we will do for supporting 3.14 
    from asyncio.events import _AbstractEventLoopPolicy as __BasePolicy


# Winloop comment: next line commented out for now. Somehow winloop\includes
from ._version import __version__  # NOQA

# is not included in the Winloop wheel, affecting version 0.1.6 on PyPI.
# from . import includes as __includes  # NOQA
from .loop import Loop as __BaseLoop  # NOQA

__all__ = ("new_event_loop", "install", "EventLoopPolicy")


_T = _typing.TypeVar("_T")


class Loop(__BaseLoop, __asyncio.AbstractEventLoop):  # type: ignore[misc]
    pass


def new_event_loop() -> Loop:
    """Return a new event loop."""
    return Loop()


def install() -> None:
    """A helper function to install winloop policy.

    WARNING
    -------
    Deprecated on Python 3.12 and Throws RuntimeError on 3.16 or higher.

    SEE:
    -   https://github.com/MagicStack/uvloop/issues/637 
    -   https://github.com/Vizonex/Winloop/issues/74
    -   https://github.com/python/cpython/issues/131148
    """
    if _sys.version_info >= (3, 12):
        _warnings.warn(

            "winloop.install() is deprecated and discouraged in favor of winloop.run()"
            "starting with Python 3.12."
            " SEE: https://github.com/MagicStack/uvloop/issues/637 "
            " and https://github.com/Vizonex/Winloop/issues/74 " \
            " and https://github.com/python/cpython/issues/131148",
            DeprecationWarning,
            stacklevel=1,
        )
    # In Preparation for 3.16 
    elif _sys.version_info >= (3, 16):
        raise RuntimeError(
            "winloop.install() is broken on 3.16 or higher " \
            " SEE: https://github.com/MagicStack/uvloop/issues/637 "
            " and https://github.com/Vizonex/Winloop/issues/74 " \
            " and https://github.com/python/cpython/issues/131148")
    
    __asyncio.set_event_loop_policy(EventLoopPolicy())


if _typing.TYPE_CHECKING:

    def run(
        main: _typing.Coroutine[_typing.Any, _typing.Any, _T],
        *,
        loop_factory: _typing.Optional[_typing.Callable[[], Loop]] = new_event_loop,
        debug: _typing.Optional[bool] = None,
    ) -> _T:
        """The preferred way of running a coroutine with winloop."""
else:

    def run(main, *, loop_factory=new_event_loop, debug=None, **run_kwargs):
        """The preferred way of running a coroutine with winloop."""

        async def wrapper():
            # If `loop_factory` is provided we want it to return
            # either winloop.Loop or a subtype of it, assuming the user
            # is using `winloop.run()` intentionally.
            loop = __asyncio._get_running_loop()
            if not isinstance(loop, Loop):
                raise TypeError("winloop.run() uses a non-uvloop event loop")
            return await main

        vi = _sys.version_info[:2]

        if vi <= (3, 10):
            # Copied from python/cpython

            if __asyncio._get_running_loop() is not None:
                raise RuntimeError(
                    "asyncio.run() cannot be called from a running event loop"
                )

            if not __asyncio.iscoroutine(main):
                raise ValueError("a coroutine was expected, got {!r}".format(main))

            loop = loop_factory()
            try:
                __asyncio.set_event_loop(loop)
                if debug is not None:
                    loop.set_debug(debug)
                return loop.run_until_complete(wrapper())
            finally:
                try:
                    _cancel_all_tasks(loop)
                    loop.run_until_complete(loop.shutdown_asyncgens())
                    if hasattr(loop, "shutdown_default_executor"):
                        loop.run_until_complete(loop.shutdown_default_executor())
                finally:
                    __asyncio.set_event_loop(None)
                    loop.close()

        elif vi == (3, 11):
            if __asyncio._get_running_loop() is not None:
                raise RuntimeError(
                    "asyncio.run() cannot be called from a running event loop"
                )

            with __asyncio.Runner(
                loop_factory=loop_factory, debug=debug, **run_kwargs
            ) as runner:
                return runner.run(wrapper())

        else:
            assert vi >= (3, 12)
            return __asyncio.run(
                wrapper(), loop_factory=loop_factory, debug=debug, **run_kwargs
            )


def _cancel_all_tasks(loop: __asyncio.AbstractEventLoop) -> None:
    # Copied from python/cpython

    to_cancel = __asyncio.all_tasks(loop)
    if not to_cancel:
        return

    for task in to_cancel:
        task.cancel()

    loop.run_until_complete(__asyncio.gather(*to_cancel, return_exceptions=True))

    for task in to_cancel:
        if task.cancelled():
            continue
        if task.exception() is not None:
            loop.call_exception_handler(
                {
                    "message": "unhandled exception during asyncio.run() shutdown",
                    "exception": task.exception(),
                    "task": task,
                }
            )


# WARNING on 3.14 or higher using EventLoop Policies are discouraged!
if _sys.version_info < (3, 16):
    class EventLoopPolicy(__BasePolicy):
        """Event loop policy.

        The preferred way to make your application use winloop:

        >>> import asyncio
        >>> import winloop
        >>> asyncio.set_event_loop_policy(winloop.EventLoopPolicy())
        >>> asyncio.get_event_loop()
        <winloop.Loop running=False closed=False debug=False>

        WARNING
        -------
        Using on 3.14 or Higher is Discouraged and `winloop.install()` will
        throw a `RuntimeError` if attempted. use `winloop.run(...)` or `winloop.new_event_loop(...)`
        instead.
        """

        # XXX: To bypass Problems of future Deprecation in 3.16 of different
        # Eventloop Policies moving it's code to here for right now makes sense...

        # Have fun trying to stop me because I put that code all right here :)
        # SEE: https://github.com/MagicStack/uvloop/issues/637

        if _sys.version_info > (3, 14):

            def __init__(self):
                _warnings.warn(
                    "Using EventLoopPolicy on 3.14+ is discouraged and is removed in 3.16 "
                    "and winloop.install() will throw a RuntimeError on 3.16+ if attempted "
                    "use winloop.new_event_loop or winloop.run() or winloop.Loop() instead "
                    "SEE: https://github.com/MagicStack/uvloop/issues/637",
                    PendingDeprecationWarning,
                    stacklevel=3,
                )
                super().__init__()

            _loop_factory = None

            class _Local(_threading.local):
                _loop = None
                _set_called = False

            def __init__(self):
                self._local = self._Local()

            def get_event_loop(self):
                """Get the event loop for the current context.

                Returns an instance of EventLoop or raises an exception.
                """
                if (
                    self._local._loop is None
                    and not self._local._set_called
                    and _threading.current_thread() is _threading.main_thread()
                ):
                    self.set_event_loop(self.new_event_loop())

                if self._local._loop is None:
                    raise RuntimeError(
                        "There is no current event loop in thread %r."
                        % _threading.current_thread().name
                    )

                return self._local._loop

            def set_event_loop(self, loop):
                """Set the event loop."""
                self._local._set_called = True
                assert loop is None or isinstance(loop, __BasePolicy)
                self._local._loop = loop

            def new_event_loop(self):
                """Create a new event loop.

                You must call set_event_loop() to make this the current event
                loop.
                """
                return self._loop_factory()

        def _loop_factory(self) -> Loop:
            return new_event_loop()

        if _typing.TYPE_CHECKING:
            # EventLoopPolicy doesn't implement these, but since they are marked
            # as abstract in typeshed, we have to put them in so mypy thinks
            # the base methods are overridden. This is the same approach taken
            # for the Windows event loop policy classes in typeshed.
            def get_child_watcher(self) -> _typing.NoReturn: ...

            def set_child_watcher(self, watcher: _typing.Any) -> _typing.NoReturn: ...
else:
    class EventLoopPolicy:
        """Event loop policy.

        The preferred way to make your application use winloop:

        >>> import asyncio
        >>> import winloop
        >>> asyncio.set_event_loop_policy(winloop.EventLoopPolicy())
        >>> asyncio.get_event_loop()
        <winloop.Loop running=False closed=False debug=False>

        WARNING
        -------
        Using on 3.14 or Higher is Discouraged and `winloop.install()` will
        throw a `RuntimeError` if attempted. use `winloop.run(...)` or `winloop.new_event_loop(...)`
        instead.
        """
        def __init__(self):
            raise RuntimeError(
                "3.16 removes EventLoopPolicies "
                "use winloop.new_event_loop or winloop.run() or winloop.Loop() instead "
                "SEE: https://github.com/MagicStack/uvloop/issues/637",
            )
