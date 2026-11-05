from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import os

# Configure Chrome for headless execution
chrome_options = webdriver.ChromeOptions()
chrome_options.add_argument("--headless=new")
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("--disable-dev-shm-usage")

# Get the Petclinic application address
APP_IP = os.environ["MASTER_PUBLIC_IP"]
url = "http://" + APP_IP.strip() + ":30001/"

print("Opening:", url)

driver = webdriver.Chrome(options=chrome_options)

try:
    driver.get(url)
    wait = WebDriverWait(driver, 20)

    # Navigate to Owners
    owners_link = wait.until(
        EC.element_to_be_clickable((By.LINK_TEXT, "OWNERS"))
    )
    owners_link.click()

    # Navigate to All
    all_link = wait.until(
        EC.element_to_be_clickable((By.LINK_TEXT, "ALL"))
    )
    all_link.click()

    # Verify that the owners table loads
    wait.until(
        EC.presence_of_element_located((By.TAG_NAME, "table"))
    )

    print("Table loaded")
    print("Test Passed")

finally:
    driver.quit()
