# mostly needed as a speedup for winloop's internal loop
# which contains unneeded & costly interpreter logic

# The only downside is that this WeakSet doesn't fully support
# copying but it's a worth-it tradeoff.

cdef class RemovalSystem:
    cdef:
        object this_ref

cdef class WeakSet:
    cdef:
        object __weakref__
        public set data
        set _iterating
        list _pending_removals
        RemovalSystem _remove

    cpdef _commit_removals(self)
    cpdef add(self, item)
    cpdef clear(self)
    cpdef WeakSet copy(self)
    cpdef pop(self)
    cpdef remove(self, item)
    cpdef discard(self, item)
    cpdef update(self, other)
    cpdef difference_update(self, other)
    cpdef isdisjoint(self, other)
