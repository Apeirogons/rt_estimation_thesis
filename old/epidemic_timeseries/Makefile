target: outputs/epidemic_cluster.out outputs/pca.out outputs/ts_plots.out outputs/ps.out

data:
	mkdir data

outputs:
	mkdir outputs

requirements.out: requirements.txt
	pip install -r requirements.txt > requirements.out

data/owid-covid-data.xlsx: data
	wget -O $@ https://covid.ourworldindata.org/data/owid-covid-data.xlsx

data/Global_Mobility_Report.csv: data
	wget -O $@ https://www.gstatic.com/covid19/mobility/Global_Mobility_Report.csv

pc_out = outputs/pca.out
outputs/grand_pca.pickle outputs/reconstructions ${pc_out}: create_pca_mobility_index.py requirements.out outputs
	python $< > ${pc_out}
	touch ${pc_out}

ts_out = outputs/ts_plots.out
outputs/ts_plots ${ts_out}: timeseries_visualization.py requirements.out outputs 
	python $< 
	touch ${ts_out}

ps_out = outputs/ps.out
outputs/phase_plane: phase_plane_visualization.py requirements.out outputs
	python $< 
	touch ${ps_out}

cluster_out = outputs/epidemic_cluster.out
outputs/epidemic_cluster ${cluster_out}: make_clusters.py requirements.out outputs
	python $< > ${cluster_out}
	touch ${cluster_out}


