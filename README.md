
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
- reticulate
- signal

More requirements: 
- The project is tested on Windows 10. It requires a make installation through [Chocolatey](https://chocolatey.org/install).
- Python package requirements are found in requirements.txt. Python 3 is required.
- PDFLatex from any TEX distribution is required.
- The Rscript and python commands may not be the same for everyone, depending on the system. Create a file local.mk to fix this (an example exists commented-out in the Makefile.
- Some of the Makefile will have to be changed if using Linux instead, due to Windows-specific commands. Some potential fixes exist in the Makefile, but they are untested.


Clone this directory, navigate to it from command-line, and build it with: make

The main output from running this should be main.pdf, which is a write-up of this project. However, should you wish to use this code to perform r(t) estimation on other incidence data (or any data for which you would like to know the exponential growth rate), you must perform the following steps:

- Perform an initial smoothing or filtering step on the incidence data. This work uses the linear_filter fuction in ts_utils/filter.R, and obtains a mean, lower CI, and upper CI timeseries in the form of a named matrix.
- Apply the rt_estimation_ci function from ts_utils/rt.R. You will have to specify the shift amount.

See real_world_plots.R for an example.

The maintainer of this project is matthewcso (Matthew So, somatthewc@gmail.com). 
