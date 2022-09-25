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
# package_search("新型コロナウイルス感染症 陽性者発表情報")
pac <- package_show("8a9688c2-7b9f-4347-ad6e-de3b339ef740")
res <- pac$resources
url <- res %>% bind_rows() %>% pull(url)
  
tmp <- lapply(url, read_csv, skip = 1, col_types = "___D_cccl__",
              col_names = c("date", "address", "age", "sex", "untraceable")) %>% 
  bind_rows() %>% 
  filter(!is.na(date), date >= as.Date("2021-01-01") - 7)
  
write_csv(tmp, "data/patients.csv")
  
# 福岡県　新型コロナウイルス感染症　新規陽性者数
# package_search("新型コロナウイルス感染症 新規陽性者数")
pac <- package_show("412b1e1c-7c05-443e-8c1f-e8dfcff57b91")
res <- pac$resources
url <- res %>% bind_rows() %>% pull(url)

tmp <- read_csv(url, skip = 1, col_types = "___D_dd", 
                col_names = c("date", "detected", "detected_cum")) %>% 
  filter(date >= as.Date("2021-01-01") - 7)

write_csv(tmp, "data/newlycases.csv")

# 福岡県　新型コロナウイルス感染症　検査陽性者の状況
# package_search("新型コロナウイルス感染症 検査陽性者の状況")
pac <- package_show("fe943202-2db4-44f8-9686-9cf682690bb7")
res <- pac$resources
url <- res %>% bind_rows() %>% pull(url)

tmp <- 
  read_csv(url, col_types = "__Dcdddddddd") %>% 
  rename(date = 公表_年月日, weekday = 曜日) %>% 
  filter(date >= as.Date("2021-01-01") - 7) %>% 
  pivot_longer(-(date:weekday)) 

write_csv(tmp, "data/situation.csv")

# 福岡県　新型コロナウイルス感染症　検査実施数
# package_search("新型コロナウイルス感染症 検査実施数")
pac <- package_show("ef64c68a-d89e-4b1b-a53f-d2535ebfa3a1")
res <- pac$resources
url <- res %>% bind_rows() %>% pull(url)

tmp <- 
  read_csv(url,
           col_types = "___D_____dd", skip = 1,
           col_names = c("date", "inspected", "inspected_cum")) %>% 
  filter(date >= as.Date("2021-01-01") - 7)

write_csv(tmp, "data/inspection.csv")

# 福岡県　新型コロナウイルス感染症　確保病床数及び宿泊療養居室数
# package_search("新型コロナウイルス感染症 確保病床数及び宿泊療養居室数")
pac <- package_show("c9efc321-6c10-448b-a859-555fd9ae8726")
res <- pac$resources
url <- res %>% bind_rows() %>% pull(url)

tmp <- 
  read_csv(url, col_types = "__D_ddd", skip = 1,
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
