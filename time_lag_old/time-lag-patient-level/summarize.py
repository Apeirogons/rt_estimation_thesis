# To add a new cell, type '# %%'
# To add a new markdown cell, type '# %% [markdown]'
# %%
# Generates statistical summaries, boxplots, QQ plots, and plots a linear regression with date on x-axis and time lag on y-axis.

# %%
from utils.analysis import *
import pandas as pd 
import numpy as np
from itertools import combinations
import matplotlib.pyplot as plt
from statsmodels.graphics.gofplots import qqplot
from scipy.stats import normaltest, describe, iqr, linregress, mannwhitneyu
import random
import os


# %%
with open('categories_list.txt', 'r') as cat:
    categories_of_interest = eval(cat.read())


# %%
differenced_data = read_data('differenced_data')


# %%
p0 = differenced_data[('date_admission_hospital', 'date_discharge')]['China']['diff']
p1 = differenced_data[('date_admission_hospital', 'date_death')]['China']['diff']

print(mannwhitneyu(p0, p1))

# %%
if not os.path.exists('distributions'):
    os.mkdir('distributions')
if not os.path.exists('trends'):
    os.mkdir('trends')

total_df = pd.DataFrame()


for country in differenced_data[categories_of_interest[0]].keys():
    fused_df = pd.DataFrame()
    this_country_data = []
    added_something = False
    print(country)

    for i, category in enumerate(differenced_data.keys()):
        diff = differenced_data[category][country]['diff']
        mean_dates = differenced_data[category][country]['mean_dates']
        mean_dates = mean_dates[diff > 0]
        diff = diff[diff > 0]

        if len(diff) > 20:
            added_something = True

            fused_df['country'] = [country] 
            s = summarize(diff, category, save_values='distributions/'+ country.replace(' ', '-'),show=False)
            generate_qqplot(diff, category, save_values='distributions/'+country.replace(' ', '-'), show=False)
            t = trend(diff, mean_dates, category, save_values='trends/'+country.replace(' ', '-'), show=False)
            
            for i_c, col in s.iteritems():
                fused_df[i_c+'_'+str(category)] = col
            for i_c, col in t.iteritems():
                fused_df[i_c+'_'+str(category)] = col

    total_df = total_df.append(fused_df, ignore_index=True)


# %%
# Save important summary data in one spreadsheet
if not os.path.exists('aggregate_distributions'):
    os.mkdir('aggregate_distributions')

total_df.to_csv('aggregate_distributions/all_data.csv')

# Plot all the boxplots on one image (however, do not show the outliers which mess up scaling)
for category in categories_of_interest:
    non_blank_data = []
    non_blank_countries = []
    for ic, country_name in enumerate(differenced_data[category].keys()):
        country_data = differenced_data[category][country_name]['diff']
        country_data = country_data[country_data> 0]
        if len(country_data) >= 20:
            non_blank_data.append(country_data)
            non_blank_countries.append(country_name[:4])
    fig, ax = plt.subplots()
    ax.set_title('Days between '+category[0] + ' and '+category[1])
    ax.set_ylabel('Days')

    ax.boxplot(non_blank_data, showfliers=False)
    ax.set_xticklabels(non_blank_countries)
    plt.savefig('aggregate_distributions/'+category[0] + '-'+category[1]+'.png')


# %%
if not os.path.exists('aggregate_trends'):
    os.mkdir('aggregate_trends')

for category in categories_of_interest:
    CI_mins = []
    CI_maxes = []
    countries = []
    for country_name, country in total_df.iterrows():
        for column in total_df.columns:
            if column == 'slope_ci_max_'+ str(category):
                CI_max = country[column]
            elif column == 'slope_ci_min_' + str(category):
                CI_min = country[column]
        if not(np.isnan(CI_min) or np.isnan(CI_max)):
            CI_mins.append(CI_min)
            CI_maxes.append(CI_max)
            countries.append(country['country'])
        

    mean_CI = np.asarray([(CI_mins[i] + CI_maxes[i])/2 for i, _ in enumerate(CI_maxes)])
    err_CI = mean_CI - np.asarray(CI_mins)

    fig, ax = plt.subplots()
    ax.set_title('Change in time lag in '+ category[0] + ' and '+category[1])
    ax.set_ylabel('Country')
    ax.set_xlabel('Slope')
    plt.yticks([i for i in range(len(mean_CI))], [x[:5] for x in countries])
    plt.axvline()
    ax.barh(y = [i for i in range(len(mean_CI))], height = 1, width = mean_CI, xerr = err_CI, alpha=0)

    plt.savefig('aggregate_trends/'+category[0] + '-'+category[1]+'.png')

    


# %%


write_lines = []

for category in categories_of_interest:
    write_lines.append('---------------------------------')
    write_lines.append(str(category))
    write_lines.append(' ')

    non_blank_data = []
    non_blank_countries = []
    country_names = differenced_data[category].keys()

    for ic, country_name in enumerate(differenced_data[category].keys()):
        country_data = differenced_data[category][country_name]['diff']
        country_data = country_data[country_data> 0]
        if len(country_data) >= 20:
            non_blank_data.append(country_data)
            non_blank_countries.append(country_name)
    data_combinations = list(combinations(non_blank_data, 2))
    country_combinations = list(combinations(non_blank_countries, 2))
    
    for i, combination in enumerate(data_combinations):
        test = mannwhitneyu(combination[0], combination[1])
        if test.pvalue < 0.05:
            write_lines.append(str(country_combinations[i]) + ' ' + str(test.pvalue))

with open('significant_differences.txt', 'w') as s:
    s.writelines([x + '\n' for x in write_lines])

# %%
