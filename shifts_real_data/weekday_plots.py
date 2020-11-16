# %%
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

import os 

true_kernel = pd.read_csv('incubation_interval.csv')['pdf']# 'serial_interval.csv')['si']#'incubation_interval.csv')['pdf']
plt.style.use('ggplot')

weekday_dict = {0:'Monday', 1:'Tuesday', 2:'Wednesday', 3:'Thursday', 4:'Friday', 5:'Saturday', 6:'Sunday'}
for country in os.listdir('data'):

    if country != 'owid-covid-data.xlsx':
        country_data =  pd.read_csv('data/' + country)
     #   symptomatic_incidence =  SEIR_outputs['new_cases_per_million'].to_numpy()
        country_data['date'] = pd.to_datetime(country_data['date'])
        country_data['weekday'] = country_data['date'].dt.weekday
        country_data['date_index'] = range(len(country_data['date']))

        plt.figure(figsize=(20, 10))
        for weekday in range(7):
            plt.plot(country_data[country_data['weekday'] == weekday]['date_index'], country_data[country_data['weekday'] == weekday]['new_cases_per_million'], label=weekday_dict[weekday])
            
        plt.legend()
        plt.title(country.split('.')[0])
        plt.show()

plt.savefig('figures/'+ country.split('.')[0] + 'weekday.png')
