target: summarize.out

# Install all requirements
requirements.out: requirements.txt 
	pip3 install -r $< > $@

# Download latestdata.tgz from this site
latestdata.tgz:
	wget -O $@ "https://github.com/beoutbreakprepared/nCoV2019/raw/master/latest_data/latestdata.tar.gz"

# Unpack latestdata.tgz
latestdata.csv: latestdata.tgz
	tar xzf $<
	touch $@
	rm $<

# Generate starting files
differenced_data.out: generate_starting_files.py latestdata.csv requirements.out
	python $< > $@

summarize.out: summarize.py differenced_data differenced_data.out
	python $< > $@


