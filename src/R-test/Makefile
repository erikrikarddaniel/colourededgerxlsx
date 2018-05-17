colourededgerxlsx: colourededgerxlsx.00 colourededgerxlsx.01 colourededgerxlsx.02

# Version 0.1
colourededgerxlsx.00:
	@../R/colourededgerxlsx.r --verbose --seedtables=BAL334.SEED.tsv,BAL450.SEED.tsv --keysep=, --keycol=feature=Features --outxlsx=$@.xlsx $@.tsv.gz
	@echo "*** This is *not* an automated test, check $@.xlsx manually! ***"

# Version 0.2
colourededgerxlsx.01:
	@../R/colourededgerxlsx.r --verbose --seedtables=BAL334.SEED.tsv,BAL450.SEED.tsv --annottables=BAL334.annot.tsv,BAL450.annot.tsv --seedcolwidthcm=6 --keysep=, --keycol=feature=Features --outxlsx=$@.xlsx $@.tsv.gz
	@echo "*** This is *not* an automated test, check $@.xlsx manually! ***"

# with FDR threshold as flag, to be tested
colourededgerxlsx.02:
	@../R/colourededgerxlsx.r --verbose --FDR=0.05 --seedtables=BAL334.SEED.tsv,BAL450.SEED.tsv --keysep=, --keycol=feature=Features --outxlsx=$@.xlsx $@.tsv.gz
	@echo "*** This is *not* an automated test, check $@.xlsx manually! ***"

# with one seed table and seedhier only (not working yet)
colourededgerxlsx.03:
	@../R/colourededgerxlsx.r --verbose --seedtables=$@.seed.tsv --outxlsx=$@.xlsx $@.edger.tsv
	@echo "*** This is *not* an automated test, check $@.xlsx manually! ***"

# Not ready yet
colourededgerxlsx.10:
	@../R/colourededgerxlsx.r --verbose --seedtables=$@.BAL334.SEED.tsv,$@.BAL450.SEED.tsv --outxlsx=$@.xlsx --cpmtable=$@.cpms.tsv.gz --contr2samples=$@.contrast2samples.tsv $@.tsv.gz
	@echo "*** This is *not* an automated test, check $@.xlsx manually! ***"
