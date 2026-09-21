### builds the shared horror data set used by the analysis scripts
###
### produces three objects:
###   horror      - horror movies with ratings and directors
###   horror_adj  - the same, with popularity, quality and adj_score added
###   imdb_names  - the names table, for looking people up by name
###
### source this before running anything in the analysis scripts:
###   source("scripts/03_horror_base.R")


### load required packages

library(RMariaDB)
library(tidyverse)
library(scales)



### fetch and format data from local database

movies_db <-
  
  dbConnect(
    MariaDB(),
    user = "root",
    password = Sys.getenv("MOVIES_DB_PASSWORD"),
    dbname = "movies",
    host = "localhost"
  )


horror_query <- 
  
  "
  SELECT imdb_basics.*, imdb_titles.averageRating, imdb_titles.numVotes, imdb_crew.directors

  FROM imdb_basics

	INNER JOIN imdb_titles

	ON imdb_basics.tconst = imdb_titles.tconst
    AND numVotes > 500

	INNER JOIN imdb_crew

	ON imdb_basics.tconst = imdb_crew.tconst

	WHERE genres LIKE '%Horror%'
    AND genres NOT LIKE '%Documentary%'
    AND (titleType = 'movie' OR titleType = 'video')
    AND runtimeMinutes > 75;

    "

horror_db <- dbSendQuery(movies_db, horror_query)

horror <- dbFetch(horror_db)

dbClearResult(horror_db)


### fetch the names table so directors can be looked up by name

names_query <- 
  
  "
  SELECT * FROM imdb_names;

    "

imdb_names_db <- dbSendQuery(movies_db, names_query)

imdb_names <- dbFetch(imdb_names_db)

dbClearResult(imdb_names_db)

dbDisconnect(movies_db)



### create the scaled popularity and quality metrics based on number of reviews and average rating

years <- unique(as.numeric(horror$startYear))

df_list <- lapply(years, function(x) {
  
  df <- horror %>%
    
    filter(startYear < x + 2, 
           startYear > x - 2) %>%
    
    arrange(numVotes) %>%
    
    mutate(vote_rank = row_number(),
           popularity = rescale(vote_rank, to = c(0, 5))) %>%
    
    filter(startYear == x)
  
})


horror_adj <- do.call(rbind, df_list) %>%
  
  arrange(averageRating) %>%
  
  mutate(rating_rank = row_number(),
         quality = rescale(rating_rank, to = c(0, 5)),
         adj_score = popularity + quality)
