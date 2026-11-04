from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import os
import random

# Configure headless Chrome
options = webdriver.ChromeOptions()
options.add_argument("--headless=new")
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")

APP_IP = os.environ["MASTER_PUBLIC_IP"]
url = f"http://{APP_IP.strip()}:8080/"

driver = webdriver.Chrome(options=options)

try:
    wait = WebDriverWait(driver, 20)
    driver.get(url)

    # Navigate to Owners -> Register
    wait.until(
        EC.element_to_be_clickable(
            (By.LINK_TEXT, "OWNERS")
        )
    ).click()

    wait.until(
        EC.element_to_be_clickable(
            (By.LINK_TEXT, "REGISTER")
        )
    ).click()

    # Register a new owner
    first_name = "Callahan" + str(random.randint(10000, 99999))

    fields = {
        "firstName": first_name,
        "lastName": "Clarusway",
        "address": "Ridge Corp. Street",
        "city": "McLean",
        "telephone": "+1230576803"
    }

    for name, value in fields.items():
        field = wait.until(
            EC.visibility_of_element_located(
                (By.NAME, name)
            )
        )
        field.send_keys(value)

    # Submit registration
    driver.find_element(
        By.NAME, "telephone"
    ).send_keys(Keys.ENTER)

    # Verify registration succeeded
    WebDriverWait(driver, 30).until(
        lambda d: first_name in d.page_source
    )

    print(first_name, "was successfully registered")
    print("Test Passed")

finally:
    driver.quit()
