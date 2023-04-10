# Foursquare NYC Venue Search
 NYC semantic venue search (Streamlit + Snowflake)

![App screenshot](screenshot.jpg)

## Description
Discover NYC with this [Streamlit](https://streamlit.io) app! It utilizes cosine similarity to semantically match your search query with Foursquare venue categories, helping you find matching venues in your selected neighborhoods across the city. Powered by Streamlit, [Snowflake](https://www.snowflake.com/en/), and [OpenAI](https://openai.com), this app allows users to explore NYC like never before.

## Features
* Select a borough and up to five neighborhoods to focus your search
* Input a search term (e.g., "Epic night out") to find relevant venue categories
* The app uses cosine similarity to match your query with Foursquare venue categories
* View suggested venues on a map and in a table with venue details

## Technical Implementation
* Streamlit app for the frontend user interface
* [OpenAI API](https://platform.openai.com/docs/guides/embeddings) to generate text embeddings for search queries
* Snowflake for data storage and retrieval

## Accessing the App
You can access the app on the Streamlit Cloud community at [nyc-venue-search.streamlit.app](http://nyc-venue-search.streamlit.app).

## Feedback
If you have any feedback or questions about this app, please reach out to me on Twitter at [@dclin](https://twitter.com/dclin).
Thank you for checking out the tool!