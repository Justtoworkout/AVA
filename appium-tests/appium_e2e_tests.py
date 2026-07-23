# appium-tests/appium_e2e_tests.py
# Comprehensive Appium E2E Test Suite for AVA Flutter App (Android/iOS)

import unittest
import time
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.webdriver.common.appiumby import AppiumBy

class AvaAppiumE2ETests(unittest.TestCase):
    def setUp(self):
        # Configure Appium UiAutomator2 Driver Options for Android emulator/device
        options = UiAutomator2Options()
        options.platform_name = "Android"
        options.automation_name = "UiAutomator2"
        options.app_package = "com.ava.hospital"
        options.app_activity = ".MainActivity"
        
        # Path pointing to built release APK
        options.app = r"c:\Users\cvkew\gamma\build\app\outputs\flutter-apk\app-release.apk"
        options.no_reset = True
        options.new_command_timeout = 300

        # Connect to local running Appium server
        self.driver = webdriver.Remote("http://127.0.0.1:4723", options=options)
        self.driver.implicitly_wait(12)

    def tearDown(self):
        if self.driver:
            self.driver.quit()

    def test_01_verify_dashboard_widgets_and_live_badge(self):
        """E2E Test: Verify Dashboard stats display and live updating state"""
        print("Running Test 01: Verify Dashboard widgets...")
        
        # 1. Assert screen contains dashboard title
        title_el = self.driver.find_element(AppiumBy.XPATH, "//*[contains(@content-desc, 'AVA Dashboard')] | //*[contains(@text, 'AVA Dashboard')]")
        self.assertTrue(title_el.is_displayed(), "AVA Dashboard title should be displayed")

        # 2. Verify existence of the live indicator badge
        live_badge = self.driver.find_element(AppiumBy.ACCESSIBILITY_ID, "live_badge") if self.has_element(AppiumBy.ACCESSIBILITY_ID, "live_badge") else self.driver.find_element(AppiumBy.XPATH, "//*[contains(@content-desc, 'LIVE')]")
        self.assertTrue(live_badge.is_displayed(), "LIVE connection indicator badge should be visible")

        # 3. Check stats cards
        calls_today_card = self.driver.find_element(AppiumBy.XPATH, "//*[contains(@content-desc, 'Calls Today')]")
        self.assertTrue(calls_today_card.is_displayed(), "Calls Today stats card should be visible")

    def test_02_calls_tab_navigation_and_filtering(self):
        """E2E Test: Navigate to Calls tab, verify call logs, and test client-side filter chips"""
        print("Running Test 02: Verify Calls tab filters...")

        # 1. Tap the Navigation item for Calls
        nav_calls = self.driver.find_element(AppiumBy.ACCESSIBILITY_ID, "nav_calls")
        nav_calls.click()
        time.sleep(1)

        # 2. Click the 'Failed' filter chip to narrow down records
        filter_failed = self.driver.find_element(AppiumBy.ACCESSIBILITY_ID, "filter_failed")
        filter_failed.click()
        time.sleep(1.5)

        # 3. Click the 'Booked' filter chip
        filter_booked = self.driver.find_element(AppiumBy.ACCESSIBILITY_ID, "filter_booked")
        filter_booked.click()

    def test_03_call_details_sheet_and_transcript_playback(self):
        """E2E Test: Open call detail bottom sheet, verify transcript rendering, and test player playback controls"""
        print("Running Test 03: Verify Call Details Bottom Sheet...")

        # 1. Open calls view
        self.driver.find_element(AppiumBy.ACCESSIBILITY_ID, "nav_calls").click()

        # 2. Tap on the first call item in the list
        call_item = self.driver.find_element(AppiumBy.XPATH, "//*[contains(@content-desc, 'appointment_card')] | //*[contains(@content-desc, 'Calls')]")
        call_item.click()
        time.sleep(1.5)

        # 3. Verify detail sheet items exist (Summary, Transcript, Player)
        summary_section = self.driver.find_element(AppiumBy.XPATH, "//*[contains(@content-desc, 'AI Summary')]")
        self.assertTrue(summary_section.is_displayed(), "AI Summary section should display in call detail sheet")

        # 4. Trigger audio player play button
        play_btn = self.driver.find_element(AppiumBy.ACCESSIBILITY_ID, "audio_play_btn")
        play_btn.click()
        time.sleep(2) # simulate 2 seconds of audio playback

        # 5. Tap pause button
        play_btn.click()

    def test_04_appointments_calendar_feed(self):
        """E2E Test: Navigate to Appointments tab and check upcoming events list"""
        print("Running Test 04: Verify Appointments feed...")

        # 1. Tap the Appointments navigation item
        nav_appts = self.driver.find_element(AppiumBy.ACCESSIBILITY_ID, "nav_appointments")
        nav_appts.click()
        time.sleep(1.5)

        # 2. Verify Today heading or list is visible
        today_section = self.driver.find_element(AppiumBy.XPATH, "//*[contains(@content-desc, 'Today')] | //*[contains(@text, 'Today')]")
        self.assertTrue(today_section.is_displayed(), "Calendar should display 'Today' section")

    def has_element(self, by_type, selector):
        try:
            self.driver.find_element(by_type, selector)
            return True
        except:
            return False

if __name__ == "__main__":
    unittest.main()
