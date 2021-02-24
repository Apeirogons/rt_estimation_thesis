library(ggplot2)
library(ggthemes)
source('ggplot_params.R')

data = read.csv('data/Canada.csv')
data$date = as.Date(data$date)

plot = ggplot(data) + geom_line(data=data, aes(x=date, y=new_cases_per_million, color='Canada'))

data = read.csv('data/United States.csv')
data$date = as.Date(data$date)

plot = plot + geom_line(data=data,aes(x=date, y=new_cases_per_million, color='United States'))



plot = plot + labs(title='New cases per million in various countries')
plot = plot + scale_color_colorblind()
print(plot)
ggsave('figures/real_dataviz.png', width=10.4, height=6.15)