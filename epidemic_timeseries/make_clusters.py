# To add a new cell, type '# %%'
# To add a new markdown cell, type '# %% [markdown]'
# %%
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os
from sklearn.preprocessing import StandardScaler
from ts_utils.load_data import *

# %%

# all_country_data = import_both('../data/owid-covid-data.xlsx', '../data/Global_Mobility_Report.csv')
country_splitted_data = import_owid('data/owid-covid-data.xlsx')

countries_of_interest = ['South Korea', 'United States', 'Canada', 'United Kingdom', 'Germany', 'Japan', 'France', 'Italy', 'China', 'India']


# %%
def quickplot(country_0, country_1, target_0, use_scaled=False):
    countries_of_interest = list(country_splitted_data.keys())

    fig, ax = plt.subplots()

    data_0 = country_splitted_data[country_0][target_0]
    data_0 = data_0.fillna(method='bfill')
    data_0 = data_0.to_numpy()
    if use_scaled:
        data_0 = StandardScaler().fit_transform(np.expand_dims(data_0,axis=-1))

    print(country_0)
    ax.plot(data_0, label=country_0 + ' ' +target_0 + '(red)', color='red')

    data_1 = country_splitted_data[country_1][target_0]
    data_1 = data_1.fillna(method='bfill')
    data_1 = data_1.to_numpy()
    if use_scaled:
        data_1 = StandardScaler().fit_transform(np.expand_dims(data_1,axis=-1))
    #country = countries_of_interest[2]

    print(country_1)
    ax.plot(data_1, label=country_1 + ' ' +target_0 + '(red)', color='blue')

    every_nth = 2
    for n, label in enumerate(ax.xaxis.get_ticklabels()):
        if n % every_nth != 0:
            label.set_visible(False)

    plt.xlabel('Date')
    ax.set_ylabel(target_0 + ' (red)')

    plt.legend()
    plt.title('New cases')

    plt.show()


# %%
target_0 = 'new_cases_per_million'#'total_cases_per_million' works!

##'transit_stations_percent_change_from_baseline' 
all_splitted_data = []
utilized_keys = []
for key in list(country_splitted_data.keys()):
    pd_obj = (country_splitted_data[key][target_0]).fillna(method='bfill')
    pd_obj = pd_obj.rolling(7).mean()
    pd_obj = pd_obj.dropna()
    if len(pd_obj) > 100:
        all_splitted_data.append(StandardScaler().fit_transform(np.expand_dims(pd_obj.to_numpy(), axis=-1)))
        utilized_keys.append(key)


# %%
from random import sample
splitted_i = np.asarray(sample(list(range(len(all_splitted_data))), 60))
all_splitted_data = np.asarray(all_splitted_data)[splitted_i]
randomized_keys = [utilized_keys[i] for i in splitted_i]
randomized_keys


# %%
from fastdtw import fastdtw
from itertools import combinations
all_distances = np.zeros((len(all_splitted_data),len(all_splitted_data)))

indice_combinations = list(combinations(range(len(all_splitted_data)), 2))
print('Number of combinations:' + str(len(indice_combinations)))

counter = 0
for I in indice_combinations:
    data_0 = all_splitted_data[I[0]]
    data_1 = all_splitted_data[I[1]]
 #   print([list(country_splitted_data.keys())[x] for x in I])
    distance, path = fastdtw(data_0, data_1)
    all_distances[I[0], I[1]] = distance
    all_distances[I[1], I[0]] = distance
    counter += 1
    if counter % 100 == 0:
       print(counter)


# %%
from sklearn.cluster import DBSCAN, AffinityPropagation

KM = DBSCAN(eps=np.mean(all_distances)/6, metric='precomputed', min_samples=2)
#AffinityPropagation(damping=0.7, affinity='precomputed')

#AgglomerativeClustering(affinity='precomputed', linkage='complete')
#AffinityPropagation(affinity='precomputed')


#DBSCAN(eps=np.mean(all_distances)/7, metric='precomputed')#SpectralClustering(affinity='precomputed')

#SpectralClustering(affinity='precomputed')#

predictions = KM.fit_predict(all_distances)
predictions


# %%

if not os.path.exists('outputs/epidemic_cluster'):
    os.mkdir('outputs/epidemic_cluster')

for i in range(max(predictions)+1):
    plt.title('Similar epidemic curves determined by clustering: cluster ' + str(i))
    plt.ylabel('Incident cases Z-score')
    plt.xlabel('Days since outbreak start')
    for x in np.asarray(all_splitted_data)[predictions==i][:5]:
        plt.plot(x)
    plt.savefig('outputs/epidemic_cluster/cluster '+ str(i) + '.png')
    plt.close()
#    plt.show()
#plt.plot(all_splitted_data[2])


