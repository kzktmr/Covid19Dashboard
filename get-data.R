# Get Data
library(dplyr)
library(readr)
library(ckanr)

ckanr_setup(url = "https://ckan.open-governmentdata.org/")

# 福岡県　新型コロナウイルス感染症　陽性者発表情報
res <- resource_show("0430a12e-568c-4a6a-bed8-51621f47c6e5")

tmp <- 
  read_csv(res$url, 
           skip = 1, col_types = "___D_cccl__",
           col_names = c("date", "address", "age", "sex", "untraceable")) %>% 
  filter(!is.na(date), date >= as.Date("2021-01-01") - 7)

write_csv(tmp, "data/patients.csv")
