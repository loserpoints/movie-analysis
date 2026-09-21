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


sports_query <- 
  
  '
SELECT imdbId, primaryTitle, startYear, numVotes, averageRating, tag, relevance FROM movie_lens_genome_scores

STRAIGHT_JOIN movie_lens_genome_tags
	  ON movie_lens_genome_tags.tagId = movie_lens_genome_scores.tagId 

INNER JOIN movie_lens_links
	  ON movie_lens_links.movieId = movie_lens_genome_scores.movieId 

INNER JOIN imdb_titles
      ON concat("tt", LPAD(movie_lens_links.imdbId, 7, 0)) = imdb_titles.tconst

INNER JOIN imdb_basics
      ON concat("tt", LPAD(movie_lens_links.imdbId, 7, 0)) = imdb_basics.tconst

  AND numVotes >= 500
  AND (titleType = "movie" OR titleType = "video")
  AND runtimeMinutes > 75

  WHERE
	(
	tag LIKE "%sports%" OR
    tag LIKE "%baseball%" OR
    tag LIKE "%football%" OR
    tag LIKE "%soccer%" OR
    tag LIKE "%boxing%" OR
    tag LIKE "%racing%" OR
    tag LIKE "%bowling%" OR
    tag LIKE "%olympics%"
    )

    '

sports_db <- dbSendQuery(movies_db, sports_query)

sports <- dbFetch(sports_db)

dbClearResult(sports_db)


tags_per_movie_query <- 
  
  "
  
  SELECT imdbId, COUNT(*)
  FROM movie_lens_tags
  GROUP BY imdbId;

  "

tags_per_movie_db <- dbSendQuery(movies_db, tags_per_movie_query)

tags_per_movie <- dbFetch(tags_per_movie_db) %>%
  
  rename(tags_count = 2)

dbClearResult(tags_per_movie_db)


### combine all sports movie data from previous two queries

  

### create scaled popularity metric based on 11 year intervals

years <- unique(as.numeric(sports$startYear))

df_list <- lapply(years, function(x) {
  
  df <- sports_test %>%
    
    filter(startYear < x + 5, 
           startYear > x - 5) %>%
    
    group_by(imdbId) %>%
    
    filter(relevance == max(relevance)) %>%
    
    ungroup() %>%
    
    arrange(numVotes) %>%
    
    mutate(vote_rank = row_number(),
           popularity = rescale(vote_rank, to = c(0, 5))) %>%
    
    filter(startYear == x)
  
})


###

sports_adj <- do.call(rbind, df_list) %>%
  
  filter(tag != "racing",
         tag != "olympics") %>%
  
  arrange(averageRating) %>%
  
  mutate(rating_rank = row_number(),
         popularity = round(popularity, 2),
         quality = round(rescale(averageRating, to = c(0, 5)), 2),
         adj_score = popularity + quality) %>%
  
  filter(relevance >= 0.7) %>%
  
  arrange(-adj_score) %>%
  
  mutate(rank = row_number()) %>%
  
  select(rank, movie = primaryTitle, year = startYear, tag, relevance, popularity, quality, adj_score) 


best_sports <- sports_adj %>%
  
  top_n(99, adj_score) %>%
  
  select(movie, year, popularity, quality) %>%
  
  mutate(rank = row_number(),
         facet = ifelse(rank < 34, 1, 
                        ifelse(rank < 67, 2, 3))) %>%
  
  mutate(label = paste0(rank, " - ", movie, " (", year, ")")) %>%
  
  arrange(-rank) %>%
  
  mutate(label = factor(label, levels = label))


ggplot(best_sports, aes(-rank, y = 1, label = label)) +
  
  facet_wrap(~facet, scales = "free") +
  
  geom_tile(stat = "identity", fill = "dodgerblue3", alpha = 0.2) +
  
  geom_text(size = 5, family = "Trebuchet MS") +
  
  theme_few() +
  
  coord_flip() +
  
  xlab("") +
  
  ylab("") +
  
  ggtitle("IMDB Top 99 Sports Movies", subtitle = "movies ranked using a blended score based on popularity and quality") +
  
  theme(axis.text = element_blank(),
        axis.ticks = element_blank(),
        axis.title = element_blank(),
        plot.title = element_text(size = 22, face = "bold", family = "Trebuchet MS", hjust = 0.5),
        plot.subtitle = element_text(size = 16, face = "italic", family = "Trebuchet MS", hjust = 0.5),
        strip.background = element_blank(),
        strip.text = element_blank())


ggsave(filename = "C:/Users/Alan/Desktop/top_99_sports_movies.png", width = 21.333, height = 10.666)

write.csv(sports_adj, file = "C:/Users/Alan/Desktop/top_120_sports_movies.csv", row.names = F)
