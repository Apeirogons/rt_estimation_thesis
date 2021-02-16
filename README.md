### Required setup:
Install PDFLatex.
Create conda environment "MachineLearning"... will change this name later. Only has to be done once
- conda create --name MachineLearning

### After setup:
Activate environment.
- conda activate MachineLearning

pip install -r requirements.txt

Download real-world data.
Create folder "data".
Download https://github.com/owid/covid-19-data/blob/master/public/data/owid-covid-data.xlsx and put it in data.

Split the data.
- Run data_splitter.py
- Run run_simulation.R.
- Run all of the other R files except base_params.R.

Alternatively, use the Makefile provided for all after-setup functions. You have to replace $r with your Rscript location, and if you're on Linux you will have to change del /f to rm.
