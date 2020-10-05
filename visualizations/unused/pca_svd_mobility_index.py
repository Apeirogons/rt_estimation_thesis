# To add a new cell, type '# %%'
# To add a new markdown cell, type '# %% [markdown]'
# %%
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os
from sklearn.decomposition import PCA, NMF, TruncatedSVD
from sklearn.metrics import r2_score, mean_absolute_error

original_data = pd.read_excel('data/owid-covid-data.xlsx')
unique_countries = list(set(original_data['location']))
country_splitted_data = {}
for country in unique_countries:
    country_data = original_data[original_data['location']==country]
    country_data['date'] = pd.to_datetime(country_data['date'])
    country_data = country_data[['date', 'total_cases_per_million', 'new_cases_per_million', 'total_deaths_per_million', 'new_deaths_per_million', 'total_tests_per_thousand', 'new_tests_per_thousand']]
    country_splitted_data[country] = country_data


mobility_data = pd.read_csv('data/Global_Mobility_Report.csv')

unique_mobility_countries = list(set(mobility_data['country_region']))
country_splitted_mobility = {}
for country in unique_mobility_countries:
    country_data = mobility_data[mobility_data['country_region']==country]
    country_data['date'] = pd.to_datetime(country_data['date'])
    country_data = country_data[pd.isna(country_data['sub_region_1']) &pd.isna(country_data['sub_region_2']) & pd.isna(country_data['metro_area'])]
    country_splitted_mobility[country] = country_data



countries_of_interest = ['South Korea', 'United States', 'Canada', 'United Kingdom', 'Germany', 'Japan', 'France', 'Italy', 'India']


# %%
if not os.path.exists('mobility_pca'):
    os.mkdir('mobility_pca')

columns_of_interest = ['retail_and_recreation_percent_change_from_baseline', 'grocery_and_pharmacy_percent_change_from_baseline', 'transit_stations_percent_change_from_baseline','workplaces_percent_change_from_baseline', 'residential_percent_change_from_baseline'] #, 
N=7
# Parks ignored due to nonlinear correlations with others

for country_name in countries_of_interest:
    # Plotting all of the changes

    country = country_name
    fig, ax = plt.subplots(figsize=(20, 10))
    for target in columns_of_interest:
        if not target == 'residential_percent_change_from_baseline':
            ax.plot(pd.to_datetime(country_splitted_mobility[country]['date']), country_splitted_mobility[country][target].rolling(N).mean(), label= "_".join(target.split('_')[:-4]), alpha=0.1)
        else:
            ax.plot(pd.to_datetime(country_splitted_mobility[country]['date']), (-1*country_splitted_mobility[country][target]).rolling(N).mean(), label= 'negative of ' + "_".join(target.split('_')[:-4]), alpha=0.1)

    ax.set_ylabel('Mobility %change from baseline')

    # Reduce crowding on x-axis
    every_nth = 2
    for n, label in enumerate(ax.xaxis.get_ticklabels()):
        if n % every_nth != 0:
            label.set_visible(False)

    plt.xlabel('Date')



    data = country_splitted_mobility[country_name][columns_of_interest].rolling(N).mean()
    data = data.dropna()

    # PC 0 generally covers major trends, while PC 1 covers minor trends
    pca = PCA(1)#
    pca_transformed = pca.fit_transform(data)



    ax2 = ax.twinx()
    ax2.plot(pd.to_datetime(country_splitted_mobility[country]['date'])[N-1:], -1*pca_transformed[:, 0], color='red', label='PC 0') #, linestyle=':'
  #  ax2.plot(pd.to_datetime(country_splitted_mobility[country]['date'])[N-1:], -1*pca_transformed[:, 1], color='blue', label='PC 1') #, linestyle='--'

    print(pca.components_)#explained_variance_ratio_)
    pca_all_r2_0 = r2_score(data[:-100], pca.inverse_transform(pca.transform(data[:-100])), multioutput = 'variance_weighted')
    pca_all_r2_1 = r2_score(data[-100:], pca.inverse_transform(pca.transform(data[-100:])), multioutput = 'variance_weighted')
    
    
    #print(pca_all_r2_0)

    ax2.set_ylabel('negative of SVD value')
    ax.legend(loc='lower left')
    ax2.legend(loc='lower right')

    plt.title(country + ' mobility PCA: smoothed with %s day mean, first 100 day R2 = %s, last 100 day R2 = %s' % (str(N), str(np.round(pca_all_r2_0, 2)), str(np.round(pca_all_r2_1, 2))))

    plt.savefig('mobility_pca/'+ country_name +'.jpg')
    plt.clf()



# %%



