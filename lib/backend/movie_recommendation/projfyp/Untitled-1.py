# Import necessary libraries
from flask import Flask, jsonify, request
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np
import re
import requests  # Don't forget to import the 'requests' library

# Initialize Flask app
app = Flask(__name__)

# Load movie data
movies = pd.read_csv("movies.csv")
movie_links = pd.read_csv("links.csv")

# Merge dataframes
movie_links['tmdbId'] = movie_links['tmdbId'].astype('Int64')
movies = pd.merge(movies, movie_links[['movieId', 'tmdbId']], on="movieId", how="left")

# Text cleaning function
def clean_title(title):
    title = re.sub("[^a-zA-Z0-9 ]", "", title)
    return title

# Vectorizer for text data
vectorizer = TfidfVectorizer(ngram_range=(1, 2))

# Process movie data
movies["clean_title"] = movies["title"].apply(clean_title)
tfidf = vectorizer.fit_transform(movies["clean_title"])


# Function to get poster path based on movieId
def fetch_poster(movieId):
    url = "https://api.themoviedb.org/3/movie/{}?api_key=8265bd1679663a7ea12ac168da84d2e8&language=en-US".format(movieId)
    data = requests.get(url).json()
    
    # Correct the key to access poster_path
    poster_path = data.get('poster_path')
    
    if poster_path:
        full_path = f"https://image.tmdb.org/t/p/w500/{poster_path}"
        return full_path
    else:
        return None

# Search function to find similar movies
def search(title):
    title = clean_title(title)
    query_vec = vectorizer.transform([title])
    similarity = cosine_similarity(query_vec, tfidf).flatten()
    indices = np.argpartition(similarity, -5)[-5:]
    results = movies.iloc[indices].iloc[::-1]
    
    # Extract specific columns
    result_columns = ["clean_title", "tmdbId"]
    recommendations = results[result_columns].to_dict(orient='records')

    # Add poster_path to each recommendation
    for recommendation in recommendations:
        recommendation["poster_path"] = fetch_poster(recommendation["tmdbId"])

    return recommendations

# Flask route to get recommendations
@app.route('/recommendations', methods=['GET'])
def recommend():
    title = request.args.get('title')
    if title:
        recommendations = search(title)
        return jsonify(recommendations)
    else:
        return jsonify({"error": "Please provide a movie title in the 'title' query parameter."})

# Run the Flask app
if __name__ == '__main__':
    app.run(debug=True)
