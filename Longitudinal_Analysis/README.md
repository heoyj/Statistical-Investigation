# Longitudinal Analysis

## Analyze Efficacy of Emotional Exposure Therapy (EET) for Fibromyalgia (FM) in Randomized Clinical Trial

Fibromyalgia (FM) is a chronic disorder that causes widespread musculoskeletal pain, fatigue, and tenderness. Since the conventional interventions, which target behaviors and cognition, have limited efficacy, a two-site, three-arm, allegiance-controlled randomized clinical trial (RCT) for FM investigated the benefit of emotional exposure therapy (EET). In order to test the efficacy of EET compared to Cognitive-Behavioral Therapy (CBT) and FM Education (EDU), a linear spline generalized estimating equation (GEE) was applied to the clinical trial dataset. The GEE model showed that the efficacy of EET was beneficial to 3 months follow-up (p-value < 0.001) compared to the EDU (p-value = 0.007), but there was no difference between EET and CBT (p- value = 0.530).

## Introduction

More than 3 million Americans per year suffer from fibromyalgia (FM), which is a disorder accompanied by widespread muscle pain, tenderness and fatigue and therefore, affect people’s mood. FM cannot be cured, and conventional approaches to FM have only targeted relief of behaviors and cognition symptoms. According to the updated pain definition [1], FM pain is defined as a distressing experience associated with actual or potential tissue damage with sensory, emotional, cognitive, and social components. Moreover, it has been shown that psychological interventions help to manage patients’ chronic pain [2]. Thus, it is important to consider psychological treatment for mitigation of the chronic pain for FM. Previous smaller studies suggest that the techniques involving emotional exposure and processing are efficacious for FM. However, these components had not been combined into a theoretically integrated emotional exposure therapy (EET) and the efficacy of EET had not been tested in a controlled, clinical trial. Therefore, a multi-site group randomized clinical trial (RCT) [3] examined the efficacy of EET, which targets psychological treatment for reducing stress, compared to the conventional interventions, cognitive-behavioral therapy (CBT) and FM education (EDU). The EET encouraged patients to disclose stressful experiences and increase expression of emotions through weekly sessions and homework. CBT focused on cognitive and behavioral exercises to manage FM symptoms rather than the emotional factor. EDU provided knowledge about FM in terms of its definition, diagnoses, medications and research methods in order to increase patient’s understanding and thus, decrease uncertainty and reduce defensiveness. Through RCT, the main interest of outcome was pain reduction following treatments.

## Methods

This clinical trial design was a 2-site, 3-arms, allegiance-controlled RCT. At the Wayne State University and the University of Michigan, participants were recruited and evaluated through screening processes by inclusion and exclusion criteria from the trial protocol. A total of 230 adults (94% female, n = 216, mean age of females = 49.5) with FM were assigned randomly to small groups. Each group provided one of three treatments, EET, CBT, and EDU. Through eight weekly small-group sessions, the three treatments were compared on key health outcomes, such
as clinical and psychophysical pain testing, subjective disability and objective physical activity, fatigue, mood, and sleep problems at baseline, 3- and 9-month follow-up evaluation. Since the research question was to compare the efficacy of EET compared to CBT and EDU in terms of pain relief, the primary outcome measurement was the subjective clinical pain evaluated from the Brief Pain Inventory (BPI; 162), which assess current pain and highest, lowest, and average pain during the past week. Each BPI has scale from 0 to 10, and the lower scale is, the less pain occurs. The pain score from the four items was averaged in order to combine all the pain severity. Since the depressive symptoms and anxiety symptoms were collected for secondary outcome measures, they were not included in this analysis in order to address the main research question. Demographic variables were collected, including age, gender, body mass index (BMI), ethnicity, race, highest educational level, total tender points, fibromyalgianess, and a score of symptoms evaluated by Complex Medical Symptoms Inventory. In order to check the validity of randomization, the demographic variables at baseline were compared across three treatments. For continuous variables, one-way ANOVA test and Kruskal-Wallis test were conducted respectively if the data followed normal and non-normal distributions in order to compare the means across treatments. In the case of categorical/binary variables, the Chi-square test and Fisher’s exact test were applied to test the difference in proportions between treatments. If the randomization was valid and there were no other risk factors, such as a site effect, then it would guarantee that the treatments are the only factor to contribute to the outcome, pain score in a longitudinal analysis model. Since a generalized estimating equation (GEE) enables to analyze the repeated measurements in a marginal level, the data was modeled with a spline GEE model based on a mean trend plot and the validity of randomization. When it comes to modeling, a covariance structure for repeated outcome measurements was determined based on the form of unstructured covariance for the values. With the specified covariance structure, coefficients from the fitted GEE model were estimated and tested by comparing two nested models. Finally, residuals from the fitted GEE model were used to do diagnostics. For missing values, the percentages of missingness were evaluated, which implicated how to deal with the missingness in this dataset. The longitudinal analysis was conducted in R and specifically the ‘geepack’ package[4] was used to fit GEE models.

