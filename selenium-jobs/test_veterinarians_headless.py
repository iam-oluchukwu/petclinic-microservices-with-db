from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import os

# Configure Chrome for headless testing
options = webdriver.ChromeOptions()
options.add_argument("--headless=new")
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")

# Petclinic application URL
APP_IP = os.environ["MASTER_PUBLIC_IP"]
url = f"http://{APP_IP.strip()}:8080/"

driver = webdriver.Chrome(options=options)

try:
    wait = WebDriverWait(driver, 20)

    print("Opening Petclinic:", url)
    driver.get(url)

    # Open Veterinarians page
    vet_link = wait.until(
        EC.element_to_be_clickable(
            (By.LINK_TEXT, "VETERINARIANS")
        )
    )
    vet_link.click()

    # Verify veterinarians table loads
    wait.until(
        EC.presence_of_element_located(
            (By.TAG_NAME, "table")
        )
    )

    print("Veterinarians table loaded")
    print("Test Passed")

finally:
    driver.quit()
