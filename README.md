# COVID-math-thesis
Repository for code relating to my HTHSCI 4R09 thesis project, related to epidemic timeseries.

epidemic_timeseries contains all the mobility PCA, timeseries clustering, and phase planes. It's ready to run: Linux users should just type $make, and if you can't do that, just download the appropriate files (link in the Makefile) and run all the python scripts.

shifts contains code for the R(t) estimation idea. It's still very WIP right at the moment, and is a complete mess. I will fix it up during this coming week.

time_lag_old contains depreciated code. One idea was to determine the time lag distribution from a sort of deconvolution-based method (There are probably better methods than the crude one I came up with there), while another idea was to use publicly available patient-level data to come up with key epidemiological lags, which seemed like an okay approach.