# check for existance of the packages and install them as necessary
if (!require(dplyr, quietly = TRUE)) install.packages('dplyr')
library(dplyr)
if (!require(plyr, quietly = TRUE)) install.packages('plyr')
library(plyr)

# Reads the activity labels and renames the fields for easier join to activityId, activityName
readActivityLabels<-function(rootDirectory){
    activityLabelsPath<-paste(rootDirectory,.Platform$file.sep,'activity_labels.txt', sep="")
    activityLabels<-read.table(activityLabelsPath)
    activityLabels<-dplyr::rename(activityLabels, activityId=V1, activityName=V2)
    activityLabels
}


# Reads the file with the columns definitions ("features.txt") and only leaves the columns of interest - the ones
# that contain 'mean' or 'std'
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
# colDefs - definitions of columns that are to be left in the dataset
# activityLabels - definitions of activity 
createDataSet<-function(rootDirectory, type, colDefs,activityLabels){
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
# cleansing and combining the data from test and train
generateDataSet<-function(rootDirectory){
    # Read activityLabels data
    activityLabelsDs<-readActivityLabels(rootDirectory)
    
    # Read columns definitions
    colDefsDs<-readAndSelectColumnsDefinitions(rootDirectory)
    
    # Read test data
    ds<-createDataSet(rootDirectory,type = "test",colDefs = colDefsDs, activityLabels = activityLabelsDs)
    
    # Read train data
    trainDs<-createDataSet(rootDirectory,type = "train",colDefs = colDefsDs, activityLabels = activityLabelsDs)
    
    # Combine together
    ds<-rbind(ds, trainDs)
    ds
}

