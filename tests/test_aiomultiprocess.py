try:
    import aiomultiprocess, multiprocessing
except ImportError:
    skip_tests = True
else:
    skip_tests = False
import unittest
import winloop
import random
import asyncio
import os
from winloop import _testbase as tb


async def test_func(sleep: float):
    return await asyncio.sleep(sleep) 

def my_map():
    return [random.uniform(0.005, 1) for _ in range(7)]

class _Test_Multiprocessing():
    """Used for Testing aiomultiprocessing"""

    def test_proccess_spawning(self):
        
        # See: https://github.com/Vizonex/Winloop/issues/11#issuecomment-1922659521
        self.processes = set()
        # There must be at least 2 pids setup for this to be correctly ran...
        total_proccesses = 2
        
        async def test():
            async with aiomultiprocess.Pool(total_proccesses) as pool:
                self.processes.update(p.pid for p in pool.processes)
                await pool.map(test_func, my_map())
            await asyncio.sleep(0.005)
            self.assertEqual(len(self.processes), total_proccesses)

        self.loop.run_until_complete(test())
        
       


@unittest.skipIf(skip_tests, "no aiomultiproccess module")
class Test_UV_AioMultiprocess(_Test_Multiprocessing, tb.UVTestCase):
    pass


@unittest.skipIf(skip_tests, "no aiomultiproccess module")
class Test_AIO_AioMultiprocess(_Test_Multiprocessing, tb.AIOTestCase):
    pass


if __name__ == "__main__":
    # I have confirmed that multiproccessing is supported so no need to continue with trying... - Vizonex...
    multiprocessing.freeze_support()
    # aiomultiprocess.set_start_method("spawn")
    winloop.install()
    unittest.main()


