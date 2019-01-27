
####################################################################################################################################
########################################### DONORS CAMPAIGN PREDICTIVE MODEL #######################################################
####################################################################################################################################

############################################# Installing Packages for future analysis ##############################################

install.packages("plyr")
library("plyr")
install.packages("tidyr")
library("tidyr")
install.packages("lubridate")
library("lubridate")
install.packages("pROC")
library(pROC)
install.packages("dplyr")
library("dplyr")

############################################# READING THE DATA SETS ##################################################################

# Read the data campaign2013, campaign2014, donors, and gifts
rcampaign2013 = read.table("C:/Users/dkrystallidou/Documents/Descriptive Predictive Analytics/Group Project/campaign20130411.csv",sep=";",header = TRUE)
rcampaign2014 = read.table("C:/Users/dkrystallidou/Documents/Descriptive Predictive Analytics/Group Project/campaign20140115.csv",sep=";",header = TRUE)
donors = read.table("C:/Users/dkrystallidou/Documents/Descriptive Predictive Analytics/Group Project/donors.csv",sep=";",header = TRUE,stringsAsFactors = FALSE)
gifts = read.table("C:/Users/dkrystallidou/Documents/Descriptive Predictive Analytics/Group Project/gifts.csv",sep=";",header = TRUE, stringsAsFactors = FALSE)

############################################ CLEANING AND CONSTRUCTING THE DATASETS ###################################################

### CLEANING GIFTS DATASET ###

# Getting the list of unique donorsID in the gifts dataset 
uniquegifts<-unique(gifts$donorID)
head(uniquegifts)

# Changing the format of the dates in the gifts dataset
gifts$date <- as.Date(gifts$date,"%d/%m/%Y")

#Deleting data that are inside our target period; it means deleting all the information that we have after 2013-04-10
gifts_filter <- with(gifts, gifts[(date < "2013-04-11"), ])

# For each unique donorID, we calculated the total amount they donated, the maximum amount, the minimum amount, the number of times they donated and the lastest date for which they donated
gifts2<-ddply(gifts_filter,.(donorID),summarize,sum_donated=sum(amount),max_donated=max(amount),min_donated=min(amount), avg_donations = sum(amount)/length(amount),nbrs_donations = length(amount),last_donation_date= max(date),.drop = FALSE)

### CLEANING DONORS DATASET ###

#Creating columns containing dummy variables for each level of gender
donors2<-spread(donors,gender, gender)
donors2$C <- ifelse(donors2$C == 'C',1,0)
indexC <- which(is.na(donors2$C))
donors2$C[indexC] <- 0

donors2$M <- ifelse(donors2$M == 'M',1,0)
indexM <- which(is.na(donors2$M))
donors2$M[indexM] <- 0

donors2$F <- ifelse(donors2$F == 'F',1,0)
indexF <- which(is.na(donors2$F))
donors2$F[indexF] <- 0

donors2$S <- ifelse(donors2$S == 'S',1,0)
indexS <- which(is.na(donors2$S))
donors2$S[indexS] <- 0

donors2$U <- ifelse(donors2$U == 'U',1,0)
indexU <- which(is.na(donors2$U))
donors2$U[indexU] <- 0

#Creating a dummy variable for language, if it is F then put 1, else if its N put 0
donors2$language <-ifelse(donors2$language == 'F' , 1 ,0 )

### CREATING NEW DATASET OF ALL VARIABLES AVAILABLE ###

# Merging donors and gifts datasets
clean_Vars <- merge(donors2,gifts2, by= "donorID", all.x = TRUE, sort = TRUE)


# Adding recency variable where lowest values indicate most recent donations
clean_Vars$recency<- (ymd("2013-04-10") - clean_Vars$last_donation_date)

#creating 3 new columns for the 3 differents regions of belgium: Flanders, Wallonia, and Bruxelles
clean_Vars$Flanders <- ifelse(clean_Vars$zipcode %in% c(1500:3999,8000:9999),1,0)
clean_Vars$Brussels <- ifelse(clean_Vars$zipcode %in% c(1000:1299),1,0)
clean_Vars$Wallonia <- ifelse(clean_Vars$zipcode %in% c(1300:1499,4000:7999),1,0)


### CREATING THE TRAIN AND TEST DATASETS ###

# calculating the target for rcampaign2013, target 1 donated more than 35 euros, target 0 didn't donate or donated less than 35 euros
dummy_campaign2013 <- rcampaign2013
dummy_campaign2013$amount <-ifelse(dummy_campaign2013$amount >35,1,0) 

#renaming target column for campaign2013
colnames(dummy_campaign2013)[2]<-"Target"

# calculating the target for rcampaign2014, target 1 donated more than 35 euros, target 0 didn't donate or donated less than 35euros
dummy_campaign2014 <- rcampaign2014
dummy_campaign2014$amount <-ifelse(dummy_campaign2014$amount >35,1,0) 

