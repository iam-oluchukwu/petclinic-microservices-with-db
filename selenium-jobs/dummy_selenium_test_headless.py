from selenium import webdriver

chrome_options = webdriver.ChromeOptions()
chrome_options.add_argument("--headless=new")
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("--disable-dev-shm-usage")

driver = webdriver.Chrome(options=chrome_options)

try:
    base_url = "https://www.google.com/"
    driver.get(base_url)

    source = driver.page_source

    if "I'm Feeling Lucky" in source:
        print("SUCCESS: Selenium dummy test passed!")
    else:
        raise AssertionError("Selenium dummy test failed!")

finally:
    driver.quit()
