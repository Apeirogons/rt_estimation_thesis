# To add a new cell, type '# %%'
# To add a new markdown cell, type '# %% [markdown]'
# %%
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import minimize, dual_annealing
from sklearn.metrics import r2_score
import os


# %%
if not os.path.exists('figures'):
    os.mkdir('figures')


# %%

case_timeseries = pd.read_csv('data/timeseries_prov/cases_timeseries_prov.csv')
mortality_timeseries = pd.read_csv('data/timeseries_prov/mortality_timeseries_prov.csv')
recovered_timeseries = pd.read_csv('data/timeseries_prov/recovered_timeseries_prov.csv')

mortality_timeseries = mortality_timeseries.rename(columns={'date_death_report':'date_report'})
recovered_timeseries = recovered_timeseries.rename(columns={'date_recovered':'date_report'})

unique_provinces = case_timeseries['province'].drop_duplicates(inplace=False).tolist()
unique_provinces.remove('Repatriated')

timeseries_by_province = {}
for province in unique_provinces:
    filtered_case = [ts[ts['province'].str.contains(province)] for ts in [case_timeseries, mortality_timeseries, recovered_timeseries]]
    t = filtered_case[0]
    for ts in filtered_case[1:]:
        for col in ts:
            if col in t.columns and col != 'date_report':
                ts = ts.drop(columns=[col]) 
        t = pd.merge(t, ts, on='date_report')

    timeseries_by_province[province] = t


# %%
def optimizer_function(k, target_0, target_1, diff_penalty=10):
    # other priors I could put in:
    # regularization
    # smoothness
    # long right tail

    scale = k[-1]

    kernel = np.concatenate([[0], k[:-1]], axis=0)

    convolved = np.convolve(target_0,kernel/np.sum(kernel)*scale,  mode='valid')

    return np.mean((convolved - target_1[(len(kernel)-1):])**2) + np.sum(np.diff(kernel/np.sum(kernel))**2)*diff_penalty * np.mean(target_1[(len(kernel)-1):]**2) 


# %%
for province in timeseries_by_province.keys():

    if np.mean(timeseries_by_province[province]['cases']) > 20:
        print(province)            

        daily_cases = timeseries_by_province[province]['cases'].rolling(7).mean().dropna().to_numpy()
        daily_recovered = timeseries_by_province[province]['recovered'].rolling(7).mean().dropna().to_numpy()
        daily_death = timeseries_by_province[province]['deaths'].rolling(7).mean().dropna().to_numpy()


        x0 = np.concatenate([[0], np.ones(shape=(50,))], axis=0)
        x0 /= np.sum(x0)

        xs = minimize(optimizer_function, x0, bounds = [[0, 1] for _ in x0], args=(daily_cases, daily_recovered, 1))#recovered))

        kernel = xs.x[:-1]/np.sum(xs.x[:-1]) * xs.x[-1]
        kernel = np.concatenate([[0], kernel], axis=0)
        reconstruction = np.convolve(kernel, daily_cases, mode='valid')
        daily_dates =  timeseries_by_province[province]['date_report'][7-1:][(len(kernel)-1):]


        r2 = r2_score(daily_recovered[(len(kernel)-1):], reconstruction)
        plt.figure(figsize=(10, 5))
        plt.plot(kernel, label='estimated kernel')
        plt.title('Estimated recovery time lags for '+ province + ', Reconstruction R2='+ str(round(r2, 2)))
        plt.xlabel('Days since infection/appearance of symptoms')
        plt.ylabel('Probability of recovery')
        plt.savefig('figures/'+province+'-estimated-recovery-kernel.png')
        plt.clf()
        

        plt.plot(reconstruction, label='convolved recovered')

        plt.plot(daily_recovered[(len(kernel)-1):], label='true recovered')
        plt.plot(daily_cases[(len(kernel)-1):], label='incident cases')
        plt.title('Reconstruction of recovery curve, Reconstruction R2='+ str(round(r2, 2)))
        plt.xlabel('Days since ' + str(daily_dates.iloc[0]))
        plt.ylabel('Incidence/Recovered smoothed over 7 days')
        plt.legend()
        plt.savefig('figures/'+ province + '-reconstructed-convolved.png')

        plt.clf()


