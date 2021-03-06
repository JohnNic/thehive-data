#Project: data research on disability data
#Author: Rachel Huang
#Date:20150613
################################################################################
#checking files
wd<-getwd()
list.files(wd)

#install packages:
source("R/helper.R", TRUE)
source("R/dbpedia.R", TRUE)

pkgTest("xlsx")

#create an empty folder to hold all data
# folder <- function(folder.name){  
#   FN <- substitute(folder.name)
#   FN <- as.character(FN)
#   x <- paste(getwd(),"/", FN, sep="")
#   dir.create(x)
# }

# folder(data)
# folder(maps)
#files in the data folder
# list.files(paste0(wd,"/data"))
################################################################################
#read abs data
# autisum_2012_file <- read.xlsx("data/absdata_autisum_2012.xls",6)
# assistance_2012_file <- read.xlsx("data/absdata_needforassistance_2012.xls",1)
# assistance_2012_headers <- assistance_2012_file[,6]
# assistance_2012_headers
# x <- read.xlsx('data/absdata_needforassistance_2012.xls',2,header=FALSE)
# ,skip=4) 

#read Liam's data
#fix this function later
# read_files <- function(x,y) {
#                                 x <- read.csv(y,header=TRUE)                               
#                              }
# x = 
# y = 'location_quotient_by_pbc_2013.csv'
# read_files(x,y)


insolvency <- read.csv('data/aus_personal_insolvency_activity.csv',header=TRUE)
demographic <- read.csv('data/demographic_variables_by_pbc_2013.csv',header=FALSE)
education <- read.csv('data/early_childhood_education_and_care.csv',header=TRUE)
mesh_block_census <- read.csv('data/mb_mesh_block_2011_census.csv',header=TRUE)
railway_lines <- read.csv('data/psma_railway_lines.csv',header=TRUE)
railway_stations <- read.csv('data/psma_railway_stations.csv',header=TRUE)
public_toilets <- read.csv('data/public_toilets_2004_2014.csv',header=FALSE)
socioeconomic <-read.csv('data/socioeconomic_variables_by_pbc.csv',header=FALSE)
# str(demographic)

## to create a gigantic table by area (lethbridge park, mt. druitt, .....) to 
## include education, demographics, train services, public toilets, nearest train stations
## in future, we can roll this out to all areas of the country. (potential features of the model to predict the success of the business)
View(insolvency)
#insolvency by postcode
#link key: post code

View(education)
# education provider of the suburbs
# link key: suburb names

View(demographic) 
#population: gender proportion, age groups, suburb names, latitute and longitute
#link key: suburb names

View(mesh_block_census)  
#SA1,2,3,4 data  total dwellings of  the area, area names
#link key: area names


##cross join these two tables
View(railway_lines) 
#railline
View(railway_stations)
#rail way stations

View(public_toilets)
#public toilet info in the area
# link key: suburb names (the column name is town)
## dplyr to group by suburb names 

##########################CLEAN AND MERGE DATASETS######################################

#View(education),View(demographic),View(mesh_block_census) 

#dataset 1: demographic

#summarise by suburb names
demographic <- read.csv('data/demographic_variables_by_pbc_2013.csv',header=FALSE)

#rename the dataset
rename_1<-c("suburb_name","age75_","poll_id","state","male_proportion",
          "age35_44","age45_59","long_1","lat_1","long_2","lat_2",
          "age0_17","age18_22","age23_34","age60_74")
        
demographic <-demographic[-1,]
names(demographic)<-rename_1

# remove all special char:  gsub("[[:punct:]]", "", x)
#convert the below code to one function using regular expression

rm_specialchar_1 <- function(x) {
                                 substring(x,2,nchar(x))
                                }  

rm_specialchar_2 <- function(x) {
                                  substring(x,1,nchar(x)-1)
                                }  

#demographic <- mapply(rm_specialchar,long_1=demographic$long_1,lat_1=demographic$lat_2)
long_1 <- as.data.frame(apply(as.data.frame(demographic$long_1),1, rm_specialchar_1))
names(long_1)<-"long_1"
lat_2 <- as.data.frame(apply(as.data.frame(demographic$lat_2),1, rm_specialchar_2))
names(lat_2)<-"lat_2"

drops <- c("long_1","lat_2")
demographic <-demographic[,!(names(demographic) %in% drops)]
demographic <-cbind(demographic,long_1,lat_2)





#dataset 2: education
education <- read.csv('data/early_childhood_education_and_care.csv',header=TRUE)
education <- apply(education,2,function(x)tolower(x))
education <- as.data.frame(education,header=TRUE)   

# require(plyr)
# require(stringr)
education[,c(1:23)] <- colwise(str_trim)(education[, c(1:23)])                  #education raw data for maps
#education <- filter(education,overallrating == "meeting nqs")

education_summary <- education %>%
  group_by(suburb) %>%
  dplyr::summarize(child_education_provider = n())

education_summary <-as.data.frame(education_summary)

