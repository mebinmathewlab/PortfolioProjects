/*
DATA EXPLORATION USING SQL

Dataset Used
Air Quality Data in India (2015 - 2020)
The dataset contains air quality data and AQI (Air Quality Index) at daily level of various stations across multiple cities in India.

Cities
Ahmedabad, Aizawl, Amaravati, Amritsar, Bengaluru, Bhopal, Brajrajnagar, Chandigarh, Chennai, Coimbatore, Delhi, Ernakulam, 
Gurugram, Guwahati, Hyderabad, Jaipur, Jorapokhar, Kochi, Kolkata, Lucknow, Mumbai, Patna, Shillong, Talcher, Thiruvananthapuram, Visakhapatnam

The data has been made publicly available by the Central Pollution Control Board: https://cpcb.nic.in/ which is the official portal of Government of India. 
They also have a real-time monitoring app: https://app.cpcbccr.com/AQI_India/

Imported  stations.csv(230 rows),station_day.csv(108035 rows),city_day.csv(29531) using data import wizard assigned approriate data type  */
  
/*Checking and viewing the imported table ,descride the colums and counting the number of rows*/
SELECT * FROM stations
SELECT * FROM station_day
SELECT * FROM city_day

DESC stations
/*STATIONID   NOT NULL VARCHAR2(5)   
STATIONNAME          VARCHAR2(100) 
CITY                 VARCHAR2(50)  
STATE                VARCHAR2(50)  
STATUS               VARCHAR2(10)  
REGION               VARCHAR2(25) */
DESC station_day
/*STATIONID       VARCHAR2(5)  
REC_DATE        DATE         
PM2_5           NUMBER(6)    
PM10            NUMBER(6)    
NO              NUMBER(5)    
NO2             NUMBER(5)    
NOX             NUMBER(5)    
NH3             NUMBER(5)    
CO              NUMBER(4)    
SO2             NUMBER(5)    
O3              NUMBER(6)    
BENZENE         NUMBER(4)    
TOLUENE         NUMBER(4)    
XYLENE          NUMBER(4)    
AQI             NUMBER(5)    
AQI_BUCKET      VARCHAR2(12) */
DESC city_day
/*CITY            VARCHAR2(20) 
REC_DATE        DATE         
PM2_5           NUMBER(20)   
PM10            NUMBER(20)   
NO              NUMBER(20)   
NO2             NUMBER(20)   
NOX             NUMBER(20)   
NH3             NUMBER(20)   
CO              NUMBER(20)   
SO2             NUMBER(20)   
O3              NUMBER(20)   
BENZENE         NUMBER(20)   
TOLUENE         NUMBER(20)   
XYLENE          NUMBER(20)   
AQI             NUMBER(20)   
AQI_BUCKET      VARCHAR2(20) */

SELECT COUNT(*) FROM station_day --108035 rows

SELECT COUNT(*) FROM stations --230 rows

SELECT  COUNT(*) FROM city_day --29531 rows

/*Checking for duplicate data and using join to combine the table */

SELECT stationid, COUNT(*)
FROM stations
GROUP BY stationid
HAVING  COUNT(*)>1 --stationid is not repeated

SELECT city, COUNT(*)
FROM city_day
GROUP BY city
HAVING  COUNT(*)>=1 --city is repeated,26 distinct values

SELECT stationname, COUNT(*)
FROM stations
GROUP BY stationname
HAVING  COUNT(*)>1  --stationname is not repeated 

SELECT city ,COUNT(*)
FROM stations 
GROUP BY city
HAVING COUNT(*)>=1 --city is repeated ,127 distinct values 

SELECT *
FROM station_day d , stations s
WHERE d.stationid = s.stationid; --testing inner join

SELECT * 
FROM station_day d FULL OUTER JOIN stations s 
ON d.stationid = s.stationid; -- outer join

SELECT *
FROM city_day c LEFT JOIN stations s
ON c.city = s.city n -- left join

/*checking recorded dates in city_day table   */
SELECT city,COUNT (rec_date) date_count
FROM city_day
GROUP BY city

/*Alter the stations table to add a primary key constraint   */

ALTER TABLE stations 
ADD CONSTRAINT station_pk
PRIMARY KEY (stationid);

/*Alter the stations_day table to add a foreign key constraint   */

ALTER TABLE station_day 
ADD CONSTRAINT station_day_fk
FOREIGN KEY (stationid)
REFERENCES stations (stationid);

/*Add region column in stations table and seperating state in to north,south,east,west region */
SELECT state, COUNT(*)
FROM stations
GROUP BY state
HAVING  COUNT(*)>=1; -- display states list

ALTER TABLE stations
ADD  region varchar2(25) -- region table created with null values

UPDATE stations
SET region = CASE
    WHEN state IN ('Maharashtra','Kerala','Karnataka','Tamil Nadu','Andhra Pradesh','Telangana') THEN 'South'
    WHEN state IN ('Uttar Pradesh','Jharkhand','Chandigarh','Delhi','Bihar','Haryana','Madhya Pradesh') THEN 'North'
    WHEN state IN ('Rajasthan','Gujarat','Punjab')  THEN 'West'
    WHEN state IN ('Odisha','Mizoram','Meghalaya','West Bengal','Assam')  THEN 'East'
    ELSE 'Others'
    END  -- 230 rows updated
    
COMMIT   --saved 

/*finding out where is moderate,poor, very poor ,severe values of  AQI in southern cities*/
SELECT DISTINCT (city),aqi_bucket,region
FROM 
(
SELECT s.region,s.city,d.*
FROM station_day d LEFT JOIN stations s 
ON d.stationid = s.stationid 
WHERE region = 'South'
)
WHERE aqi_bucket = 'Severe' OR aqi_bucket ='Very Poor' OR aqi_bucket = 'Poor' OR aqi_bucket = 'Moderate';
--Visakhapatnam	Moderate,Bengaluru	Poor,Kochi	Poor,Hyderabad	Severe,Chennai	Severe,Bengaluru	Moderate,Mumbai	Moderate,
--Visakhapatnam	Poor,Kochi	Moderate,Chennai	Very Poor,Chennai	Poor,Visakhapatnam	Very Poor,Bengaluru	Very Poor
--Ernakulam	Moderate,Hyderabad	Very Poor,Chennai	Moderate,Amaravati	Very Poor,Mumbai	Very Poor,Hyderabad	Poor
--Mumbai	Poor,Amaravati	Moderate,Amaravati	Poor,Thiruvananthapuram	Moderate,Coimbatore	Moderate,Bengaluru	Severe
--Thiruvananthapuram	Poor,Hyderabad	Moderate

SELECT aqi_bucket, COUNT(*)
FROM 
(SELECT s.region,s.city,d.*
FROM station_day d LEFT JOIN stations s 
ON d.stationid = s.stationid 
WHERE region = 'South'
)
WHERE aqi_bucket = 'Severe' OR aqi_bucket ='Very Poor' OR aqi_bucket = 'Poor' OR aqi_bucket = 'Moderate'
GROUP BY aqi_bucket
HAVING  COUNT(*)>=1; -- Poor 1145 Severe 59 Moderate	10090 Very Poor	261 values for southern cities


SELECT  DISTINCT COUNT(aqi_bucket) OVER (PARTITION BY city,aqi_bucket  ) total_by_city_aqi,city,aqi_bucket,region
FROM 
(
SELECT s.region,s.city,d.*
FROM station_day d LEFT JOIN stations s 
ON d.stationid = s.stationid 
WHERE region = 'South'
)
WHERE aqi_bucket = 'Severe' OR aqi_bucket ='Very Poor' OR aqi_bucket = 'Poor' OR aqi_bucket = 'Moderate'
ORDER BY city 
/*
219	Amaravati	Moderate	South
47	Amaravati	Poor	South
8	Amaravati	Very Poor	South
56	Bengaluru	Very Poor	South
206	Bengaluru	Poor	South
28	Bengaluru	Severe	South
2960	Bengaluru	Moderate	South
386	Chennai	Poor	South
1494	Chennai	Moderate	South
126	Chennai	Very Poor	South
20	Chennai	Severe	South
13	Coimbatore	Moderate	South
49	Ernakulam	Moderate	South
112	Hyderabad	Poor	South
3179	Hyderabad	Moderate	South
34	Hyderabad	Very Poor	South
11	Hyderabad	Severe	South
2	Kochi	Poor	South
74	Kochi	Moderate	South
314	Mumbai	Poor	South
19	Mumbai	Very Poor	South
1357	Mumbai	Moderate	South
4	Thiruvananthapuram	Poor	South
165	Thiruvananthapuram	Moderate	South
74	Visakhapatnam	Poor	South
580	Visakhapatnam	Moderate	South
18	Visakhapatnam	Very Poor	South*/


/*finding out average value of AQI in south*/
SELECT city,ROUND (AVG(aqi),2) AVG_AQI
FROM
(SELECT s.region,s.city,d.*
FROM station_day d LEFT JOIN stations s 
ON d.stationid = s.stationid 
WHERE region = 'South')
GROUP BY city 
ORDER BY city;

/*Amaravati	95.3
Bengaluru	91.73
Chennai	113.64
Coimbatore	73.02
Ernakulam	92.36
Hyderabad	100.37
Kochi	104.28
Mumbai	103.06
Thiruvananthapuram	74.75
Visakhapatnam	117.27*/

SELECT region,ROUND(AVG(aqi),2) AVG_AQI
FROM
(SELECT s.region,s.city,d.*
FROM station_day d LEFT JOIN stations s 
ON d.stationid = s.stationid 
WHERE region = 'South')
GROUP BY region; --South	99.22

/*finding out average value of AQI in North*/

SELECT city,ROUND (AVG(aqi),2) AVG_AQI
FROM
(SELECT s.region,s.city,d.*
FROM station_day d LEFT JOIN stations s 
ON d.stationid = s.stationid 
WHERE region = 'North')
GROUP BY city 
ORDER BY city;
/*Bhopal	132.83
Chandigarh	96.5
Delhi	238.74
Gurugram	211.02
Jorapokhar	159.25
Lucknow	216.46
Patna	215.61*/

SELECT region,ROUND(AVG(aqi),2) AVG_AQI
FROM
(SELECT s.region,s.city,d.*
FROM station_day d LEFT JOIN stations s 
ON d.stationid = s.stationid 
WHERE region = 'North')
GROUP BY region; --North	231.02

/*finding out average value of AQI in West*/
SELECT city,ROUND (AVG(aqi),2) AVG_AQI
FROM
(SELECT s.region,s.city,d.*
FROM station_day d LEFT JOIN stations s 
ON d.stationid = s.stationid 
WHERE region = 'West')
GROUP BY city 
ORDER BY city;

/*Ahmedabad	452.12
Amritsar	119.92
Jaipur	134.81*/

SELECT region,ROUND(AVG(aqi),2) AVG_AQI
FROM
(SELECT s.region,s.city,d.*
FROM station_day d LEFT JOIN stations s 
ON d.stationid = s.stationid 
WHERE region = 'West')
GROUP BY region; --West	209.11

/*finding out average value of AQI in East*/
SELECT city,ROUND (AVG(aqi),2) AVG_AQI
FROM
(SELECT s.region,s.city,d.*
FROM station_day d LEFT JOIN stations s 
ON d.stationid = s.stationid 
WHERE region = 'East')
GROUP BY city 
ORDER BY city;

/*Aizawl	34.77
Brajrajnagar	150.28
Guwahati	140.11
Kolkata	132.66
Shillong	53.8
Talcher	172.89*/

SELECT region,ROUND(AVG(aqi),2) AVG_AQI
FROM
(SELECT s.region,s.city,d.*
FROM station_day d LEFT JOIN stations s 
ON d.stationid = s.stationid 
WHERE region = 'East')
GROUP BY region; --East	135.98

/*finding out average ,MAX , MIN  value of AQI in India*/

SELECT ROUND(AVG(aqi),2) IND_AVG_AQI 
FROM station_day d LEFT JOIN stations s 
ON d.stationid = s.stationid --179.75


SELECT city ,MAX(aqi) MAX_AQI ,MIN(aqi) MIN_AQI
FROM station_day d LEFT JOIN stations s 
ON d.stationid = s.stationid 
GROUP BY city
ORDER BY city
/*Ahmedabad	2049	48
Aizawl	92	18
Amaravati	312	24
Amritsar	869	20
Bengaluru	727	8
Bhopal	312	37
Brajrajnagar	355	22
Chandigarh	335	26
Chennai	661	17
Coimbatore	120	26
Delhi	1019	21
Ernakulam	180	55
Gurugram	891	27
Guwahati	956	25
Hyderabad	917	10
Jaipur	644	39
Jorapokhar	604	27
Kochi	277	51
Kolkata	545	19
Lucknow	814	27
Mumbai	323	14
Patna	634	34
Shillong	182	14
Talcher	570	13
Thiruvananthapuram	230	32
Visakhapatnam	387	23*/

/*finding out MAX ,MIN  value of AQI according to date in cities*/

SELECT CITY,COUNT(rec_date) count_date
FROM (SELECT s.region,s.city,d.*
FROM station_day d LEFT JOIN stations s 
ON d.stationid = s.stationid )
GROUP BY CITY; --recorded number of days for each cities

/*finding out MAX ,MIN  value of AQI according to date in southern cities*/
SELECT cal.*
FROM
(SELECT city,rec_date, MAX(aqi) max_aqi,MIN(aqi) min_aqi
FROM
(SELECT s.region,s.city,d.*
FROM station_day d LEFT JOIN stations s 
ON d.stationid = s.stationid 
WHERE region = 'South')
WHERE rec_date BETWEEN '01-01-15' AND '31-12-20'
GROUP BY city,rec_date) cal
WHERE  max_aqi IS NOT NULL;--min and max aqi values in cities by date



--------------------------------------------------------------------------------------------------------------------



