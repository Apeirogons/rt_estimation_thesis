# load packages
library(jsonlite)
suppressPackageStartupMessages(library(dplyr))
library(tidyr)
library(ggplot2)
library(directlabels)
library(cowplot)
library(colorspace)

source('ts_utils/rl_cobey.R')
source('ts_utils/Rt.R')
source('ts_utils/process_utils.R')
theme_set(theme_bw())

source('base_params.R')
source('ggplot_params.R')

diffx <- function(x){
  return(abs(c(0, diff(x))))  
}
###################################################################################################3
# This part is not mine
# The code is taken from here:
# https://jeanpaulsoucy.com/post/covid-variant-data/

# load and process data
variants <- fromJSON("https://beta.ctvnews.ca/content/dam/common/exceltojson/COVID-Variants.txt", flatten = FALSE) %>%
  ## remove blank data and summary data
  filter(!Date %in% c("", "Updated", "Total")) %>%
  ## convert Excel dates
  mutate(date = as.Date(as.integer(Date), origin = "1899-12-30"))

# create usable table
variants <- bind_cols(
  select(variants, date, contains("B117")) %>%
    pivot_longer(
      cols = ends_with("B117"),
      names_to = c("province", ".value"),
      names_sep = "_",
      values_to = "B117",
      values_transform = list(B117 = as.integer)
    ) %>%
    arrange(date, province) %>%
    group_by(province) %>%
    fill(3, .direction = "down") %>%
    ungroup,
  select(variants, date, contains("B1351")) %>%
    pivot_longer(
      cols = ends_with("B1351"),
      names_to = c("province", ".value"),
      names_sep = "_",
      values_to = "B1351",
      values_transform = list(B1351 = as.integer)
    ) %>%
    arrange(date, province) %>%
    group_by(province) %>%
    fill(3, .direction = "down") %>%
    ungroup %>%
    select(3),
  select(variants, date, contains("P1")) %>%
    pivot_longer(
      cols = ends_with("P1"),
      names_to = c("province", ".value"),
      names_sep = "_",
      values_to = "P1",
      values_transform = list(P1 = as.integer)
    ) %>%
    arrange(date, province) %>%
    group_by(province) %>%
    fill(3, .direction = "down") %>%
    ungroup %>%
    select(3)
) %>%
  replace_na(list(B117 = 0, B1351 = 0, P1 = 0))

################################################################################3

variants <- variants %>%
  filter(province != 'Canada')
  
plot <- ggplot(variants) + 
  geom_line(aes(x=date, y=B117, color=province)) +
  labs(x='date', y='B117 cumulative', title='B117 cumulative cases')
plot <- direct.label(plot, list(cex=1.5, "last.bumpup"))
print(plot)

plot <- ggplot(variants) + 
  geom_line(aes(x=date, y=B1351, color=province)) +
  labs(x='date', y='B1351 cumulative', title='B1351 cumulative cases')
plot <- direct.label(plot, list(cex=1.5, "last.bumpup"))
print(plot)

plot <- ggplot(variants) + 
  geom_line(aes(x=date, y=P1, color=province)) +
  labs(x='date', y='P1 cumulative', title='P1 cumulative cases')
plot <- direct.label(plot, list(cex=1.5, "last.bumpup"))
print(plot)


# Select B117 from provinces with total incidence > x.
variants_incidence <- variants %>% 
  select(date, province, B117) %>%
  pivot_wider(names_from=province, values_from=B117) %>%
  mutate(across(!date, diffx)) %>%
  select_if(function(col) !is.numeric(col) || (sum(col) > 25)) %>%
  pivot_longer(cols=!date) %>%
  rename(province=name) 


plot <- ggplot(variants_incidence) + 
  geom_line(aes(x=date, y=value, color=province)) +
  labs(x='date', y='B117 incidence', title='B117 incidence by province')
print(plot)

plot <- ggplot(variants_incidence) + 
  aes(x=date, y=value, color=province)+
  geom_smooth( aes(fill=province), alpha=0.1) +
  labs(x='date', y='B117 incidence', title='B117 incidence by province - geom smooth') +
  coord_cartesian(ylim=(c(0, 30))) 

plot <- direct.label(plot, list(cex=1.5, "last.bumpup"))
print(plot)

########################################################################

compute_rt <- function(incidence){
  rt_smoothed = diff(log(incidence))
  rt_smoothed = rollapply(rt_smoothed, 7, mean, fill=NA, align='center')
  rt_smoothed = data.table::shift(rt_smoothed, -1*mean_detection)
  return(c(rt_smoothed, rep(NA, 1)))}

weekday_smoothed_incidence <- variants_incidence %>%
  pivot_wider(names_from=province) %>%
  select(c('date', 'ON', 'AB', 'BC')) %>%
  mutate(across(!date, n_day_smoother)) %>%
  pivot_longer(cols=!date) %>%
  rename(province=name)

plot <- ggplot(weekday_smoothed_incidence) + 
  geom_line(aes(x=date, y=value, color=province)) +
  labs(x='date', y='B117 incidence', title='B117 incidence by province - 7-day smooth')
plot <- direct.label(plot, list(cex=1.5, "last.bumpup"))
print(plot)


weekday_smoothed_rt <- weekday_smoothed_incidence %>%
  pivot_wider(names_from=province) %>%
  mutate(across(!date, compute_rt)) %>%
  pivot_longer(cols=!date) %>%
  rename(province=name)


plot <- ggplot(weekday_smoothed_rt, aes(x=date, y=value, color=province)) + 
  geom_line(alpha=0.8) +
  labs(x='date', y='r(t)', title='Fitted r(t)') +
  xlim(as.Date(c('2021-1-20', '2021-2-20'))) +
  scale_color_colorblind()
plot <- direct.label(plot, list(cex=1.5, "last.bumpup"))
print(plot)

#plot <- ggplot(weekday_smoothed_rt) + 
#  aes(x=date, y=value, color=province)+
#  geom_smooth( aes(fill=province), alpha=0.1) +
#  labs(x='date', y='r(t)', title='Fitted r(t) with geom smooth applied afterwards')+
#  xlim(as.Date(c('2021-1-20', '2021-2-20')))
#plot <- direct.label(plot, list(cex=1.5, "last.bumpup"))
#print(plot)