## Results

At baseline, each demographic variable were examined across treatments in order to check the validity of randomization. According to Appendix Table A1, FM patients were randomly assigned to each treatment arm. Moreover, the effect of different site was tested across treatment arms and there was no evidence to say that interventions were different from sites (p-value = 0.2). This implied that the stratification was not necessary in modeling process. Figure 1 suggests that a linear spline pattern for each treatment over time, therefore, the linear spline GEE model was selected to model the dataset. Based on the validity of randomization and the spline pattern for the repeated measurements of pain score, the linear spline GEE model was fitted to the dataset.


__Figure 1.__ Mean trend plots of the pain score for three treatments (EET, CBT and EDU).
The mean trend plots for treatments suggest a linear spline GEE model for the RCT. Time (Baseline, 3 months and 9 months) indicates that baseline, post-treatment and 6 months follow-up, respectively. EET and CBT show decreasing first and increasing again over time, whereas EDU shows decreasing pattern over time.

In order to make easy interpretations, EET was chosen to be a reference treatment. For a covariance structure, an exchangeable covariance structure was selected based on empirical correlation matrix of pain scores over time. The ‘geeglm’ function from ‘geepack’ package in R was applied to estimate parameters with its standard error based on a sandwich variance estimator, which are shown in Table 1.

__Table 1.__ Parameter estimates and standard errors (based on sandwich variance estimator) from marginal regression model for the pain score. 

| Variable   |   Estimate   |     SE    |   Chi-square statistic   | Wald 95% CI   |   p-value   | 
| -----------|:------------:|:------------:|:------------:|:------------:|:------------:|
|(Intercept) | 5.39  | 0.11 | 2520.99 | (50.00 , 50.42) | < 0.001 |
| Time       | -0.31 | 0.07 | 19.10 | (-4.51 , -4.23) | < 0.001 |
| (Time − 3)+ | 0.22 | 0.06 | 13.62 | (3.58 , 3.81) | < 0.001 |
| Time × CBT | 0.10 | 0.09 | 1.21 | (0.93 , 1.28) | 0.271 |
| (Time − 3)+ × CBT| -0.06 | 0.08 | 0.08 | (-0.98 , -0.67) | 0.411 |
| Time × EDU  | 0.26 | 0.09 | 8.27 | (2.70 , 3.05) | 0.004 |
|(Time − 3)+ × EDU | -0.23 | 0.08 | 9.34 | (-3.20 , -2.91) | 0.002 |


Since the three treatments were randomly assigned at baseline, the treatment effect was not included in the linear spline GEE model.
(Intercept) indicates that the EET effect at baseline.
(𝑥)! = 𝑥 if 𝑥>0, 0 otherwise.
SE : sandwich variance estimator.
Estimated scale parameter: 𝜙 = 3.21. Estimated working correlation: 𝛼 = 0.57.

|             |          Grouping           ||
First Header  | Second Header | Third Header |
 ------------ | :-----------: | -----------: |
Content       |          *Long Cell*        ||
Content       |   **Cell**    |         Cell |

New section   |     More      |         Data |
And more      | With an escaped '\|'         || 

