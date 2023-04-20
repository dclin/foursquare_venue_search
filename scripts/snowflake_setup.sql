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
CREATE DATABASE foursquare;
-- create a new schema 
CREATE SCHEMA main; 

-- create a new scoped role 
CREATE ROLE foursquare_read; 
GRANT IMPORTED PRIVILEGES on database foursquare_nyc to role foursquare_read;
GRANT usage on database foursquare to role foursquare_read;
GRANT usage on schema foursquare.main to role foursquare_read; 
GRANT SELECT ON ALL tables in schema foursquare.main to role foursquare_read;
GRANT SELECT ON ALL views in schema foursquare.main to role foursquare_read;
GRANT SELECT ON FUTURE tables in schema foursquare.main to role foursquare_read;
GRANT SELECT ON FUTURE views in schema foursquare.main to role foursquare_read;

GRANT usage on warehouse [YOUR_WAREHOUSE_NAME] to role foursquare_read;

-- Grant scoped role to user and set default role for user 
GRANT role foursquare_read to user SVC_STREAMLIT; 
ALTER USER svc_streamlit set DEFAULT_ROLE = foursquare_read;

-- Set up data 
USE foursquare.main; 

-- ****************************************************************************
-- Step 3: Borough, neighborhood, borough_neighboorhood 

-- Table for borough_lookup 
CREATE TRANSIENT TABLE borough_lookup (
id number autoincrement,
name varchar 
);

INSERT INTO borough_lookup(name) values
('Brooklyn'),
('Bronx'),
('Manhattan'),
('Queens'),
('Staten Island');

-- Neighborhood_lookup 
CREATE TRANSIENT TABLE neighborhood_lookup (
id number autoincrement, 
name varchar 
);

INSERT INTO neighborhood_lookup(name)
SELECT DISTINCT n.value::string 
FROM foursquare_nyc.standard.places_us_nyc_standard_schema s,
table(flatten(s.neighborhood)) n
ORDER BY 1;

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
CREATE OR REPLACE TRANSIENT TABLE z_borough_neighborhood(
borough_name varchar,
neighborhood_name varchar
);

