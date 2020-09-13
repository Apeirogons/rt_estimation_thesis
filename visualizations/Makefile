target: new_vs_total_cases new_case_and_mobility mobility_types

data:
	mkdir data

data/owid-covid-data.xlsx: data
	wget -O $@ https://covid.ourworldindata.org/data/owid-covid-data.xlsx

data/Global_Mobility_Report.csv: data
	wget -O $@ https://www.gstatic.com/covid19/mobility/Global_Mobility_Report.csv

initial_visualizations.py: requirements.txt
	pip install -r requirements.txt

new_vs_total_cases new_case_and_mobility mobility_types: initial_visualizations.py data/owid-covid-data.xlsx data/Global_Mobility_Report.csv
	python $<


