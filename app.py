import streamlit as st 
import api_snowflake as api 
import api_openai as oai 

st.set_page_config(page_title="NYC Venue Search", layout="wide", initial_sidebar_state="expanded")

# UI text strings 
page_title = "NYC Venue Search"
page_helper = "Discover NYC! The Streamlit app uses cosine similarity to semantically match your query with Foursquare venue categories and find matching venues in your selected areas."
empty_search_helper = "Select a borough and neighborhood, and enter a search term to get started."
category_list_header = "Suggested venue categories"
borough_search_header = "Select a borough"
neighborhood_search_header = "Select (up to 5) neighborhoods"
semantic_search_header = "What are you looking for?"
semantic_search_placeholder = "Epic night out"
search_label = "Search for categories and venues"
venue_list_header = "Venue details"


# Handler functions 
def handler_load_neighborhoods():
    selected_borough = 'Manhattan'
    if "borough_selection" in st.session_state and st.session_state.borough_selection != "":
        selected_borough = st.session_state.borough_selection
    neighborhoods = api.get_neighborhoods(selected_borough)
    st.session_state.neighborhood_list = [n['NAME'] for n in neighborhoods]

def handler_save_borough_neighborhoods():
    escaped_strings = ["'{}'".format(s.replace("'", "\\'")) for s in st.session_state.neighborhoods_selection]
    st.session_state.selected_neighborhood_str = ','.join(escaped_strings)

def handler_search_venues():
    try:
        embeddings = oai.get_embedding(st.session_state.user_category_query)
        st.session_state.suggested_categories = api.get_categories(embeddings)
        escaped_strings = ["'{}'".format(s['CATEGORY'].replace("'", "\\'")) for s in st.session_state.suggested_categories]
        st.session_state.suggested_category_str = ','.join(escaped_strings)
        if st.session_state.suggested_category_str != "":
            st.session_state.suggested_places = api.get_places(
                st.session_state.borough_selection, 
                st.session_state.selected_neighborhood_str, 
                st.session_state.suggested_category_str)
        else:
            st.warning("No suggested categories found. Try a different search.")

    except Exception as e: 
        st.error(f"{str(e)}")


# UI elements 
def render_cta_link(url, label, font_awesome_icon):
    st.markdown('<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">', unsafe_allow_html=True)
    button_code = f'''<a href="{url}" target=_blank><i class="fa {font_awesome_icon}"></i> {label}</a>'''
    return st.markdown(button_code, unsafe_allow_html=True)


def render_search():
    search_disabled = True 
    with st.sidebar:
        st.selectbox(label=borough_search_header, options=([b['NAME'] for b in boroughs]), index = 2, key="borough_selection", on_change=handler_load_neighborhoods)

        if "neighborhood_list" in st.session_state and len(st.session_state.neighborhood_list) > 0:
            st.multiselect(label=neighborhood_search_header, options=(st.session_state.neighborhood_list), key="neighborhoods_selection", max_selections=5, on_change=handler_save_borough_neighborhoods)

        st.text_input(label=semantic_search_header, placeholder=semantic_search_placeholder, key="user_category_query")

        if "borough_selection" in st.session_state and st.session_state.borough_selection != "" \
            and "selected_neighborhood_str" in st.session_state and st.session_state.selected_neighborhood_str != "" \
            and "user_category_query" in st.session_state and st.session_state.user_category_query != "":
            search_disabled = False 

        st.button(label=search_label, key="location_search", disabled=search_disabled, on_click=handler_search_venues)

        st.write("---")
        render_cta_link(url="https://twitter.com/dclin", label="Let's connect", font_awesome_icon="fa-twitter")
        render_cta_link(url="https://linkedin.com/in/d2clin", label="Let's connect", font_awesome_icon="fa-linkedin")

def render_search_result():
    col1, col2 = st.columns([1,2])
    col1.write(category_list_header)
    col1.table(st.session_state.suggested_categories)
    col2.write(f"Found {len(st.session_state.suggested_places)} venues.")
    col2.map(st.session_state.suggested_places, zoom=13, use_container_width=True)
    st.write(venue_list_header)
    st.dataframe(data=st.session_state.suggested_places, use_container_width=True)


boroughs = [{'NAME':'Brooklyn'},{'NAME':'Bronx'},{'NAME':'Manhattan'},{'NAME':'Queens'},{'NAME':'Staten Island'}]
#boroughs = api.get_boroughs()

if "selected_borough" not in st.session_state: 
    st.session_state.selected_borough = "Manhattan"

if "neighborhood_list" not in st.session_state:
    handler_load_neighborhoods()
render_search()

st.title(page_title)
st.write(page_helper)
st.write("---")

if "suggested_places" not in st.session_state:
    st.write(empty_search_helper)
else:
    render_search_result()

#st.write(st.session_state)

