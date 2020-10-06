
# %%
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os
from pickle import load

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os
from ts_utils.load_data import *

N=7

country_splitted_data = import_owid('data/owid-covid-data.xlsx')
country_splitted_mobility = import_mobility('data/Global_Mobility_Report.csv')

if not os.path.exists('outputs/phase_plane'):
    os.mkdir('outputs/phase_plane')
N=7
plt.figure(figsize=(20, 10))
plt.xlabel('transit_stations_percent_change_from_baseline')
plt.ylabel('new cases per million')
plt.title('Phase-plane plot of mobility against new cases')

for country in ['Canada', 'United States', 'United Kingdom', 'Mexico']:
    all_country = pd.merge(country_splitted_mobility[country],country_splitted_data[country], on='date')
    mobility = all_country['transit_stations_percent_change_from_baseline'].rolling(N).mean()
    new_cases = all_country['new_cases_per_million'].rolling(N).mean()
    mobility = mobility.fillna(value=0)
    new_cases = new_cases.fillna(value=0)

    plt.scatter(mobility, new_cases, s=5, alpha=0.7)
    plt.scatter(mobility.to_numpy()[-1], new_cases.to_numpy()[-1], s=30, alpha=1, color='black')
    for i, _ in enumerate(mobility.to_numpy()[:-1]):
        if i % 5 == 0:
            plt.arrow(mobility[i], new_cases[i], mobility[i+1] - mobility[i], new_cases[i+1] - new_cases[i], head_width=0.5)
    plt.plot(mobility, new_cases, alpha=0.5, label=country)
    plt.legend()

plt.savefig('outputs/phase_plane/mobility_vs_new_cases.png')
#, 'Mexico', 'United Kingdom'
# %%

N=7
plt.figure(figsize=(30, 16))
plt.xlabel('PCA axis 0 mobility')
plt.ylabel('new cases per million')
plt.title('Phase-plane plot of mobility against new cases')

grand_pca = load(open('outputs/grand_pca.pickle', 'rb'))
columns_of_interest = ['retail_and_recreation_percent_change_from_baseline', 'grocery_and_pharmacy_percent_change_from_baseline', 'transit_stations_percent_change_from_baseline','workplaces_percent_change_from_baseline', 'residential_percent_change_from_baseline'] 
for country in ['Canada', 'United States', 'United Kingdom', 'Mexico']:
    all_country = pd.merge(country_splitted_mobility[country],country_splitted_data[country], on='date')
    mobility = all_country[columns_of_interest].rolling(N).mean()
    new_cases = all_country['new_cases_per_million'].rolling(N).mean()
    mobility = mobility.fillna(value=0)
    new_cases = new_cases.fillna(value=0)
    mobility = mobility.to_numpy()
    mobility = grand_pca.transform(mobility)[:, 0]

    plt.scatter(mobility, new_cases, s=5, alpha=0.7)
    plt.scatter(mobility[-1], new_cases.to_numpy()[-1], s=30, alpha=1, color='black')
    for i, _ in enumerate(mobility[:-1]):
        if i % 5 == 0:
            plt.arrow(mobility[i], new_cases[i], mobility[i+1] - mobility[i], new_cases[i+1] - new_cases[i], head_width=0.5)
    plt.plot(mobility, new_cases, alpha=0.5, label=country)
    plt.legend()

plt.savefig('outputs/phase_plane/pca_mobility_vs_new_cases.png')
#, 'Mexico', 'United Kingdom'

# %%

# %%

plt.figure(figsize=(30, 16))
plt.xlabel('PCA axis 0 mobility')
plt.ylabel('PCA axis 1 mobility')
plt.title('Phase-plane plot of PCA axes 0 and 1')

