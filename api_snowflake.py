import snowflake.connector 
from snowflake.connector import DictCursor
import streamlit as st 

# External functions 
 
def get_categories(search_embeddings):
    sql = """
    WITH base_search AS (
    SELECT '{0}' embedding
    )
    , search_emb AS (
    SELECT 
        n.index
        , n.value 
    from base_search l 
    , table(flatten(input => parse_json(l.embedding))) n 
    ORDER BY n.index
    )
    , search_emb_sqr AS (
    SELECT index, value, value*value value_sqr  
    FROM search_emb r 
    )
    , result AS (
    SELECT 
        v.category_id 
        , SUM(s.value * v.value) / SQRT(SUM(s.value * s.value) * SUM(v.value * v.value)) cosine_similarity
    FROM search_emb_sqr s 
    INNER JOIN category_embed_value v ON s.index = v.index 
    GROUP BY v.category_id
    ORDER BY cosine_similarity DESC 
    LIMIT 5
    )
    SELECT c.category, r.cosine_similarity
    FROM result r 
    INNER JOIN category_lookup c ON r.category_id = c.category_id
    WHERE r.cosine_similarity > 0.81
    ORDER BY r.cosine_similarity DESC 
    """.format(search_embeddings)

    recommended_categories = _run_query(sql)

    return recommended_categories


def get_boroughs():
    sql = """SELECT * FROM borough_lookup"""
    boroughs = _run_query(sql)
    return boroughs 


def get_neighborhoods(borough_name):
    sql = """
    SELECT n.* 
    FROM neighborhood_lookup n 
    INNER JOIN borough_neighborhood bn ON n.id = bn.neighborhood_id
    INNER JOIN borough_lookup b ON bn.borough_id = b.id 
    WHERE b.name IN ('{0}')
    ORDER BY b.name, n.name 
    """.format(borough_name)
    neighborhoods = _run_query(sql)
    return neighborhoods


def get_places(borough_name, neighborhood_list, category_list):
    sql = """
    WITH base_neighborhoods AS (
        SELECT n.id  
        FROM borough_lookup b 
        INNER JOIN borough_neighborhood bn on b.id = bn.borough_id
        INNER JOIN neighborhood_lookup n ON bn.neighborhood_id = n.id
        WHERE b.name = '{0}'
        AND n.name IN ({1})
    )
    , neighborhood_places AS (
        SELECT pn.fsq_id 
        FROM place_neighborhood pn 
        WHERE pn.neighborhood_id IN (SELECT id FROM base_neighborhoods)
        ORDER BY pn.fsq_id 
    )
    , base_categories AS (
        SELECT c.category_id 
        FROM category_lookup c 
        WHERE c.category IN ({2})
    )
    , category_places AS (
        SELECT pc.fsq_id 
        FROM category_place pc 
        WHERE pc.category_id IN (SELECT category_id FROM base_categories)
        ORDER BY pc.fsq_id 
    )
    , places AS (
        SELECT 
            fsq_id 
            , name 
            , latitude
            , longitude
            , concat(COALESCE(address,''), COALESCE(address_extended,'')) address  
            , fsq_category_labels
            , n1.value::string category
        FROM place_lookup l
        , table(flatten(l.fsq_category_labels)) n 
        , table(flatten(n.value)) n1 
        WHERE fsq_id IN (
            SELECT fsq_id FROM neighborhood_places
            INTERSECT 
            SELECT fsq_id FROM category_places
        )
        AND latitude IS NOT NULL 
        AND longitude IS NOT NULL 
        QUALIFY row_number() OVER (PARTITION BY fsq_id, n.seq, n.index, n1.seq ORDER BY n1.index DESC) = 1
    )
    SELECT 
        fsq_id 
        , ANY_VALUE(name) name 
        , ANY_VALUE(latitude) latitude
        , ANY_VALUE(longitude) longitude
        , ANY_VALUE(address) address
        , listagg(category, ', ') categories
    FROM places 
    GROUP BY fsq_id 
    ORDER BY fsq_id     
    """.format(borough_name, _list_to_str(neighborhood_list), _list_to_str(category_list))
    places = _run_query(sql)
    return places


# Internal functions 

def _init_connection():
    return snowflake.connector.connect(**st.secrets["snowflake"])


@st.cache_data(ttl=10, show_spinner=False)
def _run_query(query_str):
    with _init_connection() as conn:
        with conn.cursor(DictCursor) as cur:
            cur.execute(query_str)
            return cur.fetchall()


def _list_to_str(collection_list):
    """
    Clean a list of strings and save as comma separated strings.
    """
    escaped_strings = ["'{}'".format(s.replace("'", "\\'")) for s in collection_list]
    list_str = ','.join(escaped_strings)
    return list_str