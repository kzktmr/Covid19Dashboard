# Get Data
library(dplyr)
library(tidyr)
library(readr)
library(ckanr)
library(httr)
library(ndjson)

ckanr_setup(url = "https://ckan.open-governmentdata.org/")

# 福岡県　新型コロナウイルス感染症　陽性者発表情報
# res <- resource_show("0430a12e-568c-4a6a-bed8-51621f47c6e5")
# res <- resource_show("419f6cff-e74a-49b3-9f3c-7b425e5f5228")
res <- resource_show("9d32b7ee-5bfe-4b3c-a582-ea56f3b0afd9")

tmp <- read_csv(res$url, skip = 1, col_types = "___D_cccl__",
                col_names = c("date", "address", "age", "sex", "untraceable")) %>% 
  filter(!is.na(date), date >= as.Date("2021-01-01") - 7)
  
write_csv(tmp, "data/patients.csv")

# 福岡県　新型コロナウイルス感染症　新規陽性者数
# res <- resource_show("bd25a096-b060-428a-bc85-91c1715fc540")
# res <- resource_show("949b90ee-25df-4423-a8f4-d58295676339")
res <- resource_show("3e306520-17e0-4684-8b88-bddf748c68bd")

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
tmp <- tibble(date = c(as.Date("2021-01-01"), Sys.Date())) %>% 
  complete(date = full_seq(date, 1)) %>% 
  mutate(bed = case_when(date < "2021-01-06" ~ 576,
                         date < "2021-01-08" ~ 600,
                         date < "2021-01-13" ~ 610,
                         date < "2021-01-20" ~ 620,
                         date < "2021-01-21" ~ 641,
                         date < "2021-01-22" ~ 651,
                         date < "2021-01-27" ~ 665,
                         date < "2021-02-04" ~ 691,
                         date < "2021-02-08" ~ 710,
                         date < "2021-02-10" ~ 721,
                         date < "2021-02-18" ~ 732,
                         date < "2021-02-24" ~ 742,
                         date < "2021-03-19" ~ 764,
                         date < "2021-04-15" ~ 770,
                         date < "2021-04-27" ~ 802,
                         date < "2021-04-28" ~ 807,
                         date < "2021-04-30" ~ 858,
                         date < "2021-05-03" ~ 921,
                         date < "2021-05-07" ~ 940,
                         date < "2021-05-11" ~ 1007,
                         date < "2021-05-14" ~ 1049,
                         date < "2021-05-19" ~ 1144,
                         date < "2021-05-25" ~ 1206,
                         date < "2021-05-28" ~ 1298,
                         date < "2021-06-04" ~ 1346,
                         date < "2021-06-10" ~ 1359,
                         date < "2021-06-17" ~ 1375,
                         date < "2021-07-02" ~ 1403,
                         date < "2021-08-12" ~ 1413,
                         date < "2021-08-17" ~ 1423,
                         date < "2021-08-18" ~ 1433,
                         date < "2021-08-20" ~ 1444,
                         date < "2021-08-24" ~ 1455,
                         date < "2021-08-27" ~ 1460,
                         date < "2021-09-06" ~ 1472,
                         date < "2021-09-22" ~ 1475,
                         date < "2021-09-29" ~ 1480,
                         date < "2021-12-21" ~ 1482,
                         TRUE ~ 1558))
write_csv(tmp, "data/sickbeds.csv")

# ワクチン接種状況
tmp_file <- tempfile()

GET("https://vrs-data.cio.go.jp/vaccination/opendata/latest/prefecture.ndjson") %>% 
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