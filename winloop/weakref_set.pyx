# Fork of Python's WeakSet class but cythonized for extra speed.

from cpython.weakref cimport PyWeakref_NewRef, PyWeakref_GetRef
from cpython.object cimport PyObject
from cpython.set cimport PySet_Add, PySet_Clear, PySet_Discard, PySet_Pop

cdef extern from "Python.h":
    """
static inline PyObject* Weakref_NewRef(PyObject* obj){
    return PyWeakref_NewRef(obj, NULL);
}
#define weakref_steal(obj) obj
    """

    # Same as PyWeakref_NewRef but NULL is passed for callback.
    object Weakref_NewRef(object obj)
    object weakref_steal(PyObject* obj)
    WeakSet weakref_steal_as_weakset "weakref_steal"(PyObject* obj)



cdef class _IterationGuard:
    # This context manager registers itself in the current iterators of the
    # weak container, such as to delay all removals until the context manager
    # exits.
    # This technique should be relatively thread-safe (since sets are).

    cdef:
        object weakcontainer

    def __init__(self, object weakcontainer):
        # Don't create cycles
        self.weakcontainer = Weakref_NewRef(weakcontainer)

    def __enter__(self):
        cdef PyObject* w
        cdef WeakSet ws

        if PyWeakref_GetRef(self.weakcontainer, &w):
            ws = weakref_steal_as_weakset(w)
            PySet_Add(ws._iterating, self)
        return self

    def __exit__(self, *args):
        cdef set s
        cdef PyObject* wr
        cdef WeakSet ws
        if PyWeakref_GetRef(self.weakcontainer, &wr):
            ws = weakref_steal_as_weakset(wr)
            s = ws._iterating
            s.remove(self)
            if not s:
                ws._commit_removals()


cdef class RemovalSystem:

    def __cinit__(self, WeakSet this) -> None:
        self.this_ref = Weakref_NewRef(this)

    def __call__(self, object item, object selfref=None):
        cdef PyObject* w = NULL
        cdef WeakSet ws
        cdef object this_ref = selfref or self.this_ref

        if PyWeakref_GetRef(this_ref, &w):
            ws = weakref_steal_as_weakset(w)
            if ws._iterating:
                ws._pending_removals.append(item)
            else:
                ws.data.discard(item)




cdef class WeakSet:
    def __init__(self, object data = None):
        self.data = set()
        self._remove = RemovalSystem(self)
        # A list of keys to be removed
        self._pending_removals = []
        self._iterating = set()
        if data is not None:
            self.update(data)

    cpdef _commit_removals(self):
        pop = self._pending_removals.pop
        discard = self.data.discard
        while True:
            try:
                item = pop()
            except IndexError:
                return
            discard(item)

    def __iter__(self):
        cdef PyObject* w
        with _IterationGuard(self):
            for itemref in self.data:
                if PyWeakref_GetRef(itemref, &w):
                    # Caveat: the iterator will keep a strong reference to
                    # `item` until it is resumed or closed.
                    yield weakref_steal(w)

    def __len__(self):
        return len(self.data) - len(self._pending_removals)

    def __contains__(self, item):
        try:
            wr = Weakref_NewRef(item)
        except TypeError:
            return False
        return wr in self.data

    def __reduce__(self):
        return self.__class__, (list(self),), self.__getstate__()

    cpdef add(self, item):
        if self._pending_removals:
            self._commit_removals()
        PySet_Add(self.data, PyWeakref_NewRef(item, self._remove))

    cpdef clear(self):
        if self._pending_removals:
            self._commit_removals()
        PySet_Clear(self.data)

    cpdef WeakSet copy(self):
        return self.__class__(self)

    cpdef pop(self):
        cdef PyObject* ref
        if self._pending_removals:
            self._commit_removals()
        while True:
            try:
                itemref = PySet_Pop(self.data)
            except KeyError:
                raise KeyError('pop from empty WeakSet') from None
            if PyWeakref_GetRef(itemref, &ref):
                return weakref_steal(ref)

    cpdef remove(self, item):
        if self._pending_removals:
            self._commit_removals()
        self.data.remove(Weakref_NewRef(item))

    cpdef discard(self, item):
        if self._pending_removals:
            self._commit_removals()
        PySet_Discard(self.data, Weakref_NewRef(item))

    cpdef update(self, other):
        if self._pending_removals:
            self._commit_removals()
        for element in other:
            self.add(element)

    def __ior__(self, other):
        self.update(other)
        return self

    def difference(self, other):
        newset = self.copy()
        newset.difference_update(other)
        return newset

    def __sub__(self, other):
        newset = self.copy()
        newset.difference_update(other)
        return newset

    cpdef difference_update(self, other):
        self.__isub__(other)

    def __isub__(self, other):
        if self._pending_removals:
            self._commit_removals()
        if self is other:
            PySet_Clear(self.data)
        else:
            self.data.difference_update(Weakref_NewRef(item) for item in other)
        return self

    def intersection(self, other):
        return self.__class__(item for item in other if item in self)

    def __and__(self, other):
        return self.__class__(item for item in other if item in self)

    def intersection_update(self, other):
        self.__iand__(other)

    def __iand__(self, other):
        if self._pending_removals:
            self._commit_removals()
        self.data.intersection_update(Weakref_NewRef(item) for item in other)
        return self

    def issubset(self, other):
        return self.data.issubset(Weakref_NewRef(item) for item in other)


    def __richcmp__(self, other, op):
        if op == 0:  # <
            return self.data < {Weakref_NewRef(item) for item in other}

        if op == 1:  # <=
            return self.data.issubset(Weakref_NewRef(item) for item in other)

        if op == 2:  # ==
            if not isinstance(other, self.__class__):
                return NotImplemented
            return self.data == {Weakref_NewRef(item) for item in other}

        if op == 3:  # !=
            if not isinstance(other, self.__class__):
                return NotImplemented
            return self.data != {Weakref_NewRef(item) for item in other}

        if op == 4:  # >
            return self.data > {Weakref_NewRef(item) for item in other}

        if op == 5:  # >=
            return self.issuperset(other)

    def issuperset(self, other):
        return self.data.issuperset(Weakref_NewRef(item) for item in other)

    def symmetric_difference(self, other):
        newset = self.copy()
        newset.symmetric_difference_update(other)
        return newset

    def __xor__(self, other):
        newset = self.copy()
        newset.symmetric_difference_update(other)
        return newset

    def symmetric_difference_update(self, object other):
        if self._pending_removals:
            self._commit_removals()
        if self is other:
            PySet_Clear(self.data)
        else:
            self.data.symmetric_difference_update(PyWeakref_NewRef(item, self._remove) for item in other)

    def __ixor__(self, other):
        if self._pending_removals:
            self._commit_removals()
        if self is other:
            PySet_Clear(self.data)
        else:
            self.data.symmetric_difference_update(PyWeakref_NewRef(item, self._remove) for item in other)
        return self

    def union(self, other):
        return self.__class__(e for s in (self, other) for e in s)

    def __or__(self, other):
        return self.__class__(e for s in (self, other) for e in s)

    cpdef isdisjoint(self, other):
        return len(self.intersection(other)) == 0

    def __repr__(self):
        return repr(self.data)

    __class_getitem__ = classmethod(types_GenericAlias)

col_abc_MutableSet.register(WeakSet)