INSERT INTO z_borough_neighborhood(borough_name, neighborhood_name) values
('Bronx','Allerton'),
('Bronx','Bathgate'),
('Bronx','Baychester'),
('Bronx','Bedford Park'),
('Bronx','Belmont'),
('Bronx','Bronx Park'),
('Bronx','Bronx Park South'),
('Bronx','Bronx River'),
('Bronx','Bronxdale'),
('Bronx','Castle Hill'),
('Bronx','City Island'),
('Bronx','Clason Point'),
('Bronx','Concourse'),
('Bronx','Country Club'),
('Bronx','East Tremont'),
('Bronx','Edenwald'),
('Bronx','Fieldston'),
('Bronx','Fordham'),
('Bronx','Highbridge'),
('Bronx','Kingsbridge'),
('Bronx','Kingsbridge Heights'),
('Bronx','Longwood'),
('Bronx','Marble Hill'),
('Bronx','Melrose'),
('Bronx','Melrose Houses'),
('Bronx','Morris Heights'),
('Bronx','Morris Park'),
('Bronx','Morrisania'),
('Bronx','Mott Haven'),
('Bronx','Mount Eden'),
('Bronx','Mount Hope'),
('Bronx','North Riverdale'),
('Bronx','Norwood'),
('Bronx','Olinville'),
('Bronx','Parkchester'),
('Bronx','Patterson Houses'),
('Bronx','Pelham Parkway'),
('Bronx','Port Morris'),
('Bronx','Riverdale'),
('Bronx','Schuylerville'),
('Bronx','Soundview'),
('Bronx','Spuyten Duyvil'),
('Bronx','Throgs Neck'),
('Bronx','Undercliff'),
('Bronx','Unionport'),
('Bronx','University Heights'),
('Bronx','Van Nest'),
('Bronx','Wakefield'),
('Bronx','West Concourse'),
('Bronx','West Farms'),
('Bronx','Westchester Square'),
('Bronx','Williambridge'),
('Bronx','Williams Bridge'),
('Bronx','Williamsbridge'),
('Bronx','Woodlawn'),
('Bronx','Woodstock'),
('Brooklyn','Adelphi'),
('Brooklyn','Back Bay'),
('Brooklyn','Barren Island'),
('Brooklyn','Bath Beach'),
('Brooklyn','Bayridge'),
('Brooklyn','Bedford'),
('Brooklyn','Bedford Stuyvesant'),
('Brooklyn','Bensonhurst'),
('Brooklyn','Bergen Beach'),
('Brooklyn','BoCoCa'),
('Brooklyn','Boardwalk'),
('Brooklyn','Boerum Hill'),
('Brooklyn','Borough Park'),
('Brooklyn','Brighton Beach'),
('Brooklyn','Broadway Junction'),
('Brooklyn','Brooklyn Heights'),
('Brooklyn','Brooklyn Manor'),
('Brooklyn','Brownsville'),
('Brooklyn','Bushwick'),
('Brooklyn','Cadman Plaza'),
('Brooklyn','Canarsie'),
('Brooklyn','Carroll Gardens'),
('Brooklyn','City Line'),
('Brooklyn','Clinton Hill'),
('Brooklyn','Cobble Hill'),
('Brooklyn','Coney Island'),
('Brooklyn','Crown Heights'),
('Brooklyn','Ditmas Park'),
('Brooklyn','Downtown Brooklyn'),
('Brooklyn','Dumbo'),
('Brooklyn','Dyker Heights'),
('Brooklyn','East Flatbush'),
('Brooklyn','East New York'),
('Brooklyn','East Williamsburg'),
('Brooklyn','East Williasburg'),
('Brooklyn','Farragut'),
('Brooklyn','Flatbush'),
('Brooklyn','Flatlands'),
('Brooklyn','Fort Greene'),
('Brooklyn','Fort Hamilton'),
('Brooklyn','Fort Jay'),
('Brooklyn','Fulton Ferry'),
('Brooklyn','Georgetown'),
('Brooklyn','Gerritsen Beach'),
('Brooklyn','Gowanus'),
('Brooklyn','Gravesend'),
('Brooklyn','Greenpoint'),
('Brooklyn','Homecrest'),
('Brooklyn','Kensington'),
('Brooklyn','Manhattan Beach'),
('Brooklyn','Manhattan Terrace'),
('Brooklyn','Midwood'),
('Brooklyn','Mill Basin'),
('Brooklyn','Mill Island'),
('Brooklyn','Morgan Avenue'),
('Brooklyn','New Lots'),
('Brooklyn','New Utrecht'),
('Brooklyn','North Side'),
('Brooklyn','North Williamsburg - North Side'),
('Brooklyn','Ocean Hill'),
('Brooklyn','Ocean Parkway'),
('Brooklyn','Ord-Stuyvesant'),
('Brooklyn','Park Slope'),
('Brooklyn','Parkville'),
('Brooklyn','Plum Beach'),
('Brooklyn','Prospect'),
('Brooklyn','Prospect Heights'),
('Brooklyn','Prospect Hights'),
('Brooklyn','Prospect Park Sout'),
('Brooklyn','Prospect Park South'),
('Brooklyn','Red Hook'),
('Brooklyn','Rugby'),
('Brooklyn','Sea Gate'),
('Brooklyn','Sheepshead Bay'),
('Brooklyn','South Brooklyn'),
('Brooklyn','South Side'),
('Brooklyn','South Slope'),
('Brooklyn','Spring Creek'),
('Brooklyn','Starrett City'),
('Brooklyn','Stuyvesant Heights'),
('Brooklyn','Sunset Park'),
('Brooklyn','Tulton Ferry'),
('Brooklyn','Vinegar Hill'),
('Brooklyn','Weeksville'),
('Brooklyn','Williamsburg'),
('Brooklyn','Williamsburg - South Side'),
('Brooklyn','Windsor Teraace'),
('Brooklyn','Windsor Terrace'),
('Brooklyn','Wingate'),
('Manhattan','Alphabet City'),
('Manhattan','Battery Park City'),
('Manhattan','Beacon Hill'),
('Manhattan','Beekman'),
('Manhattan','Bellevue'),
('Manhattan','Beverly Square West'),
('Manhattan','Bowery'),
('Manhattan','Carnegie Hill'),
('Manhattan','Carnegie Hills'),
('Manhattan','Central Harlem'),
('Manhattan','Chelsea'),
('Manhattan','Chinatown'),
('Manhattan','City Hall'),
('Manhattan','City Hall Area'),
('Manhattan','Civic Center'),
('Manhattan','Claremont'),
('Manhattan','Clinton'),
('Manhattan','Down Town'),
('Manhattan','Downtown'),
('Manhattan','East Side'),
('Manhattan','East Village'),
('Manhattan','Financial District'),
('Manhattan','Flatiron'),
('Manhattan','Flatiron District'),
('Manhattan','Fort George'),
('Manhattan','Garment District'),
('Manhattan','Governor Alfred e Smith Houses'),
('Manhattan','Gramercy'),
('Manhattan','Gramercy-Flatiron'),
('Manhattan','Greenwich Village'),
('Manhattan','Hamilton Grange'),
('Manhattan','Hamilton Heights'),
('Manhattan','Harlem'),
('Manhattan','Hell\'s Kitchen'),
('Manhattan','Hudson Heights'),
('Manhattan','Inwood'),
('Manhattan','Kips Bay'),
('Manhattan','Knickerbocker Village'),
('Manhattan','Koreatown'),
('Manhattan','Lenox Hill'),
('Manhattan','Lincoln Square'),
('Manhattan','Little Germany'),
('Manhattan','Little Italy'),
('Manhattan','Little Poland'),
('Manhattan','LoDel'),
('Manhattan','LoHo'),
('Manhattan','Loisaida'),
('Manhattan','Lower East Side'),
('Manhattan','Lower Manhattan'),
('Manhattan','Manhattan Valley'),
('Manhattan','Manhattanville'),
('Manhattan','Meat Packing District'),
('Manhattan','Medical Centre'),
('Manhattan','Midtown'),
('Manhattan','Midtown South'),
('Manhattan','Midtown West'),
('Manhattan','Morningside Heights'),
('Manhattan','Morningside Hights'),
('Manhattan','Murray Hill'),
('Manhattan','NoHo'),
('Manhattan','Nolita'),
('Manhattan','Roosevelt Island'),
('Manhattan','Rose Hill'),
('Manhattan','SPURA'),
('Manhattan','San Juan Hill'),
('Manhattan','Seaport'),
('Manhattan','Soho'),
('Manhattan','Southern Tip'),
('Manhattan','Spanish Harlem'),
('Manhattan','St. Nicholas Terrace'),
('Manhattan','Stuyvesant Town'),
('Manhattan','Sugar Hill'),
('Manhattan','Sutton Place'),
('Manhattan','Tenderloin'),
('Manhattan','Theatre District'),
('Manhattan','Tribeca'),
('Manhattan','Tudor City'),
('Manhattan','Turtle Bay'),
('Manhattan','Two Bridges'),
('Manhattan','Union Square'),
('Manhattan','Upper East Side'),
('Manhattan','Upper West Side'),
('Manhattan','Uptown'),
('Manhattan','Washington Heights'),
('Manhattan','West Side'),
('Manhattan','West Village'),
('Manhattan','York Ville'),
('Manhattan','Yorkville'),
('Queens','Arverne'),
('Queens','Arverne-Edgemere'),
('Queens','Astoria'),
('Queens','Astoria Heights'),
('Queens','Astoria Hights'),
('Queens','Astoria South'),
('Queens','Auburndale'),
('Queens','Bay Terrace'),
('Queens','Bayside'),
('Queens','Bayswater'),
('Queens','Beechhurst'),
('Queens','Bellaire'),
('Queens','Belle Harbor'),
('Queens','Bellerose'),
('Queens','Blissville'),
('Queens','Breezy Point'),
('Queens','Briarwood'),
('Queens','Broad Channel'),
('Queens','Brookville'),
('Queens','Bushwick Junction'),
('Queens','Cambria Heights'),
('Queens','Cedar Manor'),
('Queens','College Point'),
('Queens','Corona'),
('Queens','Down Town Flushing'),
('Queens','Dutch Kills'),
('Queens','East Elmhurst'),
('Queens','Elmhurst'),
('Queens','Far Rockaway'),
('Queens','Flushing'),
('Queens','Forest Hills'),
('Queens','Fresh Meadows'),
('Queens','Fresh Pond'),
('Queens','Fresh Pond Junction'),
('Queens','Glen Oaks'),
('Queens','Glendale'),
('Queens','Hammels'),
('Queens','Hillcrest'),
('Queens','Hillside'),
('Queens','Hollis'),
('Queens','Holliswood'),
('Queens','Hunters Point'),
('Queens','Jackson Heights'),
('Queens','Jamaica'),
('Queens','Jamaica Hills'),
('Queens','Kew Gardens Hills'),
('Queens','Laurelton'),
('Queens','LeFrak City'),
('Queens','Little Neck'),
('Queens','Long Island City'),
('Queens','Malba'),
('Queens','Maspeth'),
('Queens','Neponsit'),
('Queens','North Corona'),
('Queens','Parkside'),
('Queens','Pomonok'),
('Queens','Queensboro Hill'),
('Queens','Queensboro Hills'),
('Queens','Queensbridge'),
('Queens','Ravenswood'),
('Queens','Richmond Hill'),
('Queens','Ridgewood'),
('Queens','Rochdale'),
('Queens','Rosedale'),
('Queens','Roxbury'),
('Queens','Seaside'),
('Queens','Somerville'),
('Queens','South Corona'),
('Queens','South Jamaica'),
('Queens','South Richmond Hill'),
('Queens','St. Albans'),
('Queens','Steinway'),
('Queens','Sunnyside Gardens'),
('Queens','Utopia'),
('Queens','Whitestone'),
('Queens','Willets Point'),
('Queens','Woodhaven'),
('Queens','Woodside'),
('Staten Island','Annadale'),
('Staten Island','Arlington'),
('Staten Island','Arrochar'),
('Staten Island','Aspen Knolls'),
('Staten Island','Brighton Heights'),
('Staten Island','Bull\'s Head'),
('Staten Island','Bulls Head'),
('Staten Island','Butler Manor'),
('Staten Island','Castleton Corner'),
('Staten Island','Castleton Corners'),
('Staten Island','Charleston'),
('Staten Island','Clifton'),
('Staten Island','Concord'),
('Staten Island','Dongan Hills'),
('Staten Island','Egbertville'),
('Staten Island','Fox Hills'),
('Staten Island','Graniteville'),
('Staten Island','Grant City'),
('Staten Island','Great Kills'),
('Staten Island','Greenridge'),
('Staten Island','Grymes Hill'),
('Staten Island','Howland Hook'),
('Staten Island','Huguenot'),
('Staten Island','Lighthouse Hill'),
('Staten Island','Midland Beach'),
('Staten Island','New Brighton'),
('Staten Island','New Dorp'),
('Staten Island','New Dorp Beach'),
('Staten Island','New Springville'),
('Staten Island','Park Hill'),
('Staten Island','Pleasant Plains'),
('Staten Island','Port Richmond'),
('Staten Island','Prince\'s Bay'),
('Staten Island','Randall Manor'),
('Staten Island','Richmond Valley'),
('Staten Island','Rosebank'),
('Staten Island','Rossville'),
('Staten Island','Shore Acres'),
('Staten Island','Silver Lake'),
('Staten Island','St. George'),
('Staten Island','Stapleton'),
('Staten Island','Sunnyside'),
('Staten Island','Todt Hill'),
('Staten Island','Tompkinsville'),
('Staten Island','Tottenville'),
('Staten Island','Travis'),
('Staten Island','Ward Hill'),
('Staten Island','West Brighton'),
('Staten Island','Westerleigh'),
('Staten Island','Willowbrook'),
('Staten Island','Woodrow');


CREATE OR REPLACE TRANSIENT TABLE borough_neighborhood AS 
SELECT
    b.id borough_id
    , n.id neighborhood_id 
FROM z_borough_neighborhood bp 
INNER JOIN borough_lookup b ON bp.borough_name = b.name 
INNER JOIN neighborhood_lookup n ON bp.neighborhood_name = n.name 
ORDER BY b.id, n.id;


-- ****************************************************************************
-- Step 4: Categories 

-- category_place 
CREATE OR REPLACE TRANSIENT TABLE category_place AS 
SELECT 
    s.fsq_id 
    , n.value category_id
FROM foursquare_nyc.standard.places_us_nyc_standard_schema s,
table(flatten(s.fsq_category_ids)) n 
ORDER BY category_id, fsq_id; 


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
SELECT DISTINCT to_number(category_id) category_id, category FROM data ORDER BY category_id; 


-- Extract foursquare categories 
CREATE OR REPLACE TRANSIENT TABLE z_category_lookup AS 
SELECT category_id, value::string category  
FROM z_category_id z
, table(flatten(input => parse_json(z.category))) c 
QUALIFY row_number() OVER (PARTITION BY seq ORDER BY index DESC) = 1
ORDER BY category_id;


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
ORDER BY root_category_id, category_id;  

-- ****************************************************************************
-- Step 5: Embed categories  

-- Add a column for to store OpenAI embedding values for the categories  
ALTER TABLE category_lookup add column embedding varchar;


-- run embed_categories.py
-- Check progress of the script
SELECT 
    COUNT(category_id) total_categories
    , COUNT(DISTINCT CASE WHEN embedding IS NOT NULL THEN category_id END) categories_embedded
FROM category_lookup;


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
ORDER BY l.category_id, n.index; 


-- ****************************************************************************
-- Step 6: Cache places 
-- Ordering by fsq_id to improve performance of place lookup queries 
CREATE OR REPLACE TRANSIENT TABLE place_lookup AS 
SELECT * FROM foursquare_nyc.standard.places_us_nyc_standard_schema
ORDER BY fsq_id;



