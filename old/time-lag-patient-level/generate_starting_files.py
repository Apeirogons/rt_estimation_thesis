# Gets the time lag for each category of interest and saves to differenced_data

# %%

import pandas as pd 
import numpy as np
from itertools import combinations
import matplotlib.pyplot as plt
from statsmodels.graphics.gofplots import qqplot
from scipy.stats import normaltest, describe, iqr, linregress
import random
import os
from utils.starting_files import *

data = pd.read_csv('latestdata.csv')

countries = data['country']
unique_countries = countries.dropna(inplace=False).unique()
for unique in unique_countries:
    print(unique + ': '+ str(countries.to_list().count(unique))) 


# %%
categories_of_interest = ['date_onset_symptoms', 'date_admission_hospital', 'date_confirmation', 'date_death', 'date_discharge']
pairwise_comparisons = list(combinations(categories_of_interest, 2))
pairwise_comparisons.remove(('date_death', 'date_discharge'))

with open('categories_list.txt', 'w') as cat:
    cat.write(str(pairwise_comparisons))

country_indices = country_index(data, unique_countries)

# %%
all_comparisons = {}

for comparison in pairwise_comparisons:
    print(comparison)
    this_comparison_data = {}

    for country in country_indices.keys():
        if 'date_death' in comparison:
            c = death_discharge_comparisons(data.loc[country_indices[country]], comparison[0])[0]
        elif 'date_discharge' in comparison:
            c = death_discharge_comparisons(data.loc[country_indices[country]], comparison[0])[1]
        else:
            c = basic_comparisons(data.loc[country_indices[country]], comparison)
        this_comparison_data[country] = preprocess(data.loc[c], comparison)
        print(country)

        print(this_comparison_data[country].shape)

    all_comparisons[comparison] = this_comparison_data

# %%
if not os.path.exists('differenced_data'):
    os.mkdir('differenced_data')

for comparison_name in all_comparisons.keys():
    comparison = all_comparisons[comparison_name]

    folder_name = 'differenced_data/' + comparison_name[0] +'-' +comparison_name[1]

    if not os.path.exists(folder_name):
        os.mkdir(folder_name)

    for country_name in comparison.keys():
        comparison[country_name].to_csv(folder_name+'/'+country_name+'.csv')


# %%



