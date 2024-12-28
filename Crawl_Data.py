#!/usr/bin/env python
# coding: utf-8

# ## **PIP INSTALL LIBRARY**

# In[ ]:


pip install selenium


# In[ ]:


pip install webdriver-manager


# ## **IMPORT LIBRARY**

# In[ ]:


import pandas as pd
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from selenium.webdriver.chrome.options import Options
import pyodbc
import time


# ## **PROCESSING WEB CRAWLING**

# ### **CONNECT WEBSITE**

# In[ ]:


# Path to Chromedriver
chromedriver_path = r"C:\Users\ThinkPad\OneDrive\chromedriver-win64\chromedriver.exe"  # Đảm bảo rằng đường dẫn chính xác

# Service with path ChromeDriver
service = ChromeService(executable_path=chromedriver_path)

# Service và Options in ChromeDriver
driver_manual = webdriver.Chrome(service=service)

# Open Website
url = driver_manual.get("https://careerviet.vn/viec-lam/ha-noi-ho-chi-minh-da-nang-l4,8,511-trang-1-vi.html")

expected_url = driver_manual.current_url
if expected_url != url:
    driver_manual.get("https://careerviet.vn/viec-lam/ha-noi-ho-chi-minh-da-nang-l4,8,511-trang-1-vi.html")


# ### **CONNECT AZURE SERVER**

# In[ ]:


server  = 'tcp:server-group-5.database.windows.net'
database = 'DatabaseofGroup5'
username = 'admin-group-5'
password = 'Matkhau123'
driver = '{ODBC Driver 18 for SQL Server}'


# ### **CREATE TABLE**

# In[ ]:


def create_table(connection_string):
    try:
        conn = pyodbc.connect(connection_string)
        cursor = conn.cursor()
        print("Connected to the database successfully.")

        # Create table query if not exists
        create_table_query = """
        IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Career_3')
        BEGIN
            CREATE TABLE Career_3 (
                ID INT IDENTITY(1,1) PRIMARY KEY,
                TITLE NVARCHAR(255),
                SALARY NVARCHAR(255),
                LOCATION NVARCHAR(255),
                OPPORTUNITY NVARCHAR(255),
                UPDATE_DATE NVARCHAR(255),  
                EMPLOYER NVARCHAR(255),
                MAJOR NVARCHAR(255),
                HINH_THUC NVARCHAR(255),
                KINH_NGHIEM NVARCHAR(255),
                CAP_BAC NVARCHAR(255)
            );
        END
        """
        # Execute query
        cursor.execute(create_table_query)
        conn.commit()
        print("Table created.")
        return True  # Success
    except Exception as e:
        print(f"Error creating table: {e}")
        return False 
    finally:
        if 'conn' in locals() and conn:
            conn.close()  


# ### **INSERT AND STORE**

# In[ ]:


def insert_store(driver_manual, connection_string, start_page=1, max_page=400):
    try:
        conn = pyodbc.connect(connection_string)
        cursor = conn.cursor()
        print("Database connection established.")

        page = start_page

        while page <= max_page:
            try:
               
                driver_manual.get(f"https://careerviet.vn/viec-lam/ha-noi-ho-chi-minh-da-nang-l4,8,511-trang-{page}-vi.html")

                WebDriverWait(driver_manual, 10).until(
                    EC.visibility_of_all_elements_located((By.CSS_SELECTOR, ".title [href]"))
                )

                # Extract data
                titles = [elem.text for elem in driver_manual.find_elements(By.CSS_SELECTOR, ".title [href]")]
                links = [elem.get_attribute('href') for elem in driver_manual.find_elements(By.CSS_SELECTOR, ".title [href]")]
                salaries = [elem.text for elem in driver_manual.find_elements(By.CSS_SELECTOR, ".salary")]
                locations = [elem.text for elem in driver_manual.find_elements(By.CSS_SELECTOR, ".location")]
                opportunities = [elem.text for elem in driver_manual.find_elements(By.CSS_SELECTOR, ".expire-date")]
                updates = [elem.text for elem in driver_manual.find_elements(By.CSS_SELECTOR, ".time time")]
                employers = [elem.text for elem in driver_manual.find_elements(By.CSS_SELECTOR, ".company-name")]

                # Process each job posting
                for i in range(len(titles)):
                    title = titles[i] if i < len(titles) else None
                    link = links[i] if i < len(links) else None
                    salary = salaries[i] if i < len(salaries) else None
                    location = locations[i] if i < len(locations) else None
                    opportunity = opportunities[i] if i < len(opportunities) else None
                    update = updates[i] if i < len(updates) else None
                    employer = employers[i] if i < len(employers) else None

                    major, hinh_thuc, kinh_nghiem, cap_bac = None, None, None, None

                    if link:
                        driver_manual.get(link)
                        try:
                            detail_boxes = driver_manual.find_elements(By.CSS_SELECTOR, ".detail-box.has-background")

                            if detail_boxes:
                                major = detail_boxes[0].find_elements(By.TAG_NAME, "li")[1].text if len(detail_boxes[0].find_elements(By.TAG_NAME, "li")) > 1 else None
                                hinh_thuc = detail_boxes[0].find_elements(By.TAG_NAME, "li")[2].text if len(detail_boxes[0].find_elements(By.TAG_NAME, "li")) > 2 else None

                                if len(detail_boxes) > 1:
                                    kinh_nghiem = detail_boxes[1].find_elements(By.TAG_NAME, "li")[1].text if len(detail_boxes[1].find_elements(By.TAG_NAME, "li")) > 1 else None
                                    cap_bac = detail_boxes[1].find_elements(By.TAG_NAME, "li")[2].text if len(detail_boxes[1].find_elements(By.TAG_NAME, "li")) > 2 else None

                        except Exception as e:
                            print(f"Error extracting job details from {link}: {e}")

                    try:
                        # Insert data into the database
                        cursor.execute("""
                        INSERT INTO Career_3 (TITLE, SALARY, LOCATION, OPPORTUNITY, UPDATE_DATE, EMPLOYER, MAJOR, HINH_THUC, KINH_NGHIEM, CAP_BAC)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """,
                        title, salary, location, opportunity, update, employer, major, hinh_thuc, kinh_nghiem, cap_bac
                        )
                        conn.commit()
                    except Exception as e:
                        print(f"Error inserting data into database: {e}")

                print(f"Page {page}: Successfully processed.")

            except Exception as e:
                print(f"Error processing page {page}: {e}")

            page += 1

        print("Scraping completed.")

    except Exception as e:
        print(f"Database connection error: {e}")

    finally:
        if 'conn' in locals() and conn:
            conn.close()
            print("Database connection closed.")


# ## **CALL FUNCTION**

# In[ ]:


connection_string = f"DRIVER={driver};SERVER={server};DATABASE={database};UID={username};PWD={password}"
create_table(connection_string) 
insert_store(driver_manual, connection_string, start_page=1, max_page=5)  