#renaming target column for campaign2014
colnames(dummy_campaign2014)[2]<-"Target"

# creating train dataset by merging cleaned variables with rcampaign2013  
finaltrain   <- merge(dummy_campaign2013,clean_Vars, all.x = FALSE , sort = TRUE)

#creating test dataset by merging cleaned variables with rcampaign2014 
finaltest   <- merge(dummy_campaign2014 ,clean_Vars, all.x = FALSE , sort = TRUE)

#Reordering columns to put the target column at the end of our basetable
finaltest  <- finaltest[, c("donorID","language","zipcode","region","Flanders","Brussels","Wallonia","C","F","M","S","U","sum_donated","max_donated","min_donated","avg_donations","nbrs_donations","last_donation_date","recency","Target")]
finaltrain<- finaltrain[, c("donorID","language","zipcode","region","Flanders","Brussels","Wallonia","C","F","M","S","U","sum_donated","max_donated","min_donated","avg_donations","nbrs_donations","last_donation_date","recency","Target")]

# Constructing the basetable with the variables that we are going to use in the stepwise logistic regression
finaltrain_stepw<-finaltrain[,c("language","Flanders","Brussels","Wallonia","C","F","M","S","U","sum_donated","max_donated","min_donated","avg_donations","nbrs_donations","recency","Target")]
finaltest_stepw<-finaltest[,c("language","Flanders","Brussels","Wallonia","C","F","M","S","U","sum_donated","max_donated","min_donated","avg_donations","nbrs_donations","recency","Target")]

######################################################### STEPWISE LOGISTIC REGRESSION ############################################

### AUC FUNCTION ###
# Custom function to calculate AUC: 
auc = function(trueval, predval){
  df = as.data.frame(cbind(trueval,predval))
  names(df) = c("trueval","predval")
  auc = roc(trueval~predval,data=df)$auc
  return(auc)
}
# All possible variables:
variables = head(names(finaltrain_stepw),-1)
variablesorder = c()

# Construct a logistic regression model with no variables
model = glm(Target ~ 1,data=finaltrain_stepw,family=binomial)

# Construct a formula with all the variables
formula<-formula(paste("Target","~",paste(variables,collapse="+")))

#Loop over the steps
for(i in c(1:length(variables))){
  #calculate AIC of each model
  info = add1(model,scope=formula,data=finaltrain_stepw)
  #get variable with highest AIC
  orderedvariables = rownames(info[order(info$AIC),])
  v = orderedvariables[orderedvariables!="<none>"][1]
  #add variable to formula
  variablesorder = append(variablesorder,v)
  formulanew = formula(paste("Target","~",paste(variablesorder,collapse = "+")))
  model = glm(formulanew,data=finaltrain_stepw,family=binomial)
  print(v)
}

auctrain = rep(0,length(variablesorder)-1)
auctest = rep(0,length(variablesorder)-1)

for(i in c(1:(length(variablesorder)-1))){
  vars = variablesorder[0:i+1]
  print(vars)
  formula<-paste("Target","~",paste(vars,collapse="+"))
  model<-glm(formula,data=finaltrain_stepw,family="binomial")	
  predicttrain<-predict(model,newdata=finaltrain_stepw,type="response")
  predicttest<-predict(model,newdata=finaltest_stepw,type="response")
  auctrain[i] = auc(finaltrain_stepw$Target,predicttrain)
  auctest[i] = auc(finaltest_stepw$Target,predicttest)
} 


#SOLUTION
plot(auctrain, main="AUC", col="red",ylim= c(0.55, 0.60), ylab = " ")
lines(auctest,col="blue", type="p")

legend("bottom", legend=c("Train","Test"), ncol=2,bty="n",
       col=c("red", "blue"), lwd = 2)


#Select the model with optimal number of variables:
finalvariables = variablesorder[c(0:8)]
formula<-paste("Target","~",paste(finalvariables,collapse="+"))
model<-glm(formula,data=finaltrain_stepw,family="binomial")	
predicttrain<-predict(model,newdata=finaltrain_stepw,type="response")
predicttest<-predict(model,newdata=finaltest_stepw,type="response")
#Calculating the auctrain and auctest with our selected variables
auctrain = auc(finaltrain_stepw$Target,predicttrain)
auctest = auc(finaltest_stepw$Target,predicttest)

#################################################################################################################################
################################# AFTER EVALUATION REMODELING OF OUR VARIABLES IN THE BASETABLE##################################

# After evaluating the AUC curve from the test and train dataset, we came to the conclusion that gender "S" is decreasing
# the performance of the test model, so we will try to rerun the analysis without this variable.

finaltrain_stepw_adj<-finaltrain[,c("language","Flanders","Brussels","Wallonia","F","M","sum_donated","max_donated","min_donated","avg_donations","nbrs_donations","recency","Target")]
finaltest_stepw_adj<-finaltest[,c("language","Flanders","Brussels","Wallonia","F","M","sum_donated","max_donated","min_donated","avg_donations","nbrs_donations","recency","Target")]

