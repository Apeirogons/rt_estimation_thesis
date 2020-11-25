#! /usr/bin/Rscript
library('deSolve')

library('extraDistr')
library('EpiEstim')
library('poweRlaw')
library('data.table')
library('ggthemes')


# Real-world incubation period
m = dislnorm$new()
m$setPars(c(1.63, 0.5))
m$setXmin(0)

indices = c(0:40)
incubation_pdf = dist_pdf(m, q=indices)

# SEIR incubation period
gamma = 1/10.02

mean_gamma = 1/gamma
sd_gamma = sqrt((1/gamma)**2)
seir_incubation = discr_si(indices, mean_gamma, sd_gamma)

incubation_df = data.frame(d=indices, real_world=incubation_pdf, seir=seir_incubation)

write.csv(incubation_df, paste(paste('incubation_period', '.csv', sep='')))




