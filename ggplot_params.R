library('ggplot2')
library('ggthemes')
library('tidyverse')

theme_set(theme_bw(base_size=20))

width= 10.4
height= 7.15
# https://stackoverflow.com/questions/57153428/r-plot-color-combinations-that-are-colorblind-accessible


# Hardcoding this palette because I don't ever intend on using a different one in this project.

transparent_palette <- function(transparency){
  new_palette=c()
  # transparency: vector of numeric between 0-1
  palette  <- c( "#000000", "#E69F00", "#56B4E9", "#F0E442", "#009E73", 
                 "#0072B2", "#D55E00", "#CC79A7")
  for(i in c(1:length(palette))){
    if (i <= length(transparency)){
      alpha = transparency[i]
    }
    
    else{
      alpha = 1
    }
    
    alpha_hex_equiv = toupper(toString(as.hexmode(round(alpha*255))))
    if(alpha_hex_equiv == 'FF'){
      alpha_hex_equiv = ''
    }
    new_palette = append(new_palette, paste(palette[i],alpha_hex_equiv, sep=''))
  }
  
  return (new_palette)
}

create_plot <- function(df, select_cols, col_labels, transparencies, plot_labels, legend_loc='outside'){
  # df: dataframe to create plot from, in wide format. X must be a column.
  # select_cols: the columns to be selected, excluding X. These should be in order, top to bottom, for the legend.
  # col_labels: names of each column for ggplot legend
  # plot_labels: From the labs function from ggplot.
  
  
  plotting_df = df %>%
    select(c('X', select_cols)) %>%
    pivot_longer(cols=!X) %>%
    mutate(name=name %>% factor() %>% fct_relevel(select_cols))

  plot = ggplot(plotting_df, aes(x=X, y=value, color=name)) +
    geom_line(lwd=1) +
    scale_color_manual(values=transparent_palette(transparencies), labels=col_labels) +
    guides(colour = guide_legend(override.aes = list(alpha = 1))) +
    theme(legend.background=element_blank())+
    plot_labels 
  
  if (plot_labels$colour ==''){
    plot = plot + theme(legend.title = element_blank())
  }

  switch(
    legend_loc,
    top_right = {
      plot = plot + theme(legend.position=c(0.95, 0.95), legend.justification = c('right', 'top'))
    },
    bottom_right = {
      plot = plot + theme(legend.position=c(0.95, 0.05), legend.justification = c('right', 'bottom'))
    },
    top_left = {
      plot = plot + theme(legend.position=c(0.05, 0.95), legend.justification = c('left', 'top'))
    },
    bottom_left = {
      plot = plot + theme(legend.position=c(0.05, 0.05), legend.justification = c('left', 'bottom'))
    }
  )
  
  return (plot)
}