#### STEPWISE LOGISTIC REGRESSION WITHOUT VARIABLE "S", "U", and "C" ###

# All possible variables:
variables = head(names(finaltrain_stepw_adj),-1)
variablesorder = c()

# Construct a logistic regression model with no variables
model = glm(Target ~ 1,data=finaltrain_stepw_adj,family=binomial)

# Construct a formula with all the variables
formula<-formula(paste("Target","~",paste(variables,collapse="+")))

#Loop over the steps
for(i in c(1:length(variables))){
  #calculate AIC of each model
  info = add1(model,scope=formula,data=finaltrain_stepw_adj)
  #get variable with highest AIC
  orderedvariables = rownames(info[order(info$AIC),])
  v = orderedvariables[orderedvariables!="<none>"][1]
  #add variable to formula
  variablesorder = append(variablesorder,v)
  formulanew = formula(paste("Target","~",paste(variablesorder,collapse = "+")))
  model = glm(formulanew,data=finaltrain_stepw_adj,family=binomial)
  print(v)
}

auctrain = rep(0,length(variablesorder)-1)
auctest = rep(0,length(variablesorder)-1)

for(i in c(1:(length(variablesorder)-1))){
  vars = variablesorder[0:i+1]
  print(vars)
  formula<-paste("Target","~",paste(vars,collapse="+"))
  model<-glm(formula,data=finaltrain_stepw_adj,family="binomial")	
  predicttrain<-predict(model,newdata=finaltrain_stepw_adj,type="response")
  predicttest<-predict(model,newdata=finaltest_stepw_adj,type="response")
  auctrain[i] = auc(finaltrain_stepw_adj$Target,predicttrain)
  auctest[i] = auc(finaltest_stepw_adj$Target,predicttest)
} 

#SOLUTION

plot(auctrain, main="AUC", col="red",ylim= c(0.55, 0.60), ylab = " ")
lines(auctest,col="blue", type="p")

legend("bottom", legend=c("Train","Test"), ncol=2,bty="n",
       col=c("red", "blue"), lwd = 2)

#Select the model with optimal number of variables:
finalvariables = variablesorder[c(0:8)]
formula<-paste("Target","~",paste(finalvariables,collapse="+"))
model<-glm(formula,data=finaltrain_stepw_adj,family="binomial")	
predicttrain<-predict(model,newdata=finaltrain_stepw_adj,type="response")
predicttest<-predict(model,newdata=finaltest_stepw_adj,type="response")
# New auctrain and auctest with the selected variables
auctrain = auc(finaltrain_stepw_adj$Target,predicttrain)
auctest = auc(finaltest_stepw_adj$Target,predicttest)


########################################################## CUMULATIVES GAINS CURVES ####################################################

install.packages("ROCR")
library(ROCR)
# You can use this package to construct for instance a cumulative gains curve as follows: 
# Make an object that contains the true values and the predictions:
pred <- prediction(predicttest,finaltest_stepw_adj$Target)
# Calculate the necessary data
perf <- performance(pred,
                    "tpr","fpr")
# Plot the cumulative gains curve:
plot(perf, main="Cumulative gains", col="blue")
abline(a=0, b=1, col = 'red')


############################################################# LIFT CURVE ##############################################################
pred <- prediction(predicttest,finaltest_stepw_adj$Target)
perf <- performance(pred,"lift","rpp")
#plot(perf, main="lift curve", col="blue")
plot(perf, main="lift curve", col="blue", lab = c(10,6,3), ylim= c(0, 6))

pred <- prediction(predicttrain,finaltrain_stepw_adj$Target)
perf <- performance(pred,"lift","rpp")
par(new=TRUE)
plot(perf, main="lift curve", col="red", ylim= c(0, 6))
legend("bottom", legend=c("Train","Test"), ncol=2,bty="n",
       col=c("red", "blue"), lwd = 2)


############################################################ DECISION TREES ############################################################

install.packages("rpart.plot")
library("rpart.plot")

# Creating a new train data set with 500 observations to plot the decision tree
finaltrain_dt <-  finaltrain_stepw_adj[1:1000,]
finaltrain_dt$Target <- as.factor(finaltrain_dt$Target)

#Creating a new test data set with 500 observations to plot the decision tree
finaltest_dt <-  finaltest_stepw_adj[1:34000,]
finaltest_dt$Target <- as.factor(finaltest_dt$Target)


# Function to build the decisions trees on the test data set 
tree <- rpart(Target~., data= finaltest_dt, method = 'class', control=rpart.control(minsplit=2, minbucket=1, cp=0.001))
rpart.plot(tree, extra = 106)
predict(fit, finaltest_stepw_adj, type="class")

# Function to build the decisions trees on the train data set 
fit <- rpart(Target~recency, data= finaltrain_dt, method = 'class', control=rpart.control(minsplit=2, minbucket=1, cp=0.001))
rpart.plot(fit, extra = 106)

