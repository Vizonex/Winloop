try:
    import multiprocessing

    import aiomultiprocess
except ImportError:
    skip_tests = True
else:
    skip_tests = False
import asyncio
import random
import unittest

import winloop
from winloop import _testbase as tb


def my_map():
    return [random.uniform(0.005, 1) for _ in range(7)]


class _Test_Multiprocessing:
    """Used for Testing aiomultiprocessing"""

    @unittest.skip(
        "aiomultiprocess has an import bug releated to having a tests module"
    )
    def test_process_spawning(self):
        # See:
        # https://github.com/Vizonex/Winloop/issues/11#issuecomment-1922659521
        self.processes = set()
        # There must be at least 2 pids setup for this to be correctly ran...
        total_processes = 2

        async def test():
            async with aiomultiprocess.Pool(total_processes) as pool:
                self.processes.update(p.pid for p in pool.processes)
                await pool.map(asyncio.sleep, my_map())
            await asyncio.sleep(0.005)
            self.assertEqual(len(self.processes), total_processes)

        self.loop.run_until_complete(test())


@unittest.skipIf(skip_tests, "no aiomultiprocess module")
class Test_UV_AioMultiprocess(_Test_Multiprocessing, tb.UVTestCase):
    pass


@unittest.skipIf(skip_tests, "no aiomultiprocess module")
class Test_AIO_AioMultiprocess(_Test_Multiprocessing, tb.AIOTestCase):
    pass


if __name__ == "__main__":
    # I have confirmed that multiprocessing is supported so no need
    # to continue with trying... - Vizonex...
    multiprocessing.freeze_support()
    # aiomultiprocess.set_start_method("spawn")
    winloop.install()
    unittest.main()
