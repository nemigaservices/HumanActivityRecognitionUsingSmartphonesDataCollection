# Data Collection for Human Activity Recognition Using Smartphones 
R files for creating tidy dataset to analyze Human Activity Recognition Using Smartphones for Coursera Getting and Cleaning Data course project

## Purpose 
The purpose of the script is to read the data for Human Activity Recognition Using Smartphones and compile two datasets:
* Dataset containing ID of the subject, ID of the activity performed, and means/standard deviations of all the measurements. _Resulting dataset contains both training and test data_.__The dataset is returned as the result of the excution of the script.__ 
* Summary dataset that contains the averages of all standard deviations and means in the prior dataset grouped by subject and activity. __This dataset is saved as a CSV file.__
General information about the data collection can be found at [link](http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones). 
Details about the contents of the dataset can be found in the CodeBook.
_Unless specified, the script is using [link](https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip) as the data source._

## What the script does
The data stored in archive contains:
* Reference between Activity ID and Activity Name (specified in activity_labels.txt)
* List of the features - i.e. names of the columns in the values dataset (specified in features.txt)
* Train and test datasets (respectively in _train_ and _test_ directories) each one containing:
- File with subject IDs where each row corresponds to a single observation (subject_tests.txt)
- File with activity IDs where each row corresponds to a single observation (y_test/train.txt)
- File with sensor readings where each row corresponds to a single observation (X_test/train.txt)

### Script execution
1. For both training and test datasets, the script:
* Loads the sensor readings (X_test/train.txt file)
* Removes the columns that do not contain mean or standard deviation. In order to achieve that, the script reads the list of the features into another dataset and removes the features whose names do not contain _mean_ or _std_. Afterwards the script uses the resulting dataset to determine which columns should be kept in the sensors readings. The resulting columns of the sensors are renamed to match the names of the features as specified in features.txt.
* Adds the column with the Subject Ids
* Adds the column with Activity information. This column contains the names of the activities that are achieved by joining the data read from the activities Ids (y_test/train.txt file) with the activiy labels (file activity_labels.txt). 
2. Combines both train and test data
3. Generates and saves the summary data file with the averages of all sensor data variables by Subject and Activity. The file contains similar columns (See CodeBook.md) where the "Avg-" is added to the column names to indicate that they contain averages.

## Installation instructions
* Download run_analysis.R to your current R directory
* Load the script by executing:
_source('run_analysis.R')_
* Execute the script 
_ds<-generateAnalysisDataAndSummaryData()_

### Script parameters
* __fileUrl__, default _NULL_. If specified, uses the URL to specify the location with an archive. If not specified (NULL) uses default file mentioned above.
* __saveFile__, defalut _humanActivityRecognitionUsingSmartPhonesAvgBySubjectAndActivity.csv_. Allows specifying the path/name for the CSV file with averages of the means and standard deviations for the sensors readings.

### Dependences
Script is dependent on the following libraires: dplyr, plyr, reshape2

__Script should install and load the necessary libraries.__
