#!/usr/bin/env Rscript

# colourededgerxlsx.r
#
# Author: daniel.lundin@lnu.se

suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(tibble))
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(purrr))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(openxlsx))

SCRIPT_VERSION = "0.1"
FDR_SIGN_LEVEL = 0.10

SEEDCOLOURS = 
  matrix(
    c(
      "Amino Acids and Derivatives", "red", "white",
      "Carbohydrates", "white", "black",
      "Cell Division and Cell Cycle", "black", "#ffeeaa",
      "Cell Wall and Capsule", "black", "#afe9af",
      "Cofactors, Vitamins, Prosthetic Groups, Pigments", "black", "#c6afe9",
      "Clustering-based_subsystems", "black", "#aaccff",
      "DNA Metabolism", "#00ffff", "#800000",
      "Dormancy and Sporulation", "black", "#e9afaf",
      "Fatty Acids, Lipids, and Isoprenoids", "#800080", "white",
      "Iron acquisition and metabolism", "black", "#ff6600",
      "Membrane Transport", "black", "#ffccaa",
      "Metabolism of Aromatic Compounds", "black", "#008000",
      "Miscellaneous", "yellow", "white",
      "Miscellaneous", "yellow", "#2a2aff",
      "Motility and Chemotaxis", "yellow", "#000080",
      "Nitrogen Metabolism", "yellow", "blue",
      "Nucleosides and Nucleotides", "blue", "white",
      "Phages, Prophages, Transposable elements, Plasmids", "green", "#d38d5f",
      "Phosphorus Metabolism", "#d38d5f", "white",
      "Photosynthesis", "black", "green",
      "Potassium metabolism", "black", "#bc5fd3",
      "Protein Metabolism", "yellow", "#800000",
      "Regulation and Cell signaling", "black", "#87deaa",
      "Respiration", "yellow", "red",
      "RNA Metabolism", "green", "#800000",
      "Secondary Metabolism", "black", "#5599ff",
      "Stress Response", "black", "#9955ff",
      "Sulfur Metabolism", "black", "yellow",
      "Virulence, Disease and Defense", "black", "#ffcc00"
    ),
    byrow = TRUE, ncol = 3
  )
colnames(SEEDCOLOURS) <- c('Category', 'fontColour', 'bgFill')
SEEDCOLOURS <- as.tibble(SEEDCOLOURS)

# Arg for testing: opt <- list(options = list(seedtables = 'colourededgerxlsx.00.BAL334.SEED.tsv,colourededgerxlsx.00.BAL450.SEED.tsv', outxlsx = 'test.xlsx', verbose = TRUE, keycol = 'feature=Features', keysep = ','), args = 'colourededgerxlsx.00.tsv.gz')
# Get arguments
option_list = list(
  make_option(
    "--annottables", action="store", type="character",
    help="List of tsv files containing a two column annotation table, must contain a key named like in the main table, but see also --keycol and --keysep."
  ),
  make_option(
    '--keycol', action = 'store', type = 'character', default = 'feature=Features',
    help = 'Name of column containing separated and column containing multiple keys respectively, separated by "=", default "%default"; see also --keysep.'
  ),
  make_option(
    '--keysep', action = 'store', type = 'character', default = ',',
    help = 'Character to use to split key column, default "%default"; see also --keycol.'
  ),
  make_option(
    "--seedtables", action="store", type="character",
    help="List of tsv files containing SEED classificiations, must contain a key named like in the main table, but see also --keycol and --keysep."
  ),
  make_option(
    "--outxlsx", action="store", type="character",
    help="Name of output xlsx file."
  ),
  make_option(
    c("-v", "--verbose"), action="store_true", default=FALSE, 
    help="Print progress messages"
  ),
  make_option(
    c("-V", "--version"), action="store_true", default=FALSE, 
    help="Print program version and exit"
  )
)
opt = parse_args(
  OptionParser(
    usage = "%prog [options] edger_result_file.tsv[.gz]\n\n\tThe EdgeR result file must contain a key to join in with the SEED tables, a 'contrast' column plus logFC, FDR, locCPM.", 
    option_list = option_list
  ), 
  positional_arguments = TRUE
)

