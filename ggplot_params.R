library('ggplot2')
library('ggthemes')

theme_set(theme_bw(base_size=20))

# https://stackoverflow.com/questions/57153428/r-plot-color-combinations-that-are-colorblind-accessible

# Hardcoding this palette because I don't ever intend on using a different one in this project.
transparent_palette <- function(transparency, palette=NULL){
  # transparency: vector of numeric between 0-1
	if(is.null(palette){
		palette  <- c("#000000", "#E69F00", "#56B4E9", "#009E73", 
			"#F0E442", "#0072B2", "#D55E00", "#CC79A7"
		)
	}
  new_palette = c()
  for(i in c(1:length(palette))){
   if (i <= length(transparency)){
      alpha = transparency[i]
   }
    
   else{
      alpha = 1
   }

   alpha_hex_equiv = toupper(toString(as.hexmode(round(alpha*255))))
   new_palette = append(new_palette, paste(palette[i],alpha_hex_equiv, sep=''))
  }
  
  return (new_palette)
}

create_plot <- function(df, select_cols, col_labels, transparencies, plot_labels){
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
    scale_color_manual(values=transparent_palette(c(1, 0.75, 0.75))) +
    guides(colour = guide_legend(override.aes = list(alpha = 1))) +
    plot_labels +
    scale_fill_discrete(labels = col_labels)
  return (plot)
}


