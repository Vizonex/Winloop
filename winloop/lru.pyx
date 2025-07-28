from cpython.object cimport PyObject as PyObject


cdef extern from "Python.h":
    """
// Screw the compiler I'm hacking it in...
typedef struct _odictnode _ODictNode;

struct _odictobject {
    PyDictObject od_dict;        /* the underlying dict */
    _ODictNode *od_first;        /* first node in the linked list, if any */
    _ODictNode *od_last;         /* last node in the linked list, if any */
    /* od_fast_nodes, od_fast_nodes_size and od_resize_sentinel are managed
     * by _odict_resize().
     * Note that we rely on implementation details of dict for both. */
    _ODictNode **od_fast_nodes;  /* hash table that mirrors the dict table */
    Py_ssize_t od_fast_nodes_size;
    void *od_resize_sentinel;    /* changes if odict should be resized */

    size_t od_state;             /* incremented whenever the LL changes */
    PyObject *od_inst_dict;      /* OrderedDict().__dict__ */
    PyObject *od_weakreflist;    /* holds weakrefs to the odict */
};



struct _odictnode {
    PyObject *key;
    Py_hash_t hash;
    _ODictNode *next;
    _ODictNode *prev;
};

// Incase Removed in the future I'll hack in the Full header file as well.

#ifndef Py_ODICTOBJECT_H
#define Py_ODICTOBJECT_H
#ifdef __cplusplus
extern "C" {
#endif


/* OrderedDict */
/* This API is optional and mostly redundant. */

#ifndef Py_LIMITED_API

typedef struct _odictobject PyODictObject;

PyAPI_DATA(PyTypeObject) PyODict_Type;
PyAPI_DATA(PyTypeObject) PyODictIter_Type;
PyAPI_DATA(PyTypeObject) PyODictKeys_Type;
PyAPI_DATA(PyTypeObject) PyODictItems_Type;
PyAPI_DATA(PyTypeObject) PyODictValues_Type;

#define PyODict_Check(op) PyObject_TypeCheck(op, &PyODict_Type)
#define PyODict_CheckExact(op) Py_IS_TYPE(op, &PyODict_Type)
#define PyODict_SIZE(op) PyDict_GET_SIZE((op))

PyAPI_FUNC(PyObject *) PyODict_New(void);
PyAPI_FUNC(int) PyODict_SetItem(PyObject *od, PyObject *key, PyObject *item);
PyAPI_FUNC(int) PyODict_DelItem(PyObject *od, PyObject *key);

/* wrappers around PyDict* functions */
#define PyODict_GetItem(od, key) PyDict_GetItem(_PyObject_CAST(od), key)
#define PyODict_GetItemWithError(od, key) \
    PyDict_GetItemWithError(_PyObject_CAST(od), key)
#define PyODict_Contains(od, key) PyDict_Contains(_PyObject_CAST(od), key)
#define PyODict_Size(od) PyDict_Size(_PyObject_CAST(od))
#define PyODict_GetItemString(od, key) \
    PyDict_GetItemString(_PyObject_CAST(od), key)

#endif

#ifdef __cplusplus
}
#endif
#endif /* !Py_ODICTOBJECT_H */
    """
    # Sad how ODict never really caught anybody's attention 
    # but it's OrderedDict Under the hood...

    ctypedef struct PyODictObject:
        pass
    
    ctypedef class _collections.OrderedDict [object PyODictObject, check_size ignore]:
        pass

    # OrderedDict cannot be defined in any of it's C Methods due to GCC 
    # SEE: https://github.com/Vizonex/Winloop/issues/64

    bint PyODict_Check(object op)
    bint PyODict_CheckExact(object op)
    Py_ssize_t PyODict_SIZE(object op)
    int PyODict_Contains(object op, object key) except -1
    OrderedDict PyODict_New()
    
    int PyODict_SetItem(object od, object key, object item) except -1
    int PyODict_DelItem(object od, object key) except -1
    PyObject* PyODict_GetItem(object od, object key)
    object PyODict_GetItemWithError(object od, object key)


@cython.final
cdef class LruCache:

    cdef:
        OrderedDict _dict
        Py_ssize_t _maxsize
        object _dict_move_to_end

    # We use an OrderedDict for LRU implementation.  Operations:
    #
    # * We use a simple `__setitem__` to push a new entry:
    #       `entries[key] = new_entry`
    #   That will push `new_entry` to the *end* of the entries dict.
    #
    # * When we have a cache hit, we call
    #       `entries.move_to_end(key, last=True)`
    #   to move the entry to the *end* of the entries dict.
    #
    # * When we need to remove entries to maintain `max_size`, we call
    #       `entries.popitem(last=False)`
    #   to remove an entry from the *beginning* of the entries dict.
    #
    # So new entries and hits are always promoted to the end of the
    # entries dict, whereas the unused one will group in the
    # beginning of it.

    def __init__(self, *, Py_ssize_t maxsize):
        if maxsize <= 0:
            raise ValueError(
                f'maxsize is expected to be greater than 0, got {maxsize}')

        self._dict = PyODict_New()
        self._dict_move_to_end = getattr(self._dict, "move_to_end") 
        self._maxsize = maxsize

    cdef get(self, object key, object default):
        cdef PyObject* _o
        cdef object o
        _o = PyODict_GetItem(self._dict, key)
        if _o == NULL:
            return default
        o = <object>_o
        Py_INCREF(o)
        self._dict_move_to_end(key)  # last=True
        return o

    cdef inline bint needs_cleanup(self):
        return PyODict_SIZE(self._dict) > self._maxsize

    cdef inline cleanup_one(self):
        k, _ = self._dict.popitem(last=False)
        return k

    def __getitem__(self, key):
        o = self._dict[key]
        self._dict_move_to_end(key)  # last=True
        return o

    def __setitem__(self, key, o):
        if key in self._dict:
            PyODict_SetItem(self._dict, key, o)
            self._dict_move_to_end(key)  # last=True
        else:
            PyODict_SetItem(self._dict, key, o)
        while self.needs_cleanup():
            self.cleanup_one()

    def __delitem__(self, key):
        PyODict_DelItem(self._dict, key)

    def __contains__(self, key):
        return PyODict_Contains(self._dict, key)

    def __len__(self):
        return PyODict_SIZE(self._dict)

    def __iter__(self):
        return iter(self._dict)
