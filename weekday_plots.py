# %%
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

import os 


plt.style.use('ggplot')
plt.rcParams.update({'font.size': 22})

weekday_dict = {0:'Monday', 1:'Tuesday', 2:'Wednesday', 3:'Thursday', 4:'Friday', 5:'Saturday', 6:'Sunday'}
for country in ['Canada.csv', 'United States.csv']:


    if country != 'owid-covid-data.xlsx':
        country_data =  pd.read_csv('data/' + country)
     #   symptomatic_incidence =  SEIR_outputs['new_cases_per_million'].to_numpy()
        country_data['date'] = pd.to_datetime(country_data['date'])
        country_data['weekday'] = country_data['date'].dt.weekday
        country_data['date_index'] = range(len(country_data['date']))
    

        plt.figure(figsize=(20, 10))
        for weekday in range(7):
            plt.plot(country_data[country_data['weekday'] == weekday]['date'], country_data[country_data['weekday'] == weekday]['new_cases_per_million']+1, label=weekday_dict[weekday])
            
        plt.legend()
        plt.title(country.split('.')[0])
        plt.yscale('log')
        plt.xlabel('day')
        plt.ylabel('incidence')
        plt.savefig('figures/'+ country.split('.')[0] + '_weekday.png')
        
       # plt.show()



# %%