#dataset3: mesh_block_census  (# not sure how to use this one yet)
head(mesh_block_census,2)
unique(mesh_block_census$sa2_name11)
str(mesh_block_census)

#dataswt4:public_toilets
public_toilets <- read.csv('data/public_toilets_2004_2014.csv',header=FALSE)
names(public_toilets) <-c("parking","state","address","faility_type",
                          "icon_alt_text","sanitary_disposal",
                          "accessible_unisex","last_update_date","location_name",
                          "baby_change","parking_accessible","showers","toilet_type",
                          "is_open","sharps_disposal","accessible_female","status","opening_hours_note",
                          "accessible_note","male","payment_required","parking_note"
                          ,"accessible_parking_note","post_code","key_required","accessible_female",
                          "mlak","access_note","long_1","lat_1","long_2","lat_2",
                          "female","address_note","access_limited","opening_hours_scheduale",
                          "unisex","drinking_water","suburb_name","notes")

public_toilets <-public_toilets[-1,]
long_1 <- as.data.frame(apply(as.data.frame(public_toilets$long_1),1, rm_specialchar_1))
names(long_1)<-"long_1"
lat_2 <- as.data.frame(apply(as.data.frame(public_toilets$lat_2),1, rm_specialchar_2))
names(lat_2)<-"lat_2"


drops <- c("long_1","lat_2")
public_toilets <-public_toilets[,!(names(public_toilets) %in% drops)]
public_toilets <-cbind(public_toilets,long_1,lat_2)

public_toilets_summary <- public_toilets %>%
  group_by(suburb_name) %>%
  dplyr::summarize(total_public_toilet = n())


#dataset5:economic dataset
names(socioeconomic) <-c("buy_house","dis_ser_","ot_ch_","islamic","lone_p_h","la_for_",
                         "man_proportion","pentec_","uk","h_degree","trans_in","own_house","unemployment","catholic","overseas","add_ss_",
                         "c_no_c_h","suburb_name","c_diploma","no_religion","rent_house","soc_ser_","rou_pro_w_","se_eu","ex_in_","addre_5","o_n_c_r"
                         ,"d599_","per_ser","cwch","indigenous","state","poll_id","opfh","long_1","lat_1","long_2","lat_2","d600_2499","public_housing",
                         "m_east","anglican","internet","d2500","bus_fin","asia","inpsw")


socioeconomic<-socioeconomic[-1,]
#for_liam <- write.csv(unique(socioeconomic[,18]),file="data/westernsydney_suburbnames.txt")
long_1 <- as.data.frame(apply(as.data.frame(socioeconomic$long_1),1, rm_specialchar_1))
names(long_1)<-"long_1"
lat_2 <- as.data.frame(apply(as.data.frame(socioeconomic$lat_2),1, rm_specialchar_2))
names(lat_2)<-"lat_2"


drops <- c("long_1","lat_2")
socioeconomic <-socioeconomic[,!(names(socioeconomic) %in% drops)]
socioeconomic <-cbind(socioeconomic,long_1,lat_2)




##View all datasets cleaned
View(socioeconomic)
View(education_summary)
View(public_toilets)
View(demographic)

#trim all columns of all datasets before join
ncol(socioeconomic)
ncol(public_toilets)
ncol(demographic)

socioeconomic[,c(1:ncol(socioeconomic))] <- colwise(str_trim)(socioeconomic[, c(1:ncol(socioeconomic))])   
public_toilets[,c(1:ncol(public_toilets))] <- colwise(str_trim)(public_toilets[, c(1:ncol(public_toilets))])
demographic[,c(1:ncol(demographic))] <- colwise(str_trim)(demographic[, c(1:ncol(demographic))])
public_toilets_summary[,c(1:ncol(public_toilets_summary))] <- colwise(str_trim)(public_toilets_summary[, c(1:ncol(public_toilets_summary))])

#combining all four datasets
nrow(socioeconomic)

nrow(public_toilets_summary)
nrow(demographic)
nrow(education_summary)



names(socioeconomic)
library(reshape2)
melt_socioeconomic <- melt(socioeconomic,id=c("state","poll_id","suburb_name"))
melt_education_summary <- melt(education_summary,id=c("suburb"))
melt_demographic <- melt(demographic,id=c("state","poll_id","suburb_names"))
melt_public_toilets_summary <- melt(public_toilets_summary,id=c("suburb_name"))

melt_socioeconomic <-melt_socioeconomic[,-c(1,2)]
melt_demographic <-melt_demographic[,-c(1,2)]

names(melt_socioeconomic) <-c("location","key","value")
names(melt_education_summary) <-c("location","key","value") 
names(melt_demographic) <-c("location","key","value")  
names(melt_public_toilets_summary) <-c("location","key","value")  
 
all_data <- rbind(melt_socioeconomic,melt_education_summary,melt_demographic,melt_public_toilets_summary)



# Liam's data
dbpediaResults <- generateResults()
colnames(dbpediaResults)




