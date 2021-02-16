# %%

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os
from ts_utils.load_data import *
import requests
# %%
if not os.path.exists('data'):
    os.mkdir('data')

url = "https://github.com/owid/covid-19-data/blob/master/public/data/owid-covid-data.xlsx?raw=true"
r = requests.get(url, allow_redirects=True)
with open('data/owid-covid-data.xlsx', 'wb') as w:
    w.write(r.content)

# %%

country_splitted_data = import_owid('data/owid-covid-data.xlsx')

countries_of_interest = ['South Korea', 'United States', 'Canada', 'United Kingdom', 'Germany', 'Japan', 'France', 'Italy','India']


for country in countries_of_interest:
    country_splitted_data[country].to_csv('data/'+ country+ '.csv', index=False)

# %%
