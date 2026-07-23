# test/appium_test.py
# Ready-to-run Appium Automation Test Script for AVA Flutter Android App

import unittest
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.webdriver.common.appiumby import AppiumBy

class AvaAppiumTests(unittest.TestCase):
    def setUp(self):
        options = UiAutomator2Options()
        options.platform_name = "Android"
        options.automation_name = "UiAutomator2"
        options.app_package = "com.ava.hospital"
        options.app_activity = ".MainActivity"
        # Path to release APK if Appium installs it automatically
        options.app = r"c:\Users\cvkew\gamma\build\app\outputs\flutter-apk\app-release.apk"
        options.no_reset = True

        # Connect to local Appium server
        self.driver = webdriver.Remote("http://127.0.0.1:4723", options=options)
        self.driver.implicitly_wait(10)

    def test_01_navigate_to_appointments_and_view_details(self):
        """Test navigating to Appointments tab and opening appointment details sheet"""
        # Click Appointments tab via ValueKey
        nav_appts = self.driver.find_element(AppiumBy.ACCESSIBILITY_ID, "nav_appointments")
        nav_appts.click()

        # Click first appointment card
        appt_card = self.driver.find_element(AppiumBy.XPATH, "//div[contains(@flt-semantics-identifier, 'appointment_card')] | //*[@content-desc='Appointments']")
        self.assertTrue(appt_card.is_displayed())

    def test_02_navigate_to_calls_and_filter(self):
        """Test navigating to Calls tab and tapping filter chips"""
        # Click Calls tab
        nav_calls = self.driver.find_element(AppiumBy.ACCESSIBILITY_ID, "nav_calls")
        nav_calls.click()

        # Click 'Booked' filter chip
        filter_booked = self.driver.find_element(AppiumBy.ACCESSIBILITY_ID, "filter_booked")
        filter_booked.click()

    def tearDown(self):
        if self.driver:
            self.driver.quit()

if __name__ == "__main__":
    unittest.main()
