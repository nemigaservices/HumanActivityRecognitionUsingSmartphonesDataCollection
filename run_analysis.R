# check for existance of the packages and install them as necessary
if (!require(dplyr, quietly = TRUE)) install.packages('dplyr')
library(dplyr)
if (!require(plyr, quietly = TRUE)) install.packages('plyr')
library(plyr)
if (!require(reshape2, quietly = TRUE)) install.packages('reshape2')
library(reshape2)


# Reads the activity labels and renames the fields for easier join to activityId, activityName
# rootDirectory - root directory with the data files
# returns: definition of the activities (activityId and activityName)
readActivityLabels<-function(rootDirectory){
    activityLabelsPath<-paste(rootDirectory,.Platform$file.sep,'activity_labels.txt', sep="")
    activityLabels<-read.table(activityLabelsPath)
    activityLabels<-dplyr::rename(activityLabels, activityId=V1, activityName=V2)
    activityLabels
}


# Reads the file with the columns definitions ("features.txt") and only leaves the columns of interest - the ones
# that contain 'mean' or 'std'
# rootDirectory - root directory with the data files
# returns: definition of the colung (ColumnNumber and ColumnName)
readAndSelectColumnsDefinitions<-function(rootDirectory){
    pathColDefs<-paste(rootDirectory,.Platform$file.sep,'features.txt', sep="")
    colDefs<-read.table(pathColDefs)
    # leave only the columns with names containing 'std' or 'mean'
    colDefs<-colDefs[grepl("mean",colDefs$V2) | grepl("std",colDefs$V2),]
    colDefs<-dplyr::rename(colDefs, ColumnNumber=V1,ColumnName=V2)
    colDefs
}


# Reads the data from the specified director and and creates final dataset:
# - Reads the values data, leaves and renames only needed columns based on provided columns definitions
# - Reads the subject info data
# - Reads the activity info data and repaces the activity Id with the label based on the provided activity labels definitions
# - combines the dataset as subjectId, activityName, values
# rootDirectory - root directory with the data files
# type - type of the data. The only allowed values are 'train' or 'test'
# colDefs - definitions of columns that are to be used in the dataset
# activityLabels - definitions of activity 
createDataSet<-function(rootDirectory, type, colDefs, activityLabels){
    # Check the input
    if (!(type %in% c("train", "test"))){
        stop(paste("Cannot determine the type of the data to read: incorrect value ",type,". Allowed values: 'train' or 'test'"));
    }
    # read the subject information data
    pathSubject<-paste(rootDirectory,.Platform$file.sep,type,.Platform$file.sep,"subject_",type,".txt", sep="")
    subjectDs<-read.table(pathSubject)
    subjectDs<-dplyr::rename(subjectDs, subjectId=V1)
    
    # read the activity information data
    activityData<-paste(rootDirectory,.Platform$file.sep,type,.Platform$file.sep,"Y_",type,".txt", sep="")
    activityDs<-read.table(activityData)
    activityDs<-dplyr::rename(activityDs, activityId=V1)
    # replace activity ID with activity label using join and remove the ID column
    activityDs<-plyr::join(activityDs, activityLabels, type = "inner")
    activityDs<-activityDs[,2]
    
    # read the values data
    pathData<-paste(rootDirectory,.Platform$file.sep,type,.Platform$file.sep,"X_",type,".txt", sep="")
    ds<-read.table(pathData)
    # leave only needed columns using the columns definition dataframe
    ds<-ds[,colDefs$ColumnNumber]
    # rename the needed columns using the columns definition dataframe
    colnames(ds)<-colDefs$ColumnName
    
    # combine all together
    ds<-cbind(subjectDs,activityDs,ds)
    # need to rename the column
    ds<-dplyr::rename(ds, activityName=activityDs)
    ds
}


# Reads all the necessary data containing in the root directory and generates the dataset by
# cleansing and combining the data from test and traing datasets
# rootDirectory - root directory with the data files
# colDefs - definitions of columns that are to be used in the dataset
# returns: final dataset combined from test and training data that already prepared
generateDataSet<-function(rootDirectory, colDefs ){
    
    # Read activityLabels data
    activityLabelsDs<-readActivityLabels(rootDirectory)
        
    # Read test data
    ds<-createDataSet(rootDirectory,type = "test",colDefs = colDefs, activityLabels = activityLabelsDs)
    print(paste("Test data set contains ",nrow(ds)," rows."))
    
    # Read train data
    trainDs<-createDataSet(rootDirectory,type = "train",colDefs = colDefs, activityLabels = activityLabelsDs)
    print(paste("Train data set contains ",nrow(trainDs)," rows."))
    
    # Combine together
    ds<-rbind(ds, trainDs)
    print(paste("Final data set contains ",nrow(ds)," rows."))
    ds
}

# Generates tidy dataset by averaging the variables based on the subject Id and activity and saves it to the specified file in
# CSV format.
# dataset - source dataset used for generation
# colDefs - definitions of columns that are to be used in the dataset
# saveFile - path for the result file to save. 
generateTidyDataSetWithAverages<-function(dataset, colDefs, saveFile){
    # Melt the data
    dsMelt<-melt(dataset, id=c("subjectId", "activityName"), measure.vars=colDefs$ColumnName)
    # Generate the dataset
    tidyDs<-dcast(dsMelt, subjectId + activityName ~ variable, mean)
    # Rename the columns - add 'Avg-' to indicate the averages
    tidyColNames<-c("subjectId","activityName", paste("Avg-", colDefs$ColumnName, sep=""))
    colnames(tidyDs)<-tidyColNames
    # Save the data to a CSV file
    write.table(tidyDs, saveFile, row.names=FALSE)
    print(paste("Generated file",saveFile,"with ",nrow(tidyDs),"rows."))
}

# Main function to call.
# Downloads and unzips the data. Prepares the datasets (both training and test) by leaving only the columns of interest (means and standard deviations), adding
# the information about the subject and activity. Combines the resulted cleansed datasets into one and returns it.
# Generates the summary tidy datasets with averages for each variable by subject and activity.
# fileUrl contains the url for the file to download, if NULL is specified uses the default URL - the one that is given for the project
# saveFile - path for the result file to save. If not specified, file will be saved in the directory of execution with 
# the name humanActivityRecognitionUsingSmartPhonesAvgBySubjectAndActivity.csv
generateAnalysisDataAndSummaryData=function(fileUrl=NULL, saveFile="humanActivityRecognitionUsingSmartPhonesAvgBySubjectAndActivity.txt"){
    # download files 
    if (is.null(fileUrl))
        fileUrl<-"https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
    if (!file.exists("data")){
        dir.create("data")
    }
    download.file(url=fileUrl, destfile='./data/smartphonesdata.zip', method="curl")
    unzip('./data/smartphonesdata.zip', exdir = "./data")
    
    rootDirectory<-"./data/UCI HAR Dataset";
    
    # Read columns definitions
    colDefsDs<-readAndSelectColumnsDefinitions(rootDirectory)
    
    # generate combined cleansed dataset
    ds<-generateDataSet(rootDirectory, colDefsDs)
    
    # generate and save summary dataset
    generateTidyDataSetWithAverages(ds, colDefsDs, saveFile)
    ds
}
