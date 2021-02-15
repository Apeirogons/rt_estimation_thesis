#! /usr/bin/Rscript
library('reticulate')
library('ggplot2')
library('EpiEstim')
library('ggthemes')
library(data.table)
library('extraDistr')
library('poweRlaw')
library('zoo')


source('ts_utils/rl_cobey.R')
source('ts_utils/Rt.R')
source('ts_utils/process_utils.R')

use_condaenv('MachineLearning')
theme_set(theme_bw())
source_python('ts_utils/deconvolution.py')
source('base_params.R')


R0_t = c()
for(t_step in t){
  R0_t = append(R0_t, R0(t_step))
}
ggplot_df = data.frame(t=t, R0 = R0_t)


plot = ggplot(ggplot_df)
plot =  plot + geom_line(data=ggplot_df, aes(x=t, y=R0), alpha=1)


plot = plot + xlim(0, 400)
plot = plot + ylim(c(0,2.5)) + scale_color_colorblind()
plot = plot + labs(title='R0(t)')
print(plot)

ggsave(paste('figures/R0.png', sep=''), width=10.4, height=6.15)

