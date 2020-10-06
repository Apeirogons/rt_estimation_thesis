# To add a new cell, type '# %%'
# To add a new markdown cell, type '# %% [markdown]'
# %%
import os
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

from sklearn.decomposition import PCA, NMF, TruncatedSVD
from sklearn.metrics import r2_score, mean_absolute_error
from pickle import dump
from ts_utils.load_data import *

country_splitted_data = import_owid('data/owid-covid-data.xlsx')
country_splitted_mobility = import_mobility('data/Global_Mobility_Report.csv')

countries_of_interest = ['South Korea', 'United States', 'Canada', 'United Kingdom', 'Germany', 'Japan', 'France', 'Italy', 'India']


# %%

N = 7
if not os.path.exists('outputs/reconstructions'):
    os.mkdir('outputs/reconstructions')

columns_of_interest = ['retail_and_recreation_percent_change_from_baseline', 'grocery_and_pharmacy_percent_change_from_baseline', 'transit_stations_percent_change_from_baseline','workplaces_percent_change_from_baseline', 'residential_percent_change_from_baseline'] 


# %%
pc_overall_data = None
for country in country_splitted_mobility.keys():
    country_smoothed = country_splitted_mobility[country][columns_of_interest].rolling(N).mean()
    country_smoothed = country_smoothed.dropna()
    if len(country_smoothed) > 200:
        np_data = country_smoothed.to_numpy()

    if pc_overall_data is None:
        pc_overall_data = np_data
    else:    
        pc_overall_data = np.concatenate([pc_overall_data, np_data], axis=0)   


# %%
grand_pca = PCA(2)
new_overall_data = grand_pca.fit_transform(pc_overall_data)
print(grand_pca.explained_variance_ratio_)

# total explained variance ratio is equal to the variance-weighted reconstruction R2
print(np.sum(grand_pca.explained_variance_ratio_))
print(r2_score(pc_overall_data, grand_pca.inverse_transform(grand_pca.transform(pc_overall_data)),multioutput='variance_weighted'))


# %%
columns_of_interest = ['retail_and_recreation_percent_change_from_baseline', 'grocery_and_pharmacy_percent_change_from_baseline', 'transit_stations_percent_change_from_baseline','workplaces_percent_change_from_baseline', 'residential_percent_change_from_baseline'] 


# %%
print('PC components: ')
print(grand_pca.components_)


# %%
for country in countries_of_interest:
    country_smoothed = country_splitted_mobility[country][columns_of_interest].rolling(N).mean()
    country_smoothed = country_smoothed.dropna()
    if len(country_smoothed) > 200:
        np_data = country_smoothed.to_numpy()


        plt.figure(figsize=(10, 5))
        plt.title('PCA reconstructions for ' +country)
        pca_reconstructions =grand_pca.inverse_transform(grand_pca.transform(np_data)) 
        reconstruction_accs = np.abs(np_data - pca_reconstructions)
        plt.xlabel('Day')
        plt.ylabel('% change from baseline')

        for i, col in enumerate(columns_of_interest):
            plt.plot(np_data[:, i], label=col)
            plt.plot(pca_reconstructions[:, i], alpha=0.5, color='grey')
            
        plt.legend()
        plt.savefig('outputs/reconstructions/'+ country.replace(' ', '_') + '.png')
        plt.close()
    # plt.show()


# %%
dump(grand_pca, open('outputs/grand_pca.pickle', 'wb'))


# %%



