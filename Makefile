target: main.pdf 

r = C:\Users\somat\Documents\R\R-4.0.2\bin\Rscript.exe

logs/logs.out logs:
	mkdir logs
	echo Logs folder created > logs/logs.out 

logs/requirements.out: requirements.txt logs/logs.out
	pip install -r $< > $@

logs/data_splitter.out data: data_splitter.py logs/requirements.out
	python $< > $@

#############################################################################################################3
logs/seir.out seir : run_simulation.R logs/requirements.out 
	$r $< > $@

logs/smoothing_figures.out: smoothing_figures.R base_params.R ggplot_params.R logs/seir.out logs/requirements.out
	$r $< > $@

logs/wt.out: wt.R base_params.R ggplot_params.R logs/seir.out logs/requirements.out
	$r $< > $@

logs/deconvolution_comparison.out: deconvolution_comparison.R base_params.R ggplot_params.R logs/seir.out logs/requirements.out
	$r $< > $@

logs/R0.out: R0.R base_params.R ggplot_params.R logs/seir.out logs/requirements.out
	$r $< > $@

logs/real_world_viz.out: real_world_viz.R ggplot_params.R logs/data_splitter.out
	$r $< > $@

logs/real_world_rt_estim.out: real_world_rt_estim.R base_params.R ggplot_params.R logs/data_splitter.out logs/requirements.out 
	$r $< > $@

logs/rt_estim_2.out: rt_estim_2.R base_params.R ggplot_params.R logs/seir.out logs/requirements.out
	$r $< > $@

logs/variants_mli.out: variants_mli.R
	$r $< > $@

logs/variants_plots.out: variants_plots.R base_params.R ggplot_params.R logs/variants_mli.out
	$r $< > $@

logs/weekday_plots.out: weekday_plots.py logs/seir.out logs/requirements.out
	python $< > $@

main.pdf: main.tex logs/requirements.out logs/seir.out logs/smoothing_figures.out logs/wt.out logs/deconvolution_comparison.out logs/R0.out logs/real_world_viz.out logs/real_world_rt_estim.out logs/rt_estim_2.out logs/weekday_plots.out logs/variants_plots.out
	del /f main.pdf
	pdflatex $< 

