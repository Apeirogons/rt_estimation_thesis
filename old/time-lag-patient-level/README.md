
Analyzing the time lag between onset, admission, confirmation, and discharge/death in COVID cases.

The folder 'Naive' is obviously not a country, but a collection of data from all countries in the dataset. However, the amount of data available for each country is not proportional. 

(If you don't have python 3 installed, please install it)

To replicate results, if you are on Linux, run:
make

Otherwise, first download this dataset https://github.com/beoutbreakprepared/nCoV2019/tree/master/latest_data (latestdata.csv) and place it in the covid-time-lag folder. Then run:

pip3 install -r requirements.txt

python generate_starting_files.py

python summarize.py

If this doesn't work, try installing Anaconda and running the same commands. And if that doesn't work, message me at som5@mcmaster.ca.
