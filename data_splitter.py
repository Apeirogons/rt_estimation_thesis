# %%

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os
from ts_utils.load_data import *



country_splitted_data = import_owid('data/owid-covid-data.xlsx')

countries_of_interest = ['South Korea', 'United States', 'Canada', 'United Kingdom', 'Germany', 'Japan', 'France', 'Italy','India']


for country in countries_of_interest:
    country_splitted_data[country].to_csv('data/'+ country+ '.csv', index=False)

# %%
