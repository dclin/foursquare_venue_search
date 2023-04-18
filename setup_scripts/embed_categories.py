import streamlit as st 
import snowflake.connector 
from snowflake.connector import DictCursor
import openai 

# create a .streamlit/secrets.toml within setup_scripts folder 
# need to use a snowflake credential with update permission on the category_lookup table 
# the SQL here assumes you are in the foursquare.main schema 

openai.api_key = st.secrets['openai']['api_key'] 

def get_embedding(category_str):
    try:
        response = openai.Embedding.create(
            input=category_str,
            model="text-embedding-ada-002"
        )
        embeddings = response['data'][0]['embedding']
        return embeddings 
    
    except Exception as e: 
        raise e 

@st.cache_resource 
def init_connection():
    return snowflake.connector.connect(**st.secrets["snowflake"])


def get_all_categories(conn):
    sql = """SELECT category_id, category FROM category_lookup ORDER BY category_id IS NOT NULL"""

    categories = _run_query(conn,sql)

    return categories    

def update_embedding(conn, category_id, embeddings):
    sql = """
    UPDATE category_lookup 
    SET embedding='{0}'
    WHERE category_id = {1}
    """.format(embeddings, category_id)

    try:
        _run_query(conn, sql)
        return 1
    except:
        return 0 


def _run_query(conn, query_str):
    with conn.cursor(DictCursor) as cur:
        cur.execute(query_str)
        return cur.fetchall()


conn = init_connection()

categories = get_all_categories(conn)

for category in categories: 
    
    st.write(f"Embed category_id: {category['CATEGORY_ID']}")
    try:
        embeddings = get_embedding(category['CATEGORY'])
        st.write(f"Update category_id: {category['CATEGORY_ID']}")
        update_category = update_embedding(conn, category['CATEGORY_ID'], embeddings)
        if update_category == 1:
            st.write(f"Updated category_id: {category['CATEGORY_ID']}")
    except: 
        pass 

