import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import minimize, dual_annealing, basinhopping
import os 
from scipy.fftpack import rfft, irfft, fftfreq, fft, ifft
#from scipy.special import gamma

import pywt

def wavelet_filter(symptomatic_incidence, wavelet='sym2', cutoff=15, k=5 ):
    dec = [np.asarray(x) for x in pywt.wavedec(symptomatic_incidence, wavelet)]

    for i, _ in enumerate(dec):
        x = np.abs(dec[i])
        filt = 1 - np.exp(-k*(x-cutoff))/(1+np.exp(-k*(x-cutoff)))
        dec[i] *= filt
    rec = pywt.waverec(dec, wavelet)
    return rec

def wavelet_lp_filter(symptomatic_incidence, c, wavelet='sym2'):
    cutoff = int(c)
    dec = [np.asarray(x) for x in pywt.wavedec(symptomatic_incidence, wavelet)]
    print('There are ' + str(len(dec)) + ' levels.')
    for i in range(cutoff, len(dec)):
        dec[i] *= 0

    rec = pywt.waverec(dec, wavelet)
    return rec

def fft_filter(symptomatic_incidence, cutoff, k=5):
    freqs= fftfreq(len(symptomatic_incidence))# frequencies in 1/day
    periods = 1/freqs
    x = np.abs(periods)

    filt = 1 - np.exp(-k*(x-cutoff))/(1+np.exp(-k*(x-cutoff)))

    filtered = rfft(symptomatic_incidence)*filt

    reconstructed = irfft(filtered)
    return reconstructed


#def shift(arr, num):
#    return np.concatenate([arr[-num:], arr[num:]])


def opt_deconv(symptomatic_incidence, true_kernel, a=1E7,  degree=2):
    def cobey_callback(real_incidence, unused):
        L = len(true_kernel) - 1
        convolved = np.convolve(real_incidence, true_kernel, mode='valid')
        scaled_convolved = convolved# *1000000 
        scaled_incidence = symptomatic_incidence[L:] #*1000000 
        chi2 =  np.sum((scaled_incidence - scaled_convolved)**2/(scaled_convolved))/len(scaled_incidence)

        return chi2 <= 1
    def optimizer_function(real_incidence):
        L = len(true_kernel) - 1

        convolved = np.convolve(real_incidence, true_kernel, mode='valid')
        scaling = np.max(symptomatic_incidence[L:])

        scaled_convolved = convolved# *1000000 
        scaled_incidence = symptomatic_incidence[L:] #*1000000 


        penalty = a * np.sum(np.abs(np.diff(real_incidence)/scaling/len(real_incidence))**degree)

        loglikelihoods = scaled_incidence*np.log(scaled_convolved) - scaled_convolved

        return -np.mean(loglikelihoods)+penalty


    mean_shift = np.sum((np.arange(len(true_kernel)))* true_kernel)
    starting_shift = int(np.round(mean_shift))

    x0 = shift(symptomatic_incidence, -1*starting_shift)

    xs = minimize(optimizer_function, x0, bounds = [(0, np.inf) for _ in x0],options={'maxiter':10000}, method='Powell')
    return xs




def wiener_deconvolution(signal, kernel, lambd):
	"lambd is the SNR"
	kernel = np.hstack((kernel, np.zeros(len(signal) - len(kernel)))) # zero pad the kernel to same length
	H = fft(kernel)
	deconvolved = np.real(ifft(fft(signal)*np.conj(H)/(H*np.conj(H) + lambd**2)))
	return deconvolved
