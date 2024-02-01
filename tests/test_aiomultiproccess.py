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

from winloop import _testbase as tb
from winloop import Loop

# TODO: Neseted wrapper maybe?

def my_map():
    return [random.uniform(1, 3) for _ in range(7)]

async def test_func(sleep:float):
    return await asyncio.sleep(sleep)

class _Test_Multiproccessing:
    """Used for Testing aiomultiprocessing"""
    loop:Loop
    def test_proccess_spawning_1(self):
        async def test():
            # Can we spawn 2 proccesses to run?
            async with aiomultiprocess.Pool(1) as pool:
                await pool.map(test_func, my_map())
        self.loop.run_until_complete(test())

    def test_proccess_spawning_2(self):
        async def test():
            async with aiomultiprocess.Pool(2) as pool:
                await pool.map(test_func, my_map())
        self.loop.run_until_complete(test())

    def test_proccess_spawning_3(self):
        # Can we spawn 2 proccesses to run?
        async def test():
            async with aiomultiprocess.Pool(3) as pool:
                await pool.map(test_func, my_map())
        self.loop.run_until_complete(test())
        


@unittest.skipIf(skip_tests, "no aiomultiproccess module")
class Test_UV_AioMultiproccess(_Test_Multiproccessing, tb.UVTestCase):
    pass


@unittest.skipIf(skip_tests,"no aiomultiproccess module")
class Test_AIO_AioMultiproccess(_Test_Multiproccessing, tb.AIOTestCase):
    pass

if __name__ == "__main__":
    # I have confirmed that multiproccessing is supported so no need to continue with trying... - Vizonex...
    winloop.install()
    unittest.main()



