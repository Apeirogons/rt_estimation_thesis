
## r(t) estimation

Code related to my HTHSCI 4R12 thesis project, related to r(t) estimation using epidemic timeseries using filtering methods. The majority of the project is written in R, with a few bits in Python. 

(R package requirements):
- data.table
- tidyverse
- ggplot2
- EpiEstim
- ggthemes
- zoo
- poweRlaw
- extraDistr

Python package requirements are found in requirements.txt.

To run, replace r in the Makefile with Rscript. Then, if running Linux, replace del /f main.pdf with rm main.pdf. If you are running Windows instead, install make through [Chocolatey](https://chocolatey.org/install). You will also have to install PDFLateX from any TeX distribution.

Then, clone this directory, navigate to it from command-line, and type: make.

The main output from running this should be main.pdf, which is a write-up of this project. However, should you wish to use this code to perform r(t) estimation on other incidence data (or any data for which you would like to know the exponential growth rate), you must perform the following steps:

- Perform an initial smoothing or filtering step on the incidence data. This work uses the linear_filter fuction in ts_utils/filter.R, and obtains a mean, lower CI, and upper CI timeseries in the form of a named matrix.
- Apply the rt_estimation_ci function from ts_utils/rt.R. You will have to specify the shift amount.

See real_world_plots.R for an example.

The maintainer of this project is Apeirogons (Matthew So, somatthewc@gmail.com). 
