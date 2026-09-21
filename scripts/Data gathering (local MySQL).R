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
  SELECT * FROM imdb_basics

	INNER JOIN imdb_titles

	ON imdb_basics.tconst = imdb_titles.tconst
    AND numVotes > 500

	WHERE genres LIKE '%Horror%'
    AND genres NOT LIKE '%Documentary%'
    AND (titleType = 'movie' OR titleType = 'video')
    AND runtimeMinutes > 75;

    "

horror_db <- dbSendQuery(movies_db, horror_query)

horror <- dbFetch(horror_db)

dbClearResult(horror_db)



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

