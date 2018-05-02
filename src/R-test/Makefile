colourededgerxlsx: colourededgerxlsx.00 colourededgerxlsx.01

# Version 0.1
colourededgerxlsx.00:
	@../R/colourededgerxlsx.r --verbose --seedtables=BAL334.SEED.tsv,BAL450.SEED.tsv --outxlsx=$@.xlsx $@.tsv.gz
	@echo "*** This is *not* an automated test, check $@.xlsx manually! ***"

# Version 0.2
colourededgerxlsx.01:
	@../R/colourededgerxlsx.r --verbose --seedtables=BAL334.SEED.tsv,BAL450.SEED.tsv --annottables=BAL334.annot.tsv,BAL450.annot.tsv --outxlsx=$@.xlsx $@.tsv.gz
	@echo "*** This is *not* an automated test, check $@.xlsx manually! ***"

# Not ready yet
colourededgerxlsx.02:
	@../R/colourededgerxlsx.r --verbose --seedtables=$@.BAL334.SEED.tsv,$@.BAL450.SEED.tsv --outxlsx=$@.xlsx --cpmtable=$@.cpms.tsv.gz --contr2samples=$@.contrast2samples.tsv $@.tsv.gz
	@echo "*** This is *not* an automated test, check $@.xlsx manually! ***"
