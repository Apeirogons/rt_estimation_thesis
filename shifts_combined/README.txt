1. I've been not using environments (like an idiot), so there are too many things in requirements.txt. Anyway, it should work. Do
pip install -r requirements.txt
2. Create folder "data" and put 'owid-covid-data.xlsx' into it. Instructions for downloading are in the parent folder.
3. Run data_splitter.py
4. Run write_incubation_period.R
5. Run seir_simulation.py
6. Run all the other files. 