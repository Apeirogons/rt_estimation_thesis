SHELL := /bin/bash
all: requirements.out setup_download Makefile active_timeseries_prov.csv cases_timeseries_prov.csv mortality_timeseries_prov.csv recovered_timeseries_prov.csv testing_timeseries_prov.csv regression-time-lag.out rm_out

requirements.out: requirements.txt
	pip3 install -r $< > $@

setup_download:
	if [[ ! -d timeseries ]]; then mkdir timeseries; fi

Makefile: requirements.out 

active_timeseries_prov.csv: 
	wget -O timeseries/$@ "https://raw.githubusercontent.com/ishaberry/Covid19Canada/master/timeseries_prov/active_timeseries_prov.csv"

cases_timeseries_prov.csv: 
	wget -O timeseries/$@ "https://raw.githubusercontent.com/ishaberry/Covid19Canada/master/timeseries_prov/cases_timeseries_prov.csv"

mortality_timeseries_prov.csv: 
	wget -O timeseries/$@ "https://raw.githubusercontent.com/ishaberry/Covid19Canada/master/timeseries_prov/mortality_timeseries_prov.csv"

recovered_timeseries_prov.csv: 
	wget -O timeseries/$@ "https://raw.githubusercontent.com/ishaberry/Covid19Canada/master/timeseries_prov/recovered_timeseries_prov.csv"

testing_timeseries_prov.csv: 
	wget -O timeseries/$@ "https://raw.githubusercontent.com/ishaberry/Covid19Canada/master/timeseries_prov/testing_timeseries_prov.csv"

regression-time-lag.out: active_timeseries_prov.csv cases_timeseries_prov.csv mortality_timeseries_prov.csv recovered_timeseries_prov.csv testing_timeseries_prov.csv
	python regression-time-lag.py > $@

# Remove temp files
rm_out: regression-time-lag.out requirements.out
	rm regression-time-lag.out
	rm requirements.out