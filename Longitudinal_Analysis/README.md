# Overview of Project

## 1. Project Goal

100 million individuals in the U.S. have chronic pain, which is defined by persistent pain that lasts weeks to years[1](http://www.mayoclinic.org/understanding-pain/art-20208632). The chronic pain is very common and there is more than 3 million US cases per year. 

For more information about pain, please refer to this paper : _Merskey, Harold Ed. "Classification of chronic pain: Descriptions of chronic pain syndromes and definitions of pain terms." Pain (1986)._ 

Among the chronic pain, this project specifically focused on Fibromyalgia(FM) [2](http://www.mayoclinic.org/diseases-conditions/fibromyalgia/home/ovc-20317786). FM causes widespread musculoskeletal pain accompanied by fatigue, sleep, memory and mood issues, but cannot be cured yet. There has been many attempts to help relieve those pains from the cognitive and behavioral perspectives. However, the new definition of pain encompasses even emotional forms of pain. In order to compare the effectiveness of emotional intervention, a Multi-site Randomized Controlled Trial for Fibromyalgia was conducted by Lumley M.A. from the Wayne State University, funded by NIH. [3](http://grantome.com/grant/NIH/R01-AR057808-02)

Using the dataset collected from this RCT, this project investigated the efficacy of an emotional therapy compared to two conventional interventions for FM in terms of pain. The emotional therapy is called Emotional Exposure Therapy (EET), which intended to reduce stress. The others are Cognitive-Behavioral Therapy (CBT) and FM Education Control (EDU). For more information, see [Analysis Result Report] (https://github.com/heoyj/Statistical-Investigation/blob/master/Longitudinal_Analysis/Analysis_Result_Report.md).

## 2. Data

- NIH-funded, 2-site, 3-arm, allegiance-controlled RCT 
- 230 FM patients were randomized into two sites (Wayne State University and University of Michigan) and three treatments (EET, CBT and EDU). 
- In each site, the small groups in three treatments participated in each 90 mins treatment sessions for 8 weeks in a row according to the randomization plan.
- The assessment variable related to pain was collected at the baseline (0 month), 3 months later (post-treatment) and 9 months later (6 months follow-up). 
- Demographic variables were collected, including age, gender, body mass index (BMI), ethnicity, race, highest educational level, total tender points, fibromyalgianess, and a score of symptoms evaluated by Complex Medical Symptoms Inventory.

### summary 
- N = 230 (the number of patients)
- p = 54 (the number of collected variables over time)

## 3. Source code 

Written in R

## 4. Analysis Result

See [Analysis Result Report] (https://github.com/heoyj/Statistical-Investigation/blob/master/Longitudinal_Analysis/Analysis_Result_Report.md).


