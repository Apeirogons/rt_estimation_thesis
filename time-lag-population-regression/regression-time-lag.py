# To add a new cell, type '# %%'
# To add a new markdown cell, type '# %% [markdown]'
# %%
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import random as random
from scipy.stats import lognorm, gamma
from scipy.optimize import minimize, differential_evolution, curve_fit
from sklearn.metrics import r2_score
from sklearn.preprocessing import MinMaxScaler
import os
from lagutils import *

# %%
N=30
lag_names = ['Recoveries', 'Death']

###############
# This code splits the data by province into a dict
###############

case_timeseries = pd.read_csv('timeseries/cases_timeseries_prov.csv')
mortality_timeseries = pd.read_csv('timeseries/mortality_timeseries_prov.csv')
recovered_timeseries = pd.read_csv('timeseries/recovered_timeseries_prov.csv')

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
# TODO: convert main loop into functions
# TODO: put confidence intervals around stuff

for use_rolling in ['no-rolling', 'rolling-5day']:
    print('===================================================================')
    print('===================================================================')
    print('Starting data analysis: '+ use_rolling)
    print('===================================================================')
    print('===================================================================')
    if not os.path.exists(use_rolling):
        os.mkdir(use_rolling)

    for province_name in timeseries_by_province.keys():
        print('*************************************************************************')
        print(province_name)
        print('*************************************************************************')

        this_directory = use_rolling +'/'+ province_name
        if not os.path.exists(this_directory):
            os.mkdir(this_directory)

        province_data = timeseries_by_province[province_name]

        initial_plots(province_data, province_name, this_directory)
        xcorr_plots(province_data['cases'], province_data['deaths'], province_data['recovered'], N, save_dir=this_directory)

        if use_rolling == 'no-rolling':
            lagged_cases = generate_lagged_cases(province_data['cases'], N)

            regression_deaths = province_data['deaths'][N:]
            regression_recovered = province_data['recovered'][N:]
        elif use_rolling == 'rolling-5day':
            lagged_cases = generate_lagged_cases(province_data['cases'].rolling(5).mean(), N)

            regression_deaths = province_data['deaths'].rolling(5).mean()[N:]
            regression_recovered = province_data['recovered'].rolling(5).mean()[N:]

            lagged_cases[np.isnan(lagged_cases) ] = 0
            regression_deaths[np.isnan(regression_deaths)] = 0
            regression_recovered[np.isnan(regression_recovered)] = 0


        p0s = [(0.15432498188460625, -20.145200652501842, 41.717025008103434, 1), [0.1 for _ in range(N)]]
        all_bounds = [ [(0.01, -50, 0, 0), (5, 50, 50, 1)], [[0 for _ in range(30)], [1 for _ in range(N)]]]

        for i_lag_name, event_data in enumerate([regression_recovered, regression_deaths]):
            for i, function in enumerate([lognorm_function, distributionless_function]):
                try:
                    p = curve_fit(function, lagged_cases, event_data, p0 = p0s[i], bounds = all_bounds[i])

                    if i == 0:
                        print('===============================================================')
                        print('Using lognormal distribution ')
                        s, loc, scale, vscale = p[0]
                        xs = np.linspace(0, N, 1000)

                        plt.clf()
                        plt.xlabel('Time lag (days)')
                        plt.ylabel('Probability density')
                        plt.title('PDF of fitted time lag for ' + lag_names[i_lag_name])
                        plt.plot(xs, lognorm.pdf(xs, s, loc, scale))
                        plt.savefig(this_directory +'/' + lag_names[i_lag_name] + '-' + 'lognorm.png')
                       # plt.show()

                        with open(this_directory +'/' + lag_names[i_lag_name] + '-' + 'lognorm.txt', 'w') as L:
                            L.writelines('Fitted parameters: ' + '\n')
                            L.writelines('Sigma: ' + str(p[0][0])+ '\n')
                            L.writelines('Location: '+ str(p[0][1])+ '\n')
                            L.writelines('Scale: '+ str(p[0][2])+ '\n')
                            L.writelines('Vertical scale: '+ str(p[0][3])+ '\n')
                            L.writelines('Fitted mean: ' + str(lognorm.mean(s, loc, scale))+ '\n')
                            L.writelines('Fitted median: ' + str(lognorm.median(s, loc, scale))+ '\n')
                        dist = []
                        for i in range(N):
                            dist.append(lognorm.cdf(i+1, s, loc, scale)  - lognorm.cdf(i, s, loc, scale))
                        dist = np.asarray(dist)*vscale

                    elif i == 1:
                        print('===============================================================')
                        print('Using assumption of positive 0-1')
                        plt.clf()
                        plt.xlabel('Time lag (days)')
                        plt.ylabel('Regression Coefficient')
                        plt.title('Regression Coefficients of time lag for ' + lag_names[i_lag_name])
                        dist = p[0]
                        plt.plot(dist)
                        plt.savefig(this_directory +'/' + lag_names[i_lag_name] + '-' + 'positive.png')
                      #  plt.show()


                        with open(this_directory +'/' + lag_names[i_lag_name] + '-' + 'positive.txt', 'w') as L:
                            L.writelines('Coefficient list: ')
                            for x in p[0]:
                                L.writelines(str(x) + '\n')

                    plot_predictions(lagged_cases, event_data, dist, lag_names[i_lag_name], this_directory)

                except RuntimeError:
                    print('Error: cannot fit function')


# %%



