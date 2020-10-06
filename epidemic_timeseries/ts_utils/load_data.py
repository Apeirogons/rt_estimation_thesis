import pandas as pd

def import_owid(location='../data/owid-covid-data.xlsx'):
	original_data = pd.read_excel(location)
	unique_countries = list(set(original_data['location']))
	country_splitted_data = {}
	for country in unique_countries:
	    country_data = original_data[original_data['location']==country]
	    country_data['date'] = pd.to_datetime(country_data['date'])
	    country_data = country_data[['date', 'total_cases_per_million', 'new_cases_per_million', 'total_deaths_per_million', 'new_deaths_per_million', 'total_tests_per_thousand', 'new_tests_per_thousand']]
	    country_splitted_data[country] = country_data
	return country_splitted_data
	
	
def import_mobility(location='../data/Global_Mobility_Report.csv'):
	mobility_data = pd.read_csv(location)
	unique_mobility_countries = list(set(mobility_data['country_region']))
	country_splitted_mobility = {}
	for country in unique_mobility_countries:
	    country_data = mobility_data[mobility_data['country_region']==country]
	    country_data['date'] = pd.to_datetime(country_data['date'])
	    country_data = country_data[pd.isna(country_data['sub_region_1']) &pd.isna(country_data['sub_region_2']) & pd.isna(country_data['metro_area'])]
	    country_splitted_mobility[country] = country_data
	return country_splitted_mobility

def import_both(location_owid = '../data/owid-covid-data.xlsx', location_mobility = '../data/Global_Mobility_Report.csv'):

	original_data = pd.read_excel(location_owid)
	mobility_data = pd.read_csv(location_mobility)
	unique_countries = list(set(original_data['location']).intersection(set(mobility_data['country_region'])))

	country_splitted_data = {}
	for country in unique_countries:

		country_data = original_data[original_data['location']==country]
		country_data['date'] = pd.to_datetime(country_data['date'])
		country_data = country_data[['date', 'total_cases_per_million', 'new_cases_per_million', 'total_deaths_per_million', 'new_deaths_per_million', 'total_tests_per_thousand', 'new_tests_per_thousand']]


		cmobility_data = mobility_data[mobility_data['country_region']==country]
		cmobility_data['date'] = pd.to_datetime(cmobility_data['date'])
		cmobility_data = cmobility_data[pd.isna(cmobility_data['sub_region_1']) &pd.isna(cmobility_data['sub_region_2']) & pd.isna(cmobility_data['metro_area'])]


		# align pandemics to pandemic start points
		all_country_data = pd.merge(country_data, cmobility_data, on='date')
		for i, day in all_country_data.iterrows():
			if day['total_cases_per_million'] > 0:
				pandemic_start = i
				break

		all_country_data = all_country_data.iloc[pandemic_start:]
		country_splitted_data[country] = all_country_data
	return country_data