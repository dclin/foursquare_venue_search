-- Script to set up Snowflake database 

-- ****************************************************************************
-- Step 1: Get free foursquare new york city sample from data market place 
-- https://app.snowflake.com/marketplace/listing/GZT0ZHT9NV1/foursquare-foursquare-places-new-york-city-sample
-- Update database name. Mine is set to "foursquare_nyc"

-- ****************************************************************************
-- Step 2: Create a new user with scoped role for the streamlit app in admin UI 
-- For reference, mine is called SVC_STREAMLIT 
-- IMPORTANT: for security, limit streamlit app's use to snowflake 

-- Set up new database and schema where we are going to house auxiliary data  
CREATE DATABASE foursquare
-- create a new schema 
CREATE SCHEMA main 

-- create a new scoped role 
CREATE ROLE foursquare_read 
GRANT IMPORTED PRIVILEGES on database foursquare_nyc to role foursquare_read
GRANT usage on database foursquare to role foursquare_read 
GRANT usage on schema foursquare.main to role foursquare_read 
GRANT SELECT ON ALL tables in schema foursquare.main to role foursquare_read
GRANT SELECT ON FUTURE tables in schema foursquare.main to role foursquare_read
GRANT SELECT ON FUTURE views in schema foursquare.main to role foursquare_read

GRANT usage on warehouse [YOUR_WAREHOUSE_NAME] to role foursquare_read

-- Grant scoped role to user and set default role for user 
GRANT role foursquare_read to user SVC_STREAMLIT 
ALTER USER svc_streamlit set DEFAULT_ROLE = foursquare_read

-- Set up data 
USE foursquare.main 

-- ****************************************************************************
-- Step 3: Borough, neighborhood, borough_neighboorhood 

-- Table for borough_lookup 
CREATE TRANSIENT TABLE borough_lookup (
id number autoincrement,
name varchar 
)

INSERT INTO borough_lookup(name) values
('Brooklyn'),
('Bronx'),
('Manhattan'),
('Queens'),
('Staten Island')

-- Neighborhood_lookup 
CREATE TRANSIENT TABLE neighborhood_lookup (
id number autoincrement, 
name varchar 
)

INSERT INTO neighborhood_lookup(name)
SELECT DISTINCT n.value::string 
FROM foursquare_nyc.standard.places_us_nyc_standard_schema s,
table(flatten(s.neighborhood)) n
ORDER BY 1

-- place_neighborhood
CREATE OR REPLACE TRANSIENT TABLE place_neighborhood AS 
WITH place_neighborhood AS (
SELECT DISTINCT 
    s.fsq_id
    , n.value::string str 
FROM foursquare_nyc.standard.places_us_nyc_standard_schema s,
table(flatten(s.neighborhood)) n
)
SELECT pn.fsq_id, n.id neighborhood_id 
FROM place_neighborhood pn 
INNER JOIN neighborhood_lookup n ON pn.str = n.name 
ORDER BY id, pn.fsq_id 

-- borough_neighborhood 
CREATE OR REPLACE TRANSIENT TABLE borough_neighborhood(
borough_id number,
neighborhood_id number
)

-- Unfortunately, there is no easy way to do this. 
-- Manually look up what Foursquare neighborhoods are in what borough 
-- INSERT INTO borough_neighborhood(neighborhood_id, borough_id) values 
-- (261,3)
-- ... 

-- ****************************************************************************
-- Step 4: Categories 

-- category_place 
CREATE OR REPLACE TRANSIENT TABLE category_place AS 
SELECT 
    s.fsq_id 
    , n.value category_id
FROM foursquare_nyc.standard.places_us_nyc_standard_schema s,
table(flatten(s.fsq_category_ids)) n 
ORDER BY category_id, fsq_id 


-- Extract foursquare category IDs  
CREATE OR REPLACE TRANSIENT TABLE z_category_id AS 
WITH data AS (
SELECT 
    DISTINCT 
    s.fsq_category_labels
    , n.seq
    , n.index
    , n.value category_id
    , l.seq 
    , l.index 
    , l.value::string category
FROM foursquare_nyc.standard.places_us_nyc_standard_schema s,
table(flatten(s.fsq_category_ids)) n, 
table(flatten(s.fsq_category_labels)) l 
WHERE n.index = l.index
ORDER BY n.seq, n.index, l.seq, l.index 
)
SELECT DISTINCT to_number(category_id) category_id, category FROM data ORDER BY category_id 


-- Extract foursquare categories 
CREATE OR REPLACE TRANSIENT TABLE z_category_lookup AS 
SELECT category_id, value::string category  
FROM z_category_id z
, table(flatten(input => parse_json(z.category))) c 
QUALIFY row_number() OVER (PARTITION BY seq ORDER BY index DESC) = 1
ORDER BY category_id 


-- Set up foursquare category lookup tables 
CREATE OR REPLACE TRANSIENT TABLE category_lookup AS 
with hierarchy AS (
SELECT c.seq, c.index, c.value::string category  
FROM z_category_id z
, table(flatten(input => parse_json(z.category))) c 
)
, data AS (
SELECT 
    h.*
    , c.category_id
    , lag(c.category_id) OVER (PARTITION BY h.seq ORDER BY h.index) parent_category_id 
    , first_value(c.category_id) OVER (PARTITION BY h.seq ORDER BY h.index) root_category_id 
FROM hierarchy h 
INNER JOIN z_category_lookup c ON h.category = c.category 
)
SELECT DISTINCT category, category_id, parent_category_id, root_category_id
FROM data 
ORDER BY root_category_id, category_id  

-- ****************************************************************************
-- Step 5: Embed categories  

-- Add a column for to store OpenAI embedding values for the categories  
ALTER TABLE category_lookup add column embedding varchar

-- Use a script (or Streamlit app) to loop through all categories. 
-- For each, embed with OpenAI embedding API 
-- Store the embedding vector in the embedding column 

-- Quick lookup used for semantic search 
CREATE OR REPLACE TRANSIENT TABLE category_embed_value AS 
WITH leaf_category AS (
    SELECT category_id 
    FROM category_lookup 
    EXCEPT 
    SELECT category_id 
    FROM category_lookup 
    WHERE category_id IN (SELECT DISTINCT parent_category_id FROM category_lookup)
)
SELECT 
    l.category_id  
    , n.index 
    , n.value 
FROM category_lookup l 
, table(flatten(input => parse_json(l.embedding))) n 
WHERE l.category_id IN (SELECT category_id FROM leaf_category)
ORDER BY l.category_id, n.index 


-- ****************************************************************************
-- Step 6: Cache places 
-- Ordering by fsq_id to improve performance of place lookup queries 
CREATE OR REPLACE TRANSIENT TABLE place_lookup AS 
SELECT * FROM foursquare_nyc.standard.places_us_nyc_standard_schema
ORDER BY fsq_id



