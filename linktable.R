library(dplyr)
library(data.table)
library(readxl)
library(stringr)

compustat_list <- 
  read.csv('/Users/ao_sun/Desktop/mit/241122_dealscan/compustat_firm_list.csv', header = TRUE, stringsAsFactors = FALSE) %>% 
  distinct(conml)
write.csv(compustat_list, '/Users/ao_sun/Desktop/mit/241122_dealscan/compustat_list_distinct.csv', row.names = FALSE)

wrds_loanconnector <- 
  read_xlsx('/Users/ao_sun/Dropbox (MIT)/Tax and M&A Debt/Data/Raw/WRDS_to_LoanConnector_IDs.xlsx', sheet=1) %>% 
  rename(lpc_deal_id = 'LoanConnector Deal ID',
         lpc_tranche_id = 'LoanConnector Tranche ID',
         facilityid = 'WRDS facility_id') %>% 
  distinct(lpc_deal_id, lpc_tranche_id, .keep_all = TRUE)

dealscan <- 
  fread('/Users/ao_sun/Dropbox (MIT)/Tax and M&A Debt/Data/Raw/dealscan_data.csv', header = TRUE, stringsAsFactors = FALSE) %>% 
  filter(grepl('term loan|revolver', tranche_type, ignore.case=TRUE)) %>%  # only term loan and revolver 
  filter(sic_code < 6000 | sic_code >= 7000, # drop financial institution
         country == 'United States')

dealscan_merged <- 
  dealscan %>% 
  inner_join(wrds_loanconnector, by = c('lpc_deal_id', 'lpc_tranche_id')) 

# dealscan and compustat
dealscan_compustat <- read_xlsx('/Users/ao_sun/Dropbox (MIT)/Tax and M&A Debt/Data/Raw/Dealscan-Compustat_Linking_Database012024.xlsx', sheet = 2)

dealscan_merged_merged <- 
  dealscan_merged %>% 
  inner_join(dealscan_compustat, by = c('facilityid'))

borrower_gvkey <- 
  dealscan_merged_merged %>% 
  select(borrower_name, gvkey) %>% 
  distinct(borrower_name, .keep_all = TRUE)

# deals after 2020
deal_2020 <- 
  dealscan %>% 
  filter(deal_active_date >= '2020-09-19')

deal_2020 %>% 
  distinct(borrower_name)

# Extend to 2024 using existing links
deal_2020_exisitng_borrower <- 
  deal_2020 %>% 
  inner_join(borrower_gvkey,
             by = 'borrower_name') %>% 
  distinct(borrower_name, gvkey)
write.csv(deal_2020_exisitng_borrower, '/Users/ao_sun/Desktop/mit/241122_dealscan/deal_2020_exisitng_borrower.csv', row.names = FALSE)

other_borrowers <-
  deal_2020 %>% 
  anti_join(borrower_gvkey,
             by = 'borrower_name') %>% 
  distinct(borrower_name) %>% 
  mutate(borrower_name_clean = tolower(borrower_name)) %>% 
  mutate(borrower_name_clean = str_remove_all(borrower_name_clean, "\\b(?:inc|llc|ltd|lp)\\b"))

# fuzzy match with compustat
compustat <- 
  read.csv('/Users/ao_sun/Desktop/mit/241122_dealscan/compustat_firm_list.csv', header = TRUE, stringsAsFactors = FALSE) %>% 
  distinct(gvkey, conml) %>% 
  mutate(conml = tolower(conml)) %>% 
  mutate(conml = str_remove_all(conml, "\\b(?:inc|llc|ltd|lp)\\b"))

threshold <- 0.90

matching_results_df <- data.frame(
  borrower_name_clean = character(0),
  conml = character(0)
)

for (borrower_name_clean in other_borrowers$borrower_name_clean) {
  distances <- stringdist::stringdistmatrix(borrower_name_clean, compustat$conml, method = "jw")
  closest_match_index <- which.min(distances)
  jw_similarity <- 1 - distances[closest_match_index]

  if (jw_similarity >= threshold) {
    
    matching_results_df <- rbind(
      matching_results_df,
      data.frame(borrower_name_clean, compustat$conml[closest_match_index])
    )
  }
}

colnames(matching_results_df) <- c("borrower_name_clean", "conml")

result_df <- 
  other_borrowers %>%
  inner_join(matching_results_df, by = c("borrower_name_clean" = "borrower_name_clean")) %>% 
  left_join(compustat, by='conml')
write.csv(result_df, '/Users/ao_sun/Desktop/mit/241122_dealscan/fm_borrower.csv', row.names = FALSE)

# manually check
hand_check_borrower <- 
  other_borrowers %>% 
  anti_join(result_df %>% 
              distinct(borrower_name_clean),
            by = 'borrower_name_clean') 
write.csv(hand_check_borrower, '/Users/ao_sun/Desktop/mit/241122_dealscan/hand_check_borrower.csv', row.names = FALSE)

# final list
existing_firm <- 
  read.csv('/Users/ao_sun/Desktop/mit/241122_dealscan/deal_2020_exisitng_borrower.csv', header = TRUE, stringsAsFactors = FALSE)
fm_list <- 
  read.csv('/Users/ao_sun/Desktop/mit/241122_dealscan/fm_borrower.csv', header = TRUE, stringsAsFactors = FALSE) %>% 
  filter(conml != '') %>% 
  select(borrower_name, gvkey)
hand_check_list <- 
  read.csv('/Users/ao_sun/Desktop/mit/241122_dealscan/hand_check_borrower.csv', header = TRUE, stringsAsFactors = FALSE) %>% 
  filter(conml != '') %>% 
  left_join(
    read.csv('/Users/ao_sun/Desktop/mit/241122_dealscan/compustat_firm_list.csv', header = TRUE, stringsAsFactors = FALSE) %>% 
      distinct(conml, gvkey),
    by = 'conml'
  ) %>% 
  select(borrower_name, gvkey)

final_list <- 
  rbind(existing_firm, fm_list, hand_check_list) %>% 
  distinct()
write.csv(final_list, '/Users/ao_sun/Desktop/mit/241122_dealscan/DS_linktable_extension.csv', row.names = FALSE)
