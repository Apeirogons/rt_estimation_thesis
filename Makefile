target: main.pdf 

#r = Rscript
r = C:\Users\somat\Documents\R\R-4.0.2\bin\Rscript.exe

logs/logs.out logs data:
	mkdir logs
	mkdir data
	echo Logs folder created > logs/logs.out 

logs/requirements.out: requirements.txt logs/logs.out
	pip install -r $< > $@

logs/data_splitter.out: data_splitter.py logs/requirements.out
	python $< > $@


#############################################################################################################3
logs/seir.out seir : run_simulation.R ts_utils/deterministic_simulation.R base_params.R ggplot_params.R logs/logs.out
	$r $< > $@

logs/smoothing_figures.out: smoothing_figures.R ts_utils/filter.R logs/seir.out
	$r $< > $@

logs/smoothing_figures_extra.out: smoothing_figures_extra.R logs/seir.out
	$r $< > $@

logs/rt_estim.out: rt_estim.R ts_utils/rt.R logs/seir.out 
	$r $< > $@

logs/variants_mli.out: variants_mli.R 
	$r $< > $@

logs/variants_plots.out: variants_plots.R logs/variants_mli.out 
	$r $< > $@

logs/real_world_viz.out: real_world_viz.R logs/data_splitter.out 
	$r $< > $@

logs/real_world_plots.out: real_world_plots.R logs/data_splitter.out 
	$r $< > $@

logs/rt_estim_deconv.out: rt_estim_deconv.R ts_utils/rt.R logs/seir.out
	$r $< > $@

logs/cori_estim.out: cori_estim.R ts_utils/cori_wallinga.R logs/seir.out
	$r $< > $@

logs/wt_estim.out: wt_estim.R ts_utils/cori_wallinga.R logs/seir.out
	$r $< > $@

main.pdf: main.tex logs/smoothing_figures.out logs/seir.out logs/rt_estim.out logs/variants_plots.out logs/real_world_viz.out logs/real_world_plots.out logs/rt_estim_deconv.out logs/smoothing_figures_extra.out logs/cori_estim.out logs/wt_estim.out
	del /f main.pdf
	pdflatex $< 
