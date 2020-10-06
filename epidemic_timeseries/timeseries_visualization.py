# %%

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os
from ts_utils.load_data import *

N=7


if not os.path.exists('outputs/ts_plots'):
    os.mkdir('outputs/ts_plots')

if not os.path.exists('outputs/ts_plots/new_vs_total_cases'):
    os.mkdir('outputs/ts_plots/new_vs_total_cases')

if not os.path.exists('outputs/ts_plots/mobility_types'):
    os.mkdir('outputs/ts_plots/mobility_types')

if not os.path.exists('outputs/ts_plots/new_case_and_mobility'):
    os.mkdir('outputs/ts_plots/new_case_and_mobility')

country_splitted_data = import_owid('data/owid-covid-data.xlsx')

country_splitted_mobility = import_mobility('data/Global_Mobility_Report.csv')


countries_of_interest = ['South Korea', 'United States', 'Canada', 'United Kingdom', 'Germany', 'Japan', 'France', 'Italy', 'China', 'India']

target_0 = 'new_cases_per_million'
target_1 = 'total_cases_per_million'

for country in countries_of_interest:

    fig, ax = plt.subplots()

    ax.plot(pd.to_datetime(country_splitted_data[country]['date']), country_splitted_data[country][target_0], label=country + ' ' +target_0 + '(red)', color='red')

    # code from stack-overflow to reduce crowding on x-axis
    every_nth = 2
    for n, label in enumerate(ax.xaxis.get_ticklabels()):
        if n % every_nth != 0:
            label.set_visible(False)

    plt.xlabel('Date')
    ax.set_ylabel(target_0 + ' (red)')

    ax2 = ax.twinx()

    ax2.plot(pd.to_datetime(country_splitted_data[country]['date']), country_splitted_data[country][target_1], label=country + ' ' +target_1 +'(blue)', color='blue')
    plt.title('New vs cumulative cases in ' + country)
    ax2.set_ylabel(target_1 + ' (blue)')

    plt.savefig('outputs/ts_plots/new_vs_total_cases/'+ country+'.png')
    plt.close()

if 'China' in countries_of_interest:
    countries_of_interest.remove('China')
    


target_0 = 'new_cases_per_million'
target_1 = 'transit_stations_percent_change_from_baseline'

for country in countries_of_interest:

    fig, ax = plt.subplots()

    ax.plot(pd.to_datetime(country_splitted_data[country]['date']), country_splitted_data[country][target_0].rolling(N).mean(), label=country + ' ' +target_0 + '(red)', color='red')

    # code from stack-overflow to reduce crowding on x-axis
    every_nth = 2
    for n, label in enumerate(ax.xaxis.get_ticklabels()):
        if n % every_nth != 0:
            label.set_visible(False)

    plt.xlabel('Date')
    ax.set_ylabel(target_0 + ' (red)')

    ax2 = ax.twinx()

    ax2.plot(pd.to_datetime(country_splitted_mobility[country]['date']), country_splitted_mobility[country][target_1].rolling(N).mean(), label=country + ' ' +target_1 +'(blue)', color='blue')
    plt.title('New cases and mobility (both %s-day smoothed) ' %str(N) + country)
    ax2.set_ylabel(target_1 + ' (blue)')

    plt.savefig('outputs/ts_plots/new_case_and_mobility/'+ country+'.png')
    #plt.show()
    plt.close()

if 'China' in countries_of_interest:
    countries_of_interest.remove('China')



targets = ['retail_and_recreation_percent_change_from_baseline', 'grocery_and_pharmacy_percent_change_from_baseline', 'parks_percent_change_from_baseline', 'transit_stations_percent_change_from_baseline', 'workplaces_percent_change_from_baseline', 'residential_percent_change_from_baseline']

for country in countries_of_interest:
    fig, ax = plt.subplots()
    for target in targets:
        ax.plot(pd.to_datetime(country_splitted_mobility[country]['date']), country_splitted_mobility[country][target].rolling(N).mean(), label= "_".join(target.split('_')[:-4]))
    ax.set_ylabel('Mobility %change from baseline')

    # code from stack-overflow to reduce crowding on x-axis
    every_nth = 2
    for n, label in enumerate(ax.xaxis.get_ticklabels()):
        if n % every_nth != 0:
            label.set_visible(False)

    plt.xlabel('Date')
    plt.title(country + ' date vs mobility: smoothed with %s day mean' % str(N))
    ax.legend()
    plt.savefig('outputs/ts_plots/mobility_types/'+ country+'.png')
    plt.close()
# %%
