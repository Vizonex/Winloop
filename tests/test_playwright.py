try:
    from playwright.async_api import async_playwright
except ImportError:
    skip_tests = True
else:
    skip_tests = False

import unittest

from winloop import _testbase as tb

# SEE: https://github.com/Vizonex/Winloop/issues/34


class _TestPlaywright:
    def test_example_code(self):
        # Example code is from microsoft's own example,
        # see https://github.com/microsoft/playwright-python
        async def run():
            async with async_playwright() as p:
                for browser_type in [p.chromium, p.firefox, p.webkit]:
                    browser = await browser_type.launch()
                    page = await browser.new_page()
                    await page.goto("http://playwright.dev")
                    path = f"example-{browser_type.name}.png"
                    await page.screenshot(path=path)
                    await browser.close()

        self.loop.run_until_complete(run())


@unittest.skipIf(skip_tests, "no playwright module")
class Test_UV_Playwright(_TestPlaywright, tb.UVTestCase):
    pass


@unittest.skipIf(skip_tests, "no playwright module")
class Test_AIO_Playwright(_TestPlaywright, tb.AIOTestCase):
    pass
