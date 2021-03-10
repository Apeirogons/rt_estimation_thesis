#! /usr/bin/Rscript
library('ggplot2')
library('EpiEstim')
library('ggthemes')


source('ggplot_params.R')
source('base_params.R')


R0_t = c()
for(t_step in t){
  R0_t = append(R0_t, R0(t_step))
}
ggplot_df = data.frame(t=t, R0 = R0_t)


ggplot(ggplot_df) +
  geom_line(data=ggplot_df, aes(x=t, y=R0), alpha=1) +
  xlim(0, 400) +
  scale_color_colorblind() +
  labs(title='R0(t)')


ggsave(paste('figures/R0.png', sep=''), width=width, height=height)

