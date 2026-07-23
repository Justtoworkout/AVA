// selenium-tests/tests/login-tests.js
// Selenium WebDriver E2E Test Suite for AVA Web Frontend Login Flow

const { Builder, By, until } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');
const assert = require('assert');

describe('AVA Web Frontend E2E - Login & Authentication Tests', function () {
  this.timeout(30000); // 30 seconds timeout for E2E tests
  let driver;
  const baseUrl = 'http://localhost:8080'; // Target web app server port

  // UI Element Selectors
  const SELECTORS = {
    usernameField: By.id('login_username_input'),
    passwordField: By.id('login_password_input'),
    submitButton: By.id('login_submit_btn'),
    errorMessage: By.id('login_error_message'),
    rememberMeCheckbox: By.id('login_remember_me'),
    dashboardHeader: By.id('dashboard_header_title'),
    logoutButton: By.id('logout_btn'),
    loadingSpinner: By.className('login_loading_spinner')
  };

  before(async function () {
    // Initialize Chrome Driver in headless mode for CI/CD environments
    const options = new chrome.Options();
    options.addArguments('--headless');
    options.addArguments('--disable-gpu');
    options.addArguments('--no-sandbox');
    options.addArguments('--disable-dev-shm-usage');

    driver = await new Builder()
      .forBrowser('chrome')
      .setChromeOptions(options)
      .build();
  });

  after(async function () {
    if (driver) {
      await driver.quit();
    }
  });

  beforeEach(async function () {
    // Navigate to the Web App url and wait until the login page loads
    await driver.get(`${baseUrl}/#/login`);
    await driver.wait(until.elementLocated(SELECTORS.usernameField), 5000);
  });

  it('TC_LGN_001: Should login successfully with valid admin credentials', async function () {
    // 1. Enter valid credentials
    await driver.findElement(SELECTORS.usernameField).sendKeys('admin@avahospital.com');
    await driver.findElement(SELECTORS.passwordField).sendKeys('SecretAdminPassword123!');

    // 2. Click submit button
    const submitBtn = await driver.findElement(SELECTORS.submitButton);
    await submitBtn.click();

    // 3. Wait for dashboard page redirect
    await driver.wait(until.elementLocated(SELECTORS.dashboardHeader), 10000);

    // 4. Verify login outcome
    const headerText = await driver.findElement(SELECTORS.dashboardHeader).getText();
    assert.match(headerText, /AVA Dashboard/i, 'Should redirect to AVA Dashboard');

    // 5. Verify authentication token exists in sessionStorage
    const authToken = await driver.executeScript("return window.sessionStorage.getItem('auth_token');");
    assert.ok(authToken, 'Authentication token should be stored in session storage');
  });

  it('TC_LGN_002: Should display error message with invalid password', async function () {
    // 1. Enter correct username but wrong password
    await driver.findElement(SELECTORS.usernameField).sendKeys('admin@avahospital.com');
    await driver.findElement(SELECTORS.passwordField).sendKeys('WrongPassword123');

    // 2. Submit
    await driver.findElement(SELECTORS.submitButton).click();

    // 3. Wait for validation error to display
    await driver.wait(until.elementLocated(SELECTORS.errorMessage), 5000);

    // 4. Verify error text
    const errorText = await driver.findElement(SELECTORS.errorMessage).getText();
    assert.strictEqual(errorText, 'Invalid username or password.', 'Error message text mismatch');
  });

  it('TC_LGN_003: Should prompt validation errors for empty fields', async function () {
    // Click submit without entering credentials
    await driver.findElement(SELECTORS.submitButton).click();

    // Verify browser HTML5 validation checks or system alerts
    const usernameInput = await driver.findElement(SELECTORS.usernameField);
    const isValid = await usernameInput.getAttribute('required');
    assert.strictEqual(isValid, 'true', 'Username field should be marked as required');
  });

  it('TC_LGN_004: Should retain session when Remember Me is checked', async function () {
    // 1. Fill credentials and select "Remember Me"
    await driver.findElement(SELECTORS.usernameField).sendKeys('admin@avahospital.com');
    await driver.findElement(SELECTORS.passwordField).sendKeys('SecretAdminPassword123!');
    
    const rememberMe = await driver.findElement(SELECTORS.rememberMeCheckbox);
    if (!(await rememberMe.isSelected())) {
      await rememberMe.click();
    }

    // 2. Submit
    await driver.findElement(SELECTORS.submitButton).click();
    await driver.wait(until.elementLocated(SELECTORS.dashboardHeader), 10000);

    // 3. Verify cookie or localStorage persistence
    const persistentToken = await driver.executeScript("return window.localStorage.getItem('remember_token');");
    assert.ok(persistentToken, 'Remember token should be stored in localStorage');
  });

  it('TC_LGN_005: Should clear credentials and sessions on Logout', async function () {
    // 1. Log in
    await driver.findElement(SELECTORS.usernameField).sendKeys('admin@avahospital.com');
    await driver.findElement(SELECTORS.passwordField).sendKeys('SecretAdminPassword123!');
    await driver.findElement(SELECTORS.submitButton).click();

    // 2. Wait for dashboard and click Logout
    const logoutBtn = await driver.wait(until.elementLocated(SELECTORS.logoutButton), 5000);
    await logoutBtn.click();

    // 3. Wait for redirect back to Login
    await driver.wait(until.elementLocated(SELECTORS.usernameField), 5000);

    // 4. Verify session storage is cleared
    const authToken = await driver.executeScript("return window.sessionStorage.getItem('auth_token');");
    assert.strictEqual(authToken, null, 'Authentication token should be deleted from session storage');
  });
});
