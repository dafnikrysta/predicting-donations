# predicting-donations


# DSC Re-Activation Campaign Project 

## Project Definition 


Using historical data from past reactivation campaigns, we want to predict which donors will be more likely to donate more than 35 € for the DSC re-activation campaign.

This model will be used to support the decision-making process and answer the following question: 

**How many donors  need to be reached to gain the maximum profit?**

Datasets: Donors & Gifts Datasets were used
Only included data before April 11th, 2013 

Target Period: 11/04/2013 - 15/01/2014

# Variable Creation 

## Continuous Variables

* Sum_donated : sum amount donated per DonorId 
* Avg_donated : mean amount donated per DonorId 
* Min_donated : minimum amount donated per DonorId 
* Max_donated : maximum amount donated per DonorId 
* Recency : time elapsed between last donation and the start of the target period (in days) per DonorId 


## Dummy Variables

* Language :  0: Non-French , 1: French
* Gender: 5 levels: C, F, S, M, U
* Location: split into 3 Belgian regions based on zipcode

  * Flanders
  * Brussels 
  * Wallonia


# **Model Building**

Target Definition: Binary classification 

If donated  > 35 € then 1 
If donated  < 35 € then 0

Train dataset: Campaign 2013 containing 34,917 observations 

**Target incidence: 0.0059 / (206 targets)**

Test dataset: Campaign 2014 containing 25,645 observations

## Result of Feature Selection Algorithm

1. Recency
2. Language 
3. U
4. S
5. F
6. sum_donated
7. nbrs_donations
8. Brussels
9. C
10. M
11. Wallonia
12. Flanders
13. max_donated
14. min_donated
15. avg_donations

## **Results of AUC**

* AUC train: 0.59
* AUC test: 0.57

The result of the AUC curve shows that the variable "S" at index 4 is decreasing the performance of the test curve
We decided to take out the variables "U", "S","C" (related to the gender category) and rerun the model.

  
## **Optimising the Model – Final Variable Selection**

The number of variables was reduced to 8:
* The test and train are performing similarly
* AUC train: 0.5832
* AUC test: 0.5833
There is no overtraining, because the test AUC is slightly higher than the train AUC 

## **Evaluation of the Final Model**

Final Variables in the order of selection:

1. Rencency  
2. Language 
3. Male 
4. sum_donated
5. nbrs_donations
6. Brussels
7. max_donated
8. min_donated

**The highest significance values are recency p<0.001, language and sum donated  p<0.01, male and numbers of donation p<0.05**

* The Cumulative Gains curve indicated slightly better performance than random
* The Lift curve showed better model performance for the test than the target dataset. 
* This trend is also reflected in AUC curves.  
  * Train Target Incidence:   0.0059
  * Test Target Incidence:    0.0148

* Overall the model would be better if we had stratified the target in order to include equal percentages of targets  in both train and target data sets.

# **Alternative Model – Decision Tree**

* The Output contained only one root node. 
* We had to decrease : minsplit and minbucket to get a result. 
* The result was not very easily interpretable- many nodes
* Possible reason: too many observations with a low target incidence


**Interpretation of Variables:**

**1. Recency**

* The more time elapsed (recency) between the last donation and start of target period, the less likely the donor will donate

**2. Language**

* If the donor does not speak French, he/she will be more likely to donate 

**3. Gender**

*  Male donors are more likely to donate 

**4. Number of Donations**

* Donors that donated more than 42 times are less likely to donate 

**5. Maximum Amount Donated**

* Donors with a maximum amount donated greater than 142€ are less likely to donate again

**6. Sum Amount Donated**

* The largest the sum donated by a donor, the more likely he/she will donate 

**7. Min Amount Donated**

* Donors with higher minimum amount donated are more likely to donate 

**8. Region**

* Donors from Brussels are less likely to donate 

# Business Case

* What percentage of the donor population should we reach to get the maximum possible profit from our reactivation campaigns?

Need to consider:

 * Target Incidence: average target incidence of the test & training datasets 
 * Reward per Target:  mean amount donated by each target in the test and training datasets
 * Population size: total number of donors in the Donors database 

* To inform the business decision: 

**Tool: Lift Graph**

* We calculated the profits of our campaign based on the lift curve 
* Expected profits were calculated as a function of percentage of donors selected 
* Selected the percentage yielding maximum profit

## **Business Case Solution**

* DSC will make maximum profit by sending letters to 30% of the candidate donors 
* Based on our model, maximum profits will be generated (3,126 €) by addressing 30% of the donors.