columns_of_interest = ['retail_and_recreation_percent_change_from_baseline', 'grocery_and_pharmacy_percent_change_from_baseline', 'transit_stations_percent_change_from_baseline','workplaces_percent_change_from_baseline', 'residential_percent_change_from_baseline'] 
for country in ['Canada', 'United States', 'United Kingdom', 'Mexico']:
    all_country = pd.merge(country_splitted_mobility[country],country_splitted_data[country], on='date')
    mobility = all_country[columns_of_interest].rolling(N).mean()

    mobility = mobility.fillna(value=0)

    mobility = mobility.to_numpy()
    mobility = grand_pca.transform(mobility)

    plt.scatter(mobility[:, 0], mobility[:, 1], s=5, alpha=0.7)

    plt.scatter(mobility[-1][0], mobility[-1][1], s=30, alpha=1, color='black')

    for i, _ in enumerate(mobility[:-1]):
        if i % 5 == 0:
            plt.arrow(mobility[i][0], mobility[i][1], mobility[i+1][0] - mobility[i][0], mobility[i+1][1] - mobility[i][1], head_width=0.5)
    plt.plot(mobility[:, 0], mobility[:, 1], alpha=0.5, label=country)
    plt.legend()

plt.savefig('outputs/phase_plane/pca_mobility_0_vs_1.png')
#, 'Mexico', 'United Kingdom'

# %%


N=7
plt.figure(figsize=(20, 10))
plt.xlabel('total cases per million')
plt.ylabel('new cases per million')
plt.title('Phase-plane plot of total vs new cases')


for country in ['Canada', 'United States', 'United Kingdom', 'Mexico', 'India', 'Germany', 'South Korea']:
    all_country = pd.merge(country_splitted_mobility[country],country_splitted_data[country], on='date')
    mobility = all_country['total_cases_per_million'].rolling(N).mean()
    new_cases = all_country['new_cases_per_million'].rolling(N).mean()


    mobility = mobility.fillna(value=0)
    new_cases = new_cases.fillna(value=0)

    plt.scatter(mobility, new_cases, s=5, alpha=0.7)
    plt.scatter(mobility.to_numpy()[-1], new_cases.to_numpy()[-1], s=30, alpha=1, color='black')
    for i, _ in enumerate(mobility.to_numpy()[:-1]):
        if i % 5 == 0:
            plt.arrow(mobility[i], new_cases[i], mobility[i+1] - mobility[i], new_cases[i+1] - new_cases[i], head_width=2, head_length = 30)
    plt.plot(mobility, new_cases, alpha=0.5, label=country)
    plt.legend()

plt.savefig('outputs/phase_plane/total_vs_new_cases.png')
#, 'Mexico', 'United Kingdom'


# %%


plt.figure(figsize=(20, 10))
plt.xlabel('new tests per thousand')
plt.ylabel('new cases per million')
plt.title('Phase-plane plot of tests vs new cases')

for country in ['Canada', 'United States', 'United Kingdom', 'Mexico', 'India', 'Germany', 'South Korea']:
    all_country = pd.merge(country_splitted_mobility[country],country_splitted_data[country], on='date')
    all_country = all_country[['new_tests_per_thousand','new_cases_per_million']]
    all_country = all_country.dropna()
    mobility = all_country['new_tests_per_thousand'].rolling(N).mean().to_numpy()
    new_cases = all_country['new_cases_per_million'].rolling(N).mean().to_numpy()

    if not len(new_cases) == 0:
        plt.scatter(mobility, new_cases, s=5, alpha=0.7)
        plt.scatter(mobility[-1], new_cases[-1], s=30, alpha=1, color='black')
     #   for i, _ in enumerate(mobility[:-1]):
      #      if i % 5 == 0:
       #         plt.arrow(mobility[i], new_cases[i], mobility[i+1] - mobility[i], new_cases[i+1] - new_cases[i], head_width=0.02, head_length = 1, width=0)
        plt.plot(mobility, new_cases, alpha=0.5, label=country)
    plt.legend()

plt.savefig('outputs/phase_plane/new_tests_vs_cases.png')
#, 'Mexico', 'United Kingdom'


# %%



