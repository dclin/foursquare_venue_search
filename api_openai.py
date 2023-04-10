import openai 
import streamlit as st 

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