if ( opt$options$version ) {
  write(SCRIPT_VERSION, stdout())
  quit('no')
}

logmsg = function(msg, llevel='INFO') {
  if ( opt$options$verbose ) {
    write(
      sprintf("%s: %s: %s", llevel, format(Sys.time(), "%Y-%m-%d %H:%M:%S"), msg),
      stderr()
    )
  }
}

# Read the SEED tables
logmsg(sprintf("Reading SEED tables %s", opt$options$seedtables))
seed <- tibble(fn = str_split(opt$options$seedtables, ',')[[1]]) %>% 
  mutate(d = map(fn, ~ read_tsv(., col_types = cols(.default = col_character())))) %>% 
  unnest() %>% select(-fn)

if ( length(opt$options$keysep) ) {
  oldkey <- sub('.*=', '', opt$options$keycol)
  newkey <- sub('=.*', '', opt$options$keycol)
  seed <- seed %>% separate_rows(!! oldkey, sep = opt$options$keysep) %>%
    rename(!! newkey := !! oldkey)
}

# Read any other annotation tables and add to seed table
if ( length(opt$options$annottables) > 0 ) {
  logmsg(sprintf("Reading annotation tables %s", opt$options$annottables))
  annot <- tibble(fn = str_split(opt$options$annottables, ',')[[1]]) %>% 
    mutate(d = map(fn, ~ read_tsv(., col_types = cols(.default = col_character())))) %>% 
    unnest() %>% select(-fn)
  seed <- seed %>% right_join(annot)
}

logmsg(sprintf("Reading %s, left joining with SEED table", opt$args))
edger <- seed %>% 
  right_join(
    read_tsv(
      opt$args, 
      col_types = cols(
        .default = col_character(), 
        logFC = col_double(), logCPM = col_double(), FDR = col_double(), 
        F = col_double(), PValue = col_double()
      )
    )
  ) %>%
  replace_na(list('Category' = 'ZZ Not in SEED'))

