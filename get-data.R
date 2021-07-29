# Get Data
library(dplyr)
library(readr)
library(ckanr)

ckanr_setup(url = "https://ckan.open-governmentdata.org/")

# 福岡県　新型コロナウイルス感染症　陽性者発表情報
res <- resource_show("0430a12e-568c-4a6a-bed8-51621f47c6e5")

patients <- 
  read_csv(res$url, 
           skip = 1, col_types = "___D_cccl__",
           col_names = c("date", "address", "age", "sex", "untraceable")) %>% 
  filter(!is.na(date)) %>% 
  mutate(weekday = weekdays(date, abbreviate = TRUE)) %>% 
  mutate(holiday = if_else(weekday %in% c("土", "日") | zipangu::is_jholiday(date), TRUE, FALSE)) #%>% 

write_csv(patients, "data/patients.csv")
