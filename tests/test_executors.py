import asyncio
import concurrent.futures
import multiprocessing
import unittest
import time
from winloop import _testbase as tb


def fib(n):
    if n < 2:
        return 1
    return fib(n - 2) + fib(n - 1)


class _TestExecutors:
    def run_pool_test(self, pool_factory):
        async def run():
            pool = pool_factory()
            with pool:
                coros = []
                for i in range(0, 10):
                    coros.append(self.loop.run_in_executor(pool, fib, i))
                res = await asyncio.gather(*coros)
            self.assertEqual(res, fib10)
            await asyncio.sleep(0.01)

        fib10 = [fib(i) for i in range(10)]
        self.loop.run_until_complete(run())

    @unittest.skipIf(
        multiprocessing.get_start_method(False) == "spawn",
        "no need to test on Windows and macOS where spawn is used instead of fork",
    )
    def test_executors_process_pool_01(self):
        self.run_pool_test(concurrent.futures.ProcessPoolExecutor)

    def test_executors_process_pool_02(self):
        self.run_pool_test(concurrent.futures.ThreadPoolExecutor)

    

class TestUVExecutors(_TestExecutors, tb.UVTestCase):
    # Only libuv can feasabily do this.
    # this was implemented to help combat resource problems 

    def test_libuv_threadpool(self):
        self.loop.set_default_executor(None)
        async def run():
            coros = []
            for i in range(0, 10):
                coros.append(self.loop.run_in_executor(None, fib, i))
            res = await asyncio.gather(*coros)
            self.assertEqual(res, fib10)
            await asyncio.sleep(0.01)
        fib10 = [fib(i) for i in range(10)]
        self.loop.run_until_complete(run())

    def test_libuv_threadpool_exception(self):
        self.loop.set_default_executor(None)
        async def run():
            class TestException(Exception):
                pass

            def execption():
                raise TestException("Hello")
            
            with self.assertRaises(TestException):
                await self.loop.run_in_executor(None, execption)

        self.loop.run_until_complete(run())
    
    def test_libuv_threadpool_cancellation(self):
        self.loop.set_default_executor(None)

        async def run():
            
            def eternity():
                time(3600)
            
            fut = self.loop.run_in_executor(None, eternity)
            fut.cancel()
            with self.assertRaises(asyncio.CancelledError):
                await fut
        self.loop.run_until_complete(run())



class TestAIOExecutors(_TestExecutors, tb.AIOTestCase):
    pass