fill_worksheet <- function(wb, ws, c, fdrlimit) {
  logmsg(sprintf("\tCreating sheet for %s, fdrlimit %f", c, fdrlimit))
  logfcindex = ifelse(length(opt$options$annottables) > 0, 7, 6)

  t <- edger %>% filter(FDR <= fdrlimit, contrast == c) %>% 
    select(-contrast) %>%
    arrange(Category, Subcategory, Subsystem, Role)
  wb %>% writeData(ws, t, headerStyle = createStyle(textDecoration = 'bold'))

  # Styles for numbers
  wb %>% addStyle(ws, style = createStyle(numFmt = '0.00'), cols = 5:7, rows = 2:(nrow(t) + 1), gridExpand = TRUE)
  wb %>% addStyle(ws, style = createStyle(numFmt = '0.0E00'), cols = 9:ncol(t), rows = 2:(nrow(t) + 1), gridExpand = TRUE)
  
  # Colour coding for SEED categories
  #logmsg("\tSetting SEED category colours", 'DEBUG')
  for ( i in 1:nrow(SEEDCOLOURS) ) {
    #logmsg(sprintf("%s: %s, %s", SEEDCOLOURS$Category[i], SEEDCOLOURS$fontColour[i], SEEDCOLOURS$bgFill[i]), 'DEBUG')
    wb %>% conditionalFormatting(
      ws, cols = 1:4, rows = 1:(nrow(t) + 1), rule = sprintf('$A1 == "%s"', SEEDCOLOURS$Category[i]),
      style = createStyle(fontColour = SEEDCOLOURS$fontColour[i], bgFill = SEEDCOLOURS$bgFill[i])
    )
  }

  # Heatmaps for logFC
  #logmsg("\tSetting logFC heatmap", 'DEBUG')
  FC_NEGATIVE_HEATMAP = tibble(
    maxval = 0:-7,
    bgFill = c('#fff6d5', '#ffeeaa', '#ffe680', '#ffdd55', '#ffd42a', '#ffcc00', '#d4aa00', '#aa8800'),
    fontColour = c('black', 'black', 'black', 'black', 'black', 'white', 'white', 'white')
  )
  for ( i in 1:nrow(FC_NEGATIVE_HEATMAP) ) {
    wb %>% conditionalFormatting(
      ws, cols = logfcindex, rows = 2:(nrow(t) + 1), rule = sprintf(' < %s', FC_NEGATIVE_HEATMAP$maxval[i]),
      style = createStyle(fontColour = FC_NEGATIVE_HEATMAP$fontColour[i], bgFill = FC_NEGATIVE_HEATMAP$bgFill[i])
    )
  }
  FC_POSITIVE_HEATMAP = tibble(
    minval = 0:7,
    bgFill = c('#d7f4d7', '#afe9af', '#87de87', '#5fd35f', '#37c837', '#2ca02c', '#217821', '#165016'),
    fontColour = c('black', 'black', 'black', 'black', 'black', 'white', 'white', 'white')
  )
  for ( i in 1:nrow(FC_POSITIVE_HEATMAP) ) {
    wb %>% conditionalFormatting(
      ws, cols = logfcindex, rows = 2:(nrow(t) + 1), rule = sprintf(' > %s', FC_POSITIVE_HEATMAP$minval[i]),
      style = createStyle(fontColour = FC_POSITIVE_HEATMAP$fontColour[i], bgFill = FC_POSITIVE_HEATMAP$bgFill[i])
    )
  }

  # Heatmaps for logCPM and individual sample columns
  #logmsg("\tSetting logCPM heatmap", 'DEBUG')
  CPM_HEATMAP = tibble(
    maxval = seq(2, 18, by = 2),
    bgFill = c('#d5e5ff', '#aaccff', '#80b3ff', '#5599ff', '#2a7aff', '#0066ff', '#0055d4', '#0044aa', '#003380'),
    fontColour = c('black', 'black', 'black', 'black', 'black', 'white', 'white', 'white', 'white')
  )
  for ( i in 1:nrow(CPM_HEATMAP) ) {
    wb %>% conditionalFormatting(
      ws, cols = logfcindex + 1, rows = 2:(nrow(t) + 1), rule = sprintf(' > %s', CPM_HEATMAP$maxval[i]),
      style = createStyle(fontColour = CPM_HEATMAP$fontColour[i], bgFill = CPM_HEATMAP$bgFill[i])
    )
# Waiting until we join in cpm table(s)
###    wb %>% conditionalFormatting(
###      ws, cols = (logfcindex + 3):ncol(t), rows = 2:(nrow(t) + 1), rule = sprintf(' > %s', 2**CPM_HEATMAP$maxval[i]),
###      style = createStyle(fontColour = CPM_HEATMAP$fontColour[i], bgFill = CPM_HEATMAP$bgFill[i])
###    )
  }

  # Colours for FDR
  #logmsg("\tSetting colours for FDR", 'DEBUG')
  wb %>% conditionalFormatting(
    ws, cols = logfcindex + 4, rows = 2:(nrow(t) + 1), rule = '<= 0.10',
    style = createStyle(fontColour = 'black', bgFill = 'yellow')
  )
  wb %>% conditionalFormatting(
    ws, cols = logfcindex + 4, rows = 2:(nrow(t) + 1), rule = '<= 0.05',
    style = createStyle(fontColour = 'black', bgFill = 'green')
  )
  wb %>% conditionalFormatting(
    ws, cols = logfcindex + 4, rows = 2:(nrow(t) + 1), rule = '> 0.10',
    style = createStyle(fontColour = 'black', bgFill = 'red')
  )
  logmsg(sprintf("\tDone with %s", c))
}

wb <- createWorkbook()
for ( c in edger %>% distinct(contrast) %>% pull(contrast) ) {
  sh <- wb %>% addWorksheet(sprintf('%s_SIGN', c))
  fill_worksheet(wb, sh, c, FDR_SIGN_LEVEL)
  sh <- wb %>% addWorksheet(sprintf('%s_ALL', c))
  fill_worksheet(wb, sh, c, 1.0)
}
wb %>% saveWorkbook(opt$options$outxlsx, overwrite = TRUE)

logmsg("Done")
