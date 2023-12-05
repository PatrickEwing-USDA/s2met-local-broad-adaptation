library(here)
library(lme4)
library(magrittr)

in_dir = 'Data'
in_df = file.path('T3 Traits', 'Yield.csv')
out_df = 'S2MET_BLUP.csv'

df = here(in_dir, in_df) |>
  read.csv(skip=3, stringsAsFactors=TRUE)

# remove empty columns
nr = nrow(df)
is_empty = sapply(df, function(x) sum(is.na(x))==nr)
df = df[, !is_empty]

# remove columns with single values
is_single = sapply(df, function(x) length(unique(x))==1)
df = df[, !is_single]

# remove redundant columns (double-type IDs)
is_dbid = grepl('DbId', names(df))
df = df[, !is_dbid]
# remove synonyms
df$germplasmSynonyms = NULL

# munge study description. Only the 3rd column has useful information.
df$studyDescription = 
  df$studyDescription |>
  as.character() |>
  strsplit(', ') |>
  sapply('[', 3) |>
  as.factor()

# rename columns
new_names = c(
  studyYear = 'YEAR',
  studyName = 'STUDY_ID',
  studyDescription = 'NOTES',
  locationName = 'LOCATION',
  germplasmName = 'ENTRY',
  observationUnitName = 'SID',
  blockNumber = 'BLOCK',
  plotNumber = 'PLOT',
  rowNumber = 'ROW',
  colNumber = 'COL',
  entryType = 'IS_CHECK',
  Grain.yield.adjusted.weight.basis...kg.ha.CO_323.0000390 = 'YIELD'
)
names(df) = new_names[names(df)]

# add study type
df$STUDY_TYPE = df$STUDY_ID |>
  as.character() |>
  strsplit('_') |>
  sapply('[', 1)

# add more accurate location information
df$SITE = df$STUDY_ID |>
  as.character() |>
  strsplit('_') |>
  sapply('[', 3)

# Add column for check names
df$IS_CHECK = df$IS_CHECK == 'check'

# drop S2C1, which are all experimental lines.
df = subset(df, STUDY_TYPE != 'S2C1') |>
  droplevels()

# remove non-numeric YIELD
is_character = df$YIELD |>
  lapply(type.convert, as.is=TRUE) |>
  sapply(is.character)
df = df[!is_character, ] |>
  type.convert(as.is=TRUE)

# Make columns of test name and check name
checks = df[df$IS_CHECK, 'ENTRY'] |>
  unique()
df$TESTNAME = ifelse(df$ENTRY %in% checks, 'Check', df$ENTRY)
df$CHECKNAME = ifelse(df$ENTRY %in% checks, df$ENTRY, 'Test')

# ensure factors are correct
facts = c('YEAR', 'BLOCK', 'ROW', 'COL')
df[, facts] %<>% lapply(as.factor)

# contingency tables
with(df, table(STUDY_TYPE, YEAR))
with(df, table(CHECKNAME, YEAR))
with(df, table(SITE, YEAR, STUDY_TYPE))

#### BEGIN ADJUSTMENT ####
#### S2TP ####

# Adjust training population data?
s2tp = subset(df, STUDY_TYPE == 'S2TP') |>
  droplevels()
# S2TP supposedly used an incomplete block design

with(s2tp, table(BLOCK, STUDY_ID))
# but it looks like 3 sites are completely random.

with(s2tp, table(CHECKNAME, STUDY_ID))
# with unreplicated checks

with(s2tp, table(ROW, STUDY_ID))
with(s2tp, table(COL, STUDY_ID))
# and no positional information, so we'll ignore S2TP because we can't BLUP with 
# acceptable confidence.


# Adjust S2MET?
s2met = subset(df, STUDY_TYPE == 'S2MET') |>
  droplevels()
with(s2met, table(STUDY_ID, BLOCK))
# All completely random

with(s2met, table(STUDY_ID, CHECKNAME))
# But with replicated checks

with(s2met, table(STUDY_ID, ROW))
with(s2met, table(STUDY_ID, COL))
# and positional locations

ff = "YIELD ~ CHECKNAME + (1|ROW) + (1|COL) + (1|TESTNAME:IS_CHECK)" |>
  formula()

dd = split(s2met, s2met$STUDY_ID, drop=TRUE)
mm = lapply(names(dd), function(y) {
  x = dd[[y]]
  out = lmer(ff, data=x) |> 
    ranef()
  out = out[[1]]
  glob_mean = mean(x$YIELD)
  out = data.frame(STUDY_ID = y,
                   TESTNAME = gsub(":FALSE", '', rownames(out)),
                   YIELD_ADJ = out[[1]] + glob_mean)
  out
})
mm = do.call(rbind, mm) %>% 
  subset(!(TESTNAME %in% c('BLANK', 'Check:TRUE'))) %>% 
  merge(s2met, ., by=c('STUDY_ID', 'TESTNAME'))

# Don't use checks because they're included for variation not performance
# and are from a variety of different programs (ex. AAC, CDC, LCS).
## Average checks, which are replicated so reliable
# ck = subset(df, CHECKNAME != 'Test') %>% 
#   aggregate(YIELD ~ CHECKNAME + STUDY_ID, data=., mean)
# names(ck) %<>% gsub('YIELD', 'YIELD_ADJ', .)
# ck %<>% merge(s2met, ., by=c('STUDY_ID', 'CHECKNAME')) %>% 
#   .[, colnames(mm)]

keep_cols = c('STUDY_ID', 'YEAR', 'LOCATION', 'ENTRY', 'IS_CHECK', 'STUDY_TYPE', 'SITE', 'YIELD_ADJ')

out = mm
head(out)
tail(out)
sum(duplicated(out[, c('ENTRY', 'YIELD_ADJ')]))

write.csv(out, 
          here(in_dir, out_df),
          row.names=FALSE)
