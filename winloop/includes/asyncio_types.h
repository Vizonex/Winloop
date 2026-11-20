
#ifndef ___ASYNCIO_TYPES_H__
#define ___ASYNCIO_TYPES_H__

/* Newest Supported Python Version: 3.16 */

#ifdef __cplusplus
extern "C" {
#endif

#include <Python.h>

#define CPYTHON_ASYNCIO_MINIMAL_SUPPORTED_VERSION 9
#define CPYTHON_ASYNCIO_NEWEST_SUPPORTED_VERSION 16


#if (PY_MAJOR_VERSION == 3 && PY_MINOR_VERSION == 9)
    #define CPYTHON_ASYNCIO_39
#endif

#ifdef CPYTHON_ASYNCIO_39

/* enums */
typedef enum fut_state {
    STATE_PENDING = 0,
    STATE_CANCELLED = 1,
    STATE_FINISHED = 2,
} fut_state;

/* structs */
typedef struct FutureObj {
    PyObject_HEAD
    PyObject* fut_loop;
    PyObject* fut_callback0;
    PyObject* fut_callbacks;
    PyObject* fut_exception;
    PyObject* fut_result;
    PyObject* fut_source_tb;
    PyObject* fut_cancel_msg;
    fut_state fut_state;
    int fut_log_tb;
    int fut_log_blocking;
    PyObject* dict;
    PyObject* fut_weakreflist;
    _PyErr_StackItem fut_cancelled_exc_state;
} FutureObj;

typedef struct TaskObj {
    PyObject_HEAD
    PyObject* task_loop;
    PyObject* task_callback0;
    PyObject* task_callbacks;
    PyObject* task_exception;
    PyObject* task_result;
    PyObject* task_source_tb;
    PyObject* task_cancel_msg;
    fut_state task_state;
    int task_log_tb;
    int task_log_blocking;
    PyObject* dict;
    PyObject* task_weakreflist;
    _PyErr_StackItem task_cancelled_exc_state;
    PyObject *task_fut_waiter;
    PyObject *task_coro;
    PyObject *task_name;
    PyObject *task_context;
    int task_must_cancel;
    int task_log_destroy_pending;
} TaskObj;

#endif /* 3.9 */

#if (PY_MAJOR_VERSION == 3 && PY_MINOR_VERSION == 10)
    #define CPYTHON_ASYNCIO_310
#endif

#ifdef CPYTHON_ASYNCIO_310

/* enums */
typedef enum fut_state {
    STATE_PENDING = 0,
    STATE_CANCELLED = 1,
    STATE_FINISHED = 2,
} fut_state;

/* structs */
typedef struct FutureObj {
    PyObject_HEAD
    PyObject* fut_loop;
    PyObject* fut_callback0;
    PyObject* fut_callbacks;
    PyObject* fut_exception;
    PyObject* fut_exception_tb;
    PyObject* fut_result;
    PyObject* fut_source_tb;
    PyObject* fut_cancel_msg;
    fut_state fut_state;
    int fut_log_tb;
    int fut_log_blocking;
    PyObject* dict;
    PyObject* fut_weakreflist;
    _PyErr_StackItem fut_cancelled_exc_state;
} FutureObj;

typedef struct TaskObj {
    PyObject_HEAD
    PyObject* task_loop;
    PyObject* task_callback0;
    PyObject* task_callbacks;
    PyObject* task_exception;
    PyObject* task_exception_tb;
    PyObject* task_result;
    PyObject* task_source_tb;
    PyObject* task_cancel_msg;
    fut_state task_state;
    int task_log_tb;
    int task_log_blocking;
    PyObject* dict;
    PyObject* task_weakreflist;
    _PyErr_StackItem task_cancelled_exc_state;
    PyObject *task_fut_waiter;
    PyObject *task_coro;
    PyObject *task_name;
    PyObject *task_context;
    int task_must_cancel;
    int task_log_destroy_pending;
} TaskObj;

#endif /* 3.10 */

#if (PY_MAJOR_VERSION == 3 && PY_MINOR_VERSION == 11)
    #define CPYTHON_ASYNCIO_311
#endif

#ifdef CPYTHON_ASYNCIO_311

/* enums */
typedef enum fut_state {
    STATE_PENDING = 0,
    STATE_CANCELLED = 1,
    STATE_FINISHED = 2,
} fut_state;

/* structs */
typedef struct FutureObj {
    PyObject_HEAD
    PyObject* fut_loop;
    PyObject* fut_callback0;
    PyObject* fut_context0;
    PyObject* fut_callbacks;
    PyObject* fut_exception;
    PyObject* fut_exception_tb;
    PyObject* fut_result;
    PyObject* fut_source_tb;
    PyObject* fut_cancel_msg;
    fut_state fut_state;
    int fut_log_tb;
    int fut_blocking;
    PyObject* dict;
    PyObject* fut_weakreflist;
    PyObject* fut_cancelled_exc;
} FutureObj;

typedef struct TaskObj {
    PyObject_HEAD
    PyObject* task_loop;
    PyObject* task_callback0;
    PyObject* task_context0;
    PyObject* task_callbacks;
    PyObject* task_exception;
    PyObject* task_exception_tb;
    PyObject* task_result;
    PyObject* task_source_tb;
    PyObject* task_cancel_msg;
    fut_state task_state;
    int task_log_tb;
    int task_blocking;
    PyObject* dict;
    PyObject* task_weakreflist;
    PyObject* task_cancelled_exc;
    PyObject *task_fut_waiter;
    PyObject *task_coro;
    PyObject *task_name;
    PyObject *task_context;
    int task_must_cancel;
    int task_log_destroy_pending;
    int task_num_cancels_requested;
} TaskObj;

#endif /* 3.11 */

#if (PY_MAJOR_VERSION == 3 && PY_MINOR_VERSION == 12)
    #define CPYTHON_ASYNCIO_312
#endif

#ifdef CPYTHON_ASYNCIO_312

/* enums */
typedef enum fut_state {
    STATE_PENDING = 0,
    STATE_CANCELLED = 1,
    STATE_FINISHED = 2,
} fut_state;

/* structs */
typedef struct FutureObj {
    PyObject_HEAD
    PyObject* fut_loop;
    PyObject* fut_callback0;
    PyObject* fut_context0;
    PyObject* fut_callbacks;
    PyObject* fut_exception;
    PyObject* fut_exception_tb;
    PyObject* fut_result;
    PyObject* fut_source_tb;
    PyObject* fut_cancel_msg;
    fut_state fut_state;
    int fut_log_tb;
    int fut_blocking;
    PyObject* dict;
    PyObject* fut_weakreflist;
    PyObject* fut_cancelled_exc;
} FutureObj;

typedef struct {
    PyObject_HEAD
    PyObject *task_loop;
    PyObject *task_callback0;
    PyObject *task_context0;
    PyObject *task_callbacks;
    PyObject *task_exception;
    PyObject *task_exception_tb;
    PyObject *task_result;
    PyObject *task_source_tb;
    PyObject *task_cancel_msg;
    fut_state task_state;
    int task_log_tb;
    int task_blocking;
    PyObject *dict;
    PyObject *task_weakreflist;
    PyObject *task_cancelled_exc;
    PyObject *task_fut_waiter;
    PyObject *task_coro;
    PyObject *task_name;
    PyObject *task_context;
    int task_must_cancel;
    int task_log_destroy_pending;
    int task_num_cancels_requested;
} TaskObj;

#endif /* 3.12 */

#if (PY_MAJOR_VERSION == 3 && PY_MINOR_VERSION == 13)
    #define CPYTHON_ASYNCIO_313
#endif

#ifdef CPYTHON_ASYNCIO_313

/* enums */
typedef enum fut_state {
    STATE_PENDING = 0,
    STATE_CANCELLED = 1,
    STATE_FINISHED = 2,
} fut_state;

/* structs */
typedef struct FutureObj {
    PyObject_HEAD
    PyObject* fut_loop;
    PyObject* fut_callback0;
    PyObject* fut_context0;
    PyObject* fut_callbacks;
    PyObject* fut_exception;
    PyObject* fut_exception_tb;
    PyObject* fut_result;
    PyObject* fut_source_tb;
    PyObject* fut_cancel_msg;
    PyObject* fut_cancelled_exc;
    fut_state fut_state;
    unsigned fut_log_tb: 1;
    unsigned fut_blocking: 1;
} FutureObj;

typedef struct TaskObj {
    PyObject_HEAD
    PyObject *task_loop;
    PyObject *task_callback0;
    PyObject *task_context0;
    PyObject *task_callbacks;
    PyObject *task_exception;
    PyObject *task_exception_tb;
    PyObject *task_result;
    PyObject *task_source_tb;
    PyObject *task_cancel_msg;
    PyObject *task_cancelled_exc;
    fut_state task_state;
    unsigned task_log_tb: 1;
    unsigned task_blocking: 1;
    unsigned task_must_cancel: 1;
    unsigned task_log_destroy_pending: 1;
    int task_num_cancels_requested;
    PyObject *task_fut_waiter;
    PyObject *task_coro;
    PyObject *task_name;
    PyObject *task_context;
} TaskObj;

#endif /* 3.13 */

#if (PY_MAJOR_VERSION == 3 && PY_MINOR_VERSION == 14)
    #define CPYTHON_ASYNCIO_314
#endif

#ifdef CPYTHON_ASYNCIO_314

#include <stdint.h>

/* enums */
typedef enum fut_state {
    STATE_PENDING = 0,
    STATE_CANCELLED = 1,
    STATE_FINISHED = 2,
} fut_state;

/* structs */

struct llist_node {
    struct llist_node *next;
    struct llist_node *prev;
};

typedef struct FutureObj {
    PyObject_HEAD
    PyObject* fut_loop;
    PyObject* fut_callback0;
    PyObject* fut_context0;
    PyObject* fut_callbacks;
    PyObject* fut_exception;
    PyObject* fut_exception_tb;
    PyObject* fut_result;
    PyObject* fut_source_tb;
    PyObject* fut_cancel_msg;
    PyObject* fut_cancelled_exc;
    PyObject* fut_awaited_by;
    fut_state fut_state;
    char fut_is_task;
    char fut_awaited_by_is_set;
    unsigned fut_log_tb: 1;
    unsigned fut_blocking: 1;
} FutureObj;

typedef struct TaskObj {
    PyObject_HEAD
    PyObject *task_loop;
    PyObject *task_callback0;
    PyObject *task_context0;
    PyObject *task_callbacks;
    PyObject *task_exception;
    PyObject *task_exception_tb;
    PyObject *task_result;
    PyObject *task_source_tb;
    PyObject *task_cancel_msg;
    PyObject *task_cancelled_exc;
    PyObject *task_awaited_by;
    fut_state task_state;
    char task_is_task;
    unsigned task_must_cancel: 1;
    unsigned task_log_destroy_pending: 1;
    int task_num_cancels_requested;
    PyObject *task_fut_waiter;
    PyObject *task_coro;
    PyObject *task_name;
    PyObject *task_context;
    struct llist_node task_node;
#ifdef Py_GIL_DISABLED
    uint64_t task_tstate_id;
#endif
} TaskObj;

#endif /* 3.14 */

#if (PY_MAJOR_VERSION == 3 && PY_MINOR_VERSION == 15)
    #define CPYTHON_ASYNCIO_315
#endif

#ifdef CPYTHON_ASYNCIO_315

#include <stdint.h>

/* enums */
typedef enum fut_state {
    STATE_PENDING = 0,
    STATE_CANCELLED = 1,
    STATE_FINISHED = 2,
} fut_state;

/* structs */
struct llist_node {
    struct llist_node *next;
    struct llist_node *prev;
};

typedef struct FutureObj {
    PyObject_HEAD
    PyObject* fut_loop;
    PyObject* fut_callback0;
    PyObject* fut_context0;
    PyObject* fut_callbacks;
    PyObject* fut_exception;
    PyObject* fut_exception_tb;
    PyObject* fut_result;
    PyObject* fut_source_tb;
    PyObject* fut_cancel_msg;
    PyObject* fut_cancelled_exc;
    PyObject* fut_awaited_by;
    fut_state fut_state;
    char fut_is_task;
    char fut_awaited_by_is_set;
    unsigned fut_log_tb: 1;
    unsigned fut_blocking: 1;
} FutureObj;

typedef struct TaskObj {
    PyObject_HEAD
    PyObject *task_loop;
    PyObject *task_callback0;
    PyObject *task_context0;
    PyObject *task_callbacks;
    PyObject *task_exception;
    PyObject *task_exception_tb;
    PyObject *task_result;
    PyObject *task_source_tb;
    PyObject *task_cancel_msg;
    PyObject *task_cancelled_exc;
    PyObject *task_awaited_by;
    fut_state task_state;
    char task_is_task;
    char task_awaited_by_is_set;
    unsigned task_log_tb: 1;
    unsigned task_blocking: 1;
    unsigned task_must_cancel: 1;
    unsigned task_log_destroy_pending: 1;
    int task_num_cancels_requested;
    PyObject *task_fut_waiter;
    PyObject *task_coro;
    PyObject *task_name;
    PyObject *task_context;
    struct llist_node task_node;
#ifdef Py_GIL_DISABLED
    uint64_t task_tstate_id;
#endif
} TaskObj;

#endif /* 3.15 */

#if (PY_MAJOR_VERSION == 3 && PY_MINOR_VERSION == 16)
    #define CPYTHON_ASYNCIO_316
#endif

#ifdef CPYTHON_ASYNCIO_316

#include <stdint.h>

/* enums */
typedef enum fut_state {
    STATE_PENDING = 0,
    STATE_CANCELLED = 1,
    STATE_FINISHED = 2,
} fut_state;

/* structs */
struct llist_node {
    struct llist_node *next;
    struct llist_node *prev;
};

typedef struct FutureObj {
    PyObject_HEAD
    PyObject* fut_loop;
    PyObject* fut_callback0;
    PyObject* fut_context0;
    PyObject* fut_callbacks;
    PyObject* fut_exception;
    PyObject* fut_exception_tb;
    PyObject* fut_result;
    PyObject* fut_source_tb;
    PyObject* fut_cancel_msg;
    PyObject* fut_cancelled_exc;
    PyObject* fut_awaited_by;
    fut_state fut_state;
    char fut_is_task;
    char fut_awaited_by_is_set;
    unsigned fut_log_tb: 1;
    unsigned fut_blocking: 1;
} FutureObj;

typedef struct TaskObj {
    PyObject_HEAD
    PyObject *task_loop;
    PyObject *task_callback0;
    PyObject *task_context0;
    PyObject *task_callbacks;
    PyObject *task_exception;
    PyObject *task_exception_tb;
    PyObject *task_result;
    PyObject *task_source_tb;
    PyObject *task_cancel_msg;
    PyObject *task_cancelled_exc;
    PyObject *task_awaited_by;
    fut_state task_state;
    char task_is_task;
    char task_awaited_by_is_set;
    unsigned task_log_tb: 1;
    unsigned task_blocking: 1;
    unsigned task_must_cancel: 1;
    unsigned task_log_destroy_pending: 1;
    int task_num_cancels_requested;
    PyObject *task_fut_waiter;
    PyObject *task_coro;
    PyObject *task_name;
    PyObject *task_context;
    struct llist_node task_node;
#ifdef Py_GIL_DISABLED
    // unique id of the thread state where the task was registered
    uint64_t task_tstate_id;
#endif
} TaskObj;

#endif /* 3.16 */


#if(PY_MAJOR_VERSION == 3 && PY_MINOR_VERSION < CPYTHON_ASYNCIO_MINIMAL_SUPPORTED_VERSION)
    #error "your version of python is not supported please upgrade to 3.9 or higher"
#endif

#if(PY_MAJOR_VERSION == 3 && PY_MINOR_VERSION > CPYTHON_ASYNCIO_NEWEST_SUPPORTED_VERSION)
    #error "your version of python is not supported at the moment please throw an issue"
#endif

#ifdef __cplusplus
}
#endif /* __cplusplus */
#endif /* ___ASYNCIO_TYPES_H__ */
