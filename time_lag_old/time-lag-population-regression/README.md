This repo tries to determine the distribution of time lags between events using linear regression, but with the regression parameters forced to conform to a lognormal distribution.

If using linux, run:

make

Otherwise, 
Data in /timeseries comes from this source:
https://github.com/ishaberry/Covid19Canada

To use, run regression-time-lag.py. 


The no-rolling folder regresses against non-smoothed data, the rolling-5day folder regresses against the 5-day rolling average.

More documentation will be added later.
