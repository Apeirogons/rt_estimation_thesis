### Required setup:
Install PDFLatex.
Create folder "data".
Download https://github.com/owid/covid-19-data/blob/master/public/data/owid-covid-data.xlsx and put it in data.
Create conda environment "MachineLearning"... will change this name later. Only has to be done once
- conda create --name MachineLearning

### After setup:
Activate environment.
- conda activate MachineLearning

pip install -r requirements.txt

Split the data.
- Run data_splitter.py
- Run run_simulation.R.
- Run all of the other R files except base_params.R.

Alternatively, use the Makefile provided for all after-setup functions.