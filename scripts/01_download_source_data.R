### step 1 of 2 in building the movies database
###
### downloads the imdb and movielens source files and reads them into memory.
### leaves two lists behind, imdb_data and ml_data, which step 2 writes to
### mysql. run both steps in order, in the same session.

### load required packages

library(tidyverse)


### define function to download files from imdb site

get_imdb_data <- function(x) {
  
  download.file("https://datasets.imdbws.com/title.ratings.tsv.gz",
                destfile = "data/imdb/title.ratings.tsv.gz")
  
  download.file("https://datasets.imdbws.com/title.basics.tsv.gz",
                destfile = "data/imdb//title.basics.tsv.gz")
  
  download.file("https://datasets.imdbws.com/title.crew.tsv.gz",
                destfile = "data/imdb//title.crew.tsv.gz")
  
  download.file("https://datasets.imdbws.com/name.basics.tsv.gz",
                destfile = "data/imdb//name.basics.tsv.gz")
  
  download.file("https://datasets.imdbws.com/title.episode.tsv.gz",
                destfile = "data/imdb//title.episode.tsv.gz")
  
  
  ## read downloadeded imdb tsv files
  
  imdb_titles <- read.csv("data/imdb//title.ratings.tsv.gz", sep = "\t", stringsAsFactors = F)
  
  imdb_basics <- read.csv("data/imdb//title.basics.tsv.gz", sep = "\t", stringsAsFactors = F)
  
  imdb_crew <- read.csv("data/imdb//title.crew.tsv.gz", sep = "\t", stringsAsFactors = F)
  
  imdb_names <- read.csv("data/imdb//name.basics.tsv.gz", sep = "\t", stringsAsFactors = F)
  
  imdb_episodes <- read.csv("data/imdb//title.episode.tsv.gz", sep = "\t", stringsAsFactors = F)
  
  
  ## put imdb data frames in list to return
  
  imdb_data <- list(
    titles = imdb_titles,
    basics = imdb_basics,
    crew = imdb_crew,
    names = imdb_names,
    episodes = imdb_episodes
  )
  
  return(imdb_data)
  
}


### define function to download and unzip files from movie lens

get_ml_data <- function(x) {
  
  download.file("http://files.grouplens.org/datasets/movielens/ml-25m.zip",
                destfile = "data/movielens/ml-25.zip")
  
  unzip("data/movielens/ml-25.zip", exdir = "data/movielens")
  
  
  ### read unzipped movielens csv files
  
  ml_movies <- read.csv("data/movielens/ml-25m/movies.csv", stringsAsFactors = F)
  
  ml_tags <- read.csv("data/movielens/ml-25m/tags.csv", stringsAsFactors = F)
  
  ml_ratings <- read.csv("data/movielens/ml-25m/ratings.csv")
  
  ml_links <- read.csv("data/movielens/ml-25m/links.csv")
  
  ml_genome_tags <- read.csv("data/movielens/ml-25m/genome-tags.csv", stringsAsFactors = F)
  
  ml_genome_scores <- read.csv("data/movielens/ml-25m/genome-scores.csv")
  
  
  ## put movie lens data frames in list to return
  
  ml_data <- list(
    movies = ml_movies,
    tags = ml_tags,
    ratings = ml_ratings,
    links = ml_links,
    genome_tags = ml_genome_tags,
    genome_scores = ml_genome_scores
  )
  
  return(ml_data)
    
}

### get imdb data

imdb_data <- get_imdb_data()


### get movie lens data

ml_data <- get_ml_data()


