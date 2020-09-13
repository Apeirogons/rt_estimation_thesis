import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import random as random
from scipy.stats import lognorm, gamma
from scipy.optimize import minimize, differential_evolution, curve_fit
from sklearn.metrics import r2_score
from sklearn.preprocessing import MinMaxScaler
import os
from uncertainties import ufloat


def generate_lagged_cases(cases, N):
    """
    Given a Pandas Series of cases, return sliding windows of the last N days of cases before it.
    Args:
        cases (pd.Series)
        N (int)
    Returns:
        np.ndarray
    """
    return np.asarray([cases[i:i+N:][::-1] for i, _ in enumerate(cases[:-N])])

def lognorm_function(x_data, s, loc, scale, vscale):
    """
    Gets each day's regression prediction given the lognormal parameters (s, loc, scale) and the vertical scaling parameter (vscale)
    TODO: fix this N1=30 here
    Args:
        x_data (np.ndarray): returned from generate_lagged_cases
        s (float)
        loc (float)
        scale (float)
        vscale (float)
    Returns:
        int
    """
    N1 = 30
    dist = []
    for i in range(N1):
        dist.append(lognorm.cdf(i+1,  s, loc, scale)  - lognorm.cdf(i,  s, loc, scale))
    dist = np.asarray(dist)*vscale

    predicted = np.asarray([np.sum(dist*x) for x in x_data])
    return predicted

def distributionless_function(x_data, *ds):
    """
    Gets each day's regression prediction given the regression coefficients for each day. 
    Args:
        x_data (np.ndarray): returned from generate_lagged_cases
        *ds: regression coefficients
    Returns:
        int
    """
    d = np.asarray(ds)
    predicted = np.asarray([np.sum(d*x) for x in x_data])
    return predicted

def initial_plots(province_data, province_name, save_dir = None):
    """
    Plots the number of cases vs days and plots the 5-day rolling average of cases, deaths, and recoveries.
    Args:
        province_data (pd.DataFrame)
        province_name (str), for example "Ontario"
    """
    plt.clf()
    plt.xlabel('Day Index')
    plt.ylabel('Number of cases')
    plt.title('Number of cases vs day index for ' + province_name)
    plt.plot(province_data['cases'])

    if not (save_dir is None):
        plt.savefig(save_dir +'/' + 'cases-plot.png')
  #  plt.show()

    plt.clf()
    plt.xlabel('Day Index')
    plt.ylabel('Proportion of maximal events')
    plt.title('5-day rolling average of events for ' + province_name)
    plt.plot(MinMaxScaler().fit_transform(np.expand_dims(province_data['cases'].rolling(5).mean(), axis=1)), label = 'Cases', alpha=0.75)
    plt.plot(MinMaxScaler().fit_transform(np.expand_dims(province_data['deaths'].rolling(5).mean(), axis=1)), label = 'Deaths', alpha=0.75)
    plt.plot(MinMaxScaler().fit_transform(np.expand_dims(province_data['recovered'].rolling(5).mean(), axis=1)), label = 'Recovered', alpha=0.75)
    plt.legend()
    if not (save_dir is None):
        plt.savefig(save_dir +'/' + 'events-plot.png')
  #  plt.show()


def xcorr_plots(cases, deaths, recoveries, N=30, save_dir = None):
    """
    Plots the cross-correlation between the cases and events
    Args:
        cases (pd.Series): number of new cases per day
        deaths (pd.Series): number of new deaths per day
        recoveries (pd.Series): number of new recoveries per day
    """
    plt.clf()
    plt.title('Cross correlation of cases to deaths')
    plt.xcorr(cases.to_numpy().astype('float32'), deaths.astype('float32').to_numpy(), normed=True, maxlags=N)
    if not (save_dir is None):
        plt.savefig(save_dir +'/' + 'xcorr-deaths.png')
  #  plt.show()
    plt.clf()
    plt.title('Cross correlation of cases to recoveries')
    plt.xcorr(cases.to_numpy().astype('float32'), recoveries.astype('float32').to_numpy(), normed=True, maxlags=N)
    if not (save_dir is None):
        plt.savefig(save_dir +'/' + 'xcorr-recoveries.png')
   # plt.show()


def plot_predictions(lagged_cases, actual_cases, dist, lag_name, save_dir = None):
    """
    Plots the outputted predictions
    Args:
        lagged_cases (np.ndarray): returned from generate_lagged_cases
        actual_cases (np.ndarray/pd.Series): the event of choice, for example, recoveries or deaths
        dist (np.ndarray): regression coefficients for each day of lag
        lag_name (str): The type of lag (ex. "Cases to deaths")
    """
    plt.clf()
    predicted = np.asarray([np.sum(dist*x) for x in lagged_cases])
    plt.xlabel('Date Index')
    plt.ylabel('Number of '+ lag_name)
    plt.title('Predicted and actual '+ lag_name)
    plt.plot(predicted, color='red', label = 'Predictions')
    plt.plot(actual_cases.to_numpy(), color='blue', label = 'Actual', alpha=0.75)
    plt.legend()
    if not (save_dir is None):
        plt.savefig(save_dir +'/' + lag_name +'-predictions.png')
  #  plt.show()
    print('R^2: ' + str(r2_score(actual_cases.to_numpy(), predicted)))
