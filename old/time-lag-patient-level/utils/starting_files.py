import pandas as pd 
import numpy as np
from itertools import combinations
import matplotlib.pyplot as plt
from scipy.stats import normaltest, describe, iqr, linregress
import random
import os

# %%
def country_index(data, unique_countries):
    '''
    Finds the indexes of each country in data.
    Args:
        data: read from latestdata.csv (pd.DataFrame)
        unique_countries: countries of interest (pd.DataFrame)
    Returns:
        dictionary {country names (str): indices (various pd objects containing int)}
    '''
    data_lookup = {}
    data_lookup['Naive'] = data.index
    each_country_index = [data[data['country'] == country].index for country in unique_countries]
    for i, country_index in enumerate(each_country_index):
        data_lookup[unique_countries[i]] = country_index
    return data_lookup

def basic_comparisons(data, comparisons):
    '''
    Gets the indices where there exist values for both points in the comparison.
    Args:
        data: read from latestdata.csv or from a slice of it (pd.DataFrame).
        comparisons: pairwise comparisons, for example, ('date_onset_symptoms', 'date_admission_hospital') (tuple).
    Returns:
        indices (pd.Int64Index)
    '''
    cleared_data = data
    for comparison in comparisons:
        datetime_attempt = pd.to_datetime(cleared_data[comparison], format = "%d.%m.%Y", errors='coerce')
        datetime_success = datetime_attempt[~pd.isna(datetime_attempt)].index

        cleared_data = cleared_data.loc[datetime_success]

    return cleared_data.index 

def death_discharge_comparisons(data, other_comparison):
    '''
    Gets the indices where there exists a date of death or discharge AND a known outcome (death or discharge), AND the other comparison. 
    Args:
        data: read from latestdata.csv or from a slice of it (pd.DataFrame).
        other_comparison: for example, 'date_onset_symptoms'. (str)
    Returns:
        indices of death, indices of discharge (tuple(pd.Int64Index, pd.Int64Index))
    '''
    initial_i = basic_comparisons(data, (other_comparison, 'date_death_or_discharge'))
    death_discharge_data = data.loc[initial_i]

    datetime_attempt = pd.to_datetime(death_discharge_data['date_death_or_discharge'], format = "%d.%m.%Y")
    datetime_success = datetime_attempt[~pd.isna(datetime_attempt)].index
    death_discharge_data = death_discharge_data.loc[datetime_success]

    death_i = []
    discharge_i = []
    death_keystrings = ['death', 'die']
    discharge_keystrings = ['discharge', 'recover', 'release']

    for i, line in death_discharge_data.iterrows():
        outcome = str(line['outcome']).lower()
        found_death = False
        for keystr in death_keystrings:
            if outcome.find(keystr) != -1:
                death_i.append(i)
                found_death = True
                break
        if not found_death:
            for keystr in discharge_keystrings:
                if outcome.find(keystr) != -1:
                    discharge_i.append(i)
                    break
    return pd.Int64Index(death_i), pd.Int64Index(discharge_i)

def preprocess(data, c):
    '''
    Gets the cleaned time differences and mean dates. 
    Args:
        data: from a slice of latestdata.csv (pd.DataFrame).
        c: pairwise comparisons, for example, ('date_onset_symptoms', 'date_admission_hospital') (tuple).
    Returns:
        time differences in days (pd.Series(int)), mean days since 12-01-2019 (pd.Series(float)) (pd.DataFrame)
    '''

    comparisons = [comp.replace('date_death', 'date_death_or_discharge').replace('date_discharge', 'date_death_or_discharge') for comp in c]
    initial_date = pd.to_datetime("12-01-2019")
    first_comparison = pd.to_datetime(data[comparisons[0]], format = "%d.%m.%Y", errors='coerce') 
    second_comparison = pd.to_datetime(data[comparisons[1]], format = "%d.%m.%Y", errors='coerce') 
    
    mean_dates = (first_comparison-initial_date).dt.days#((second_comparison-initial_date).dt.days +(first_comparison-initial_date).dt.days)/2
    diff = (second_comparison-first_comparison).dt.days

    temp_df = pd.DataFrame()
    temp_df['diff'] = diff
    temp_df['mean_dates'] = mean_dates
    temp_df = temp_df.dropna(inplace=False)
    diff = temp_df['diff']
    mean_dates = temp_df['mean_dates']

    if len(diff) > 0:
        no_upper_extreme = diff[diff < np.quantile(diff, 0.75) + 3*iqr(diff)] 
    else: 
        no_upper_extreme = pd.Series()
    if len(no_upper_extreme) > 0:
        no_lower_extreme = no_upper_extreme[no_upper_extreme > np.quantile(no_upper_extreme, 0.25) - 3*iqr(no_upper_extreme)]
    else:
        no_lower_extreme = pd.Series()
    cleaned_mean_dates = mean_dates.loc[no_lower_extreme.index]

    output_df = pd.DataFrame()
    output_df['diff'] = no_lower_extreme
    output_df['mean_dates'] = cleaned_mean_dates
    return output_df