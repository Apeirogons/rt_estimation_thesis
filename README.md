# COVID-math-thesis
Repository for code relating to my HTHSCI 4R09 thesis project, related to epidemic timeseries.

Current project: R(t) estimation, in the shifts_combined folder.
Data from https://ourworldindata.org/coronavirus.

older stuff that isn't being visited immediately:
time_lag_old contains deprecated code. One idea was to use publicly available patient-level data to come up with key epidemiological lags, which seemed like an okay approach.
lag_estimation_revisited revisits an old idea of determining the time lag distribution by finding convolutions that plausibly explained the distance between two curves. To run the code, run shifts/estimate_2.R, and run the two .py files in lag_estimation_revisited. I may update the makefile for this next week, depending on whether or not we intend on revisiting this.
data from https://github.com/ishaberry/Covid19Canada.
epidemic_timeseries contains all the mobility PCA, timeseries clustering, and phase planes. It's ready to run: Linux users should just type $make, and if you can't do that, just download the appropriate files (link in the Makefile) and run all the python scripts.
