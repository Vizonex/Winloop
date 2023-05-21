from __future__ import annotations
from asyncio import Task, Future, Handle, _get_running_loop, _register_task, iscoroutine, InvalidStateError
from asyncio.events import AbstractEventLoop 
from itertools import count
from typing import Coroutine, Awaitable, TypeVar, Optional, AnyStr
import inspect 
import contextvars

from socket import SO_BROADCAST


# Used for research and will be used to develop a new Task handler using WinLoop 
# This is written to primarly to help me solve how coroutines get invoked 
# by figureing out how objects are handled, I will be able to write the task object in cython...

R = TypeVar("R")
"""The result object"""

S = TypeVar("S")
"""A Sendable value"""

B = TypeVar("B")
"""Unknown because I don't know or understand it's purose yet..."""

concept_task_counter = count(0).__next__


class ReaserchTask(Future):
    """Used to see how we should go about planning out our own awaitable task..."""
    def __init__(self,coro:Coroutine[B , S, R], *, loop: Optional[AbstractEventLoop] = None, name:Optional[str] = None) -> None:
        super().__init__(loop=loop)
        self._coro = coro

        if not iscoroutine(self._coro):
            raise RuntimeError(f"{self._coro.__name__} is not a Coroutine")
        
        self._context = contextvars.Context()
        self._must_cancel = False
        self._fut_waiter = None
        self._name = f"ReaserchTask <{concept_task_counter()}>" if not name else name
        self._loop.call_soon(self.step, context=self._context)
        _register_task(self)

    @property
    def name(self):
        """The name of a task..."""
        return self._name

    #NOTE: Reaserch purposes ONLY!
    def step(self, exc:Optional[BaseException] = None):
        """Does what :function:`asyncio.Task.__step()` function does but only this time there is a little bit more typehinting to help us out...

        Parameters
        ----------

        exc: `Optional[BaseException]` \
            likely blongs to the execption to be thrown or raised \
            when something doesn't go right...
        """

        if self.done():
            raise InvalidStateError(f"step should not be called if coroutine is already done. The Task that caused this was {self.name}")
    
    

        
