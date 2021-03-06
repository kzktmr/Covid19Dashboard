# Get Data
library(dplyr)
library(tidyr)
library(readr)
library(ckanr)
library(httr)
library(ndjson)
library(readxl)
library(stringr)
library(lubridate)

ckanr_setup(url = "https://ckan.open-governmentdata.org/")

# 福岡県　新型コロナウイルス感染症　陽性者発表情報
# res <- resource_show("0430a12e-568c-4a6a-bed8-51621f47c6e5")
# res <- resource_show("419f6cff-e74a-49b3-9f3c-7b425e5f5228")
# res <- resource_show("9d32b7ee-5bfe-4b3c-a582-ea56f3b0afd9")
res <- resource_show("90cd005a-8d70-468e-a9b5-d36aad4eb3ca")

# Mon Apr 11 09:38:58 2022 ------------------------------
if(str_detect(res$url, "\\.csv$")){
  tmp <- read_csv(res$url, skip = 1, col_types = "___D_cccl__",
                  col_names = c("date", "address", "age", "sex", "untraceable")) %>% 
    filter(!is.na(date), date >= as.Date("2021-01-01") - 7)
  write_csv(tmp, "data/patients.csv")
}else if(str_detect(res$url, "\\.xlsx$")){
  tmp_file <- tempfile()
  download.file(res$url, tmp_file)
  tmp <- read_excel(tmp_file, skip = 1, col_names = c("date", "address", "age", "sex"),
                    col_types = c("skip", "skip", "skip", "date", "skip", 
                                  "text", "text", "text")) %>% 
    mutate(date = as.Date(date)) %>% 
    filter(!is.na(date), date >= as.Date("2021-01-01") - 7)
  write_csv(tmp, "data/patients.csv")
}
  
# 福岡県　新型コロナウイルス感染症　新規陽性者数
# res <- resource_show("bd25a096-b060-428a-bc85-91c1715fc540")
# res <- resource_show("949b90ee-25df-4423-a8f4-d58295676339")
# res <- resource_show("3e306520-17e0-4684-8b88-bddf748c68bd")
res <- resource_show("cbce5bf0-6c04-4f35-a0fd-748f9024d20f")

tmp <- read_csv(res$url, skip = 1, col_types = "___D_dd", 
                col_names = c("date", "detected", "detected_cum")) %>% 
  filter(date >= as.Date("2021-01-01") - 7)

write_csv(tmp, "data/newlycases.csv")

# 福岡県　新型コロナウイルス感染症　検査陽性者の状況
# res <- resource_show("e3630e26-14c5-4cd0-b111-53e51b56b85a")
# res <- resource_show("f9d172be-5cf7-4d89-aca5-cbcde79314e1")
res <- resource_show("4470951b-5559-4778-9d02-33e66bbcc06f")

tmp <- 
  read_csv(res$url, col_types = "__Dcdddddddd") %>% 
  rename(date = 公表_年月日, weekday = 曜日) %>% 
  filter(date >= as.Date("2021-01-01") - 7) %>% 
  pivot_longer(-(date:weekday)) 

write_csv(tmp, "data/situation.csv")

# 福岡県　新型コロナウイルス感染症　検査実施数
# res <- resource_show("33e3a2ba-6d07-474c-9370-2885932b22e9")
# res <- resource_show("dacd1366-2a49-4a1a-a508-73fc0f57b5ca")
res <- resource_show("1aca4a7e-fda6-496c-badc-17a70964767c")

tmp <- 
  read_csv(res$url,
           col_types = "___D_____dd", skip = 1,
           col_names = c("date", "inspected", "inspected_cum")) %>% 
  filter(date >= as.Date("2021-01-01") - 7)

write_csv(tmp, "data/inspection.csv")

# 確保病床数
res <- resource_show("fa692fe1-9792-4127-a245-61a32f3e7448")

tmp <- 
  read_csv(res$url, col_types = "__D_ddd", skip = 1,
           col_names = c("date", "bed", "severe_bed", "hotel_room")) %>% 
  filter(date >= as.Date("2021-01-01") - 7)

write_csv(tmp, "data/sickbeds.csv")

# ワクチン接種状況
tmp_file <- tempfile()

# GET("https://vrs-data.cio.go.jp/vaccination/opendata/latest/prefecture.ndjson") %>% 
GET("https://data.vrs.digital.go.jp/vaccination/opendata/latest/prefecture.ndjson") %>% 
  content() %>% writeBin(tmp_file)
tmp <- ndjson::stream_in(tmp_file) %>% filter(prefecture == "40") 

write_csv(tmp, "data/vaccination.csv")

# 重症者数
severe_cases <-
  read_csv("https://covid19.mhlw.go.jp/public/opendata/severe_cases_daily.csv") %>%
  # filter(Prefecture == "Fukuoka") %>% 
  # mutate(date = as.Date(Date)) %>% 
  # select(date, severe_cases = `Severe cases`)
  mutate(date = as.Date(Date)) %>%     # 2021/12/04 厚労省仕様変更
  select(date, severe_cases = Fukuoka) # 
  
write_csv(severe_cases, "data/severe_cases.csv")

# 救急搬送困難事案
tmp_file <- tempfile()
download.file("https://www.fdma.go.jp/disaster/coronavirus/items/coronavirus_data.xlsx", tmp_file)
tmp <- read_excel(tmp_file, skip = 5, col_names = FALSE) %>% 
  rename(pref = "...1", city = "...2") %>% 
  select(-pref) %>% filter(city %in% c("福岡市消防局", "北九州市消防局")) %>% 
  pivot_longer(-city) %>% 
  mutate(week = as.integer(str_extract(name, "[0-9]+")) - 2,
         date = lubridate::ymd("2020-03-30") + lubridate::weeks(week - 1 )) %>% 
  select(date, city, value)

write_csv(tmp, "data/emergency_transport.csv")