library(tidyverse)
library(ggthemes)
library(extrafont)
library(scales)


if (.Platform$OS.type == "windows") loadfonts(device = "win")


### fetch and format data from local database
###
### comedies that aren't also family, animated or documentary movies, so the
### list isn't dominated by kids' films and stand-up specials

source("scripts/00_get_data.R")

movies_db <- connect_movies_db()


comedy_query <-

  "
  SELECT imdb_basics.*, imdb_titles.averageRating, imdb_titles.numVotes

  FROM imdb_basics

	INNER JOIN imdb_titles

	ON imdb_basics.tconst = imdb_titles.tconst

	WHERE genres LIKE '%Comedy%'
    AND genres NOT LIKE '%Documentary%'
    AND genres NOT LIKE '%Family%'
    AND genres NOT LIKE '%Animation%'
    AND titleType = 'movie'
    AND isAdult = 0
    AND runtimeMinutes >= 60
    AND numVotes >= 1000

  ORDER BY imdb_basics.tconst;

    "

comedy <- dbGetQuery(movies_db, comedy_query)

dbDisconnect(movies_db, shutdown = TRUE)


### create the scaled popularity and quality metrics based on number of reviews and average rating
###
### the same method as the horror base: popularity ranks votes against
### comedies released within a year either side, so older movies aren't
### penalised for having fewer voters, and quality ranks rating against all
### comedies

years <- unique(comedy$startYear)

df_list <- lapply(years, function(x) {

  df <- comedy %>%

    filter(startYear < x + 2,
           startYear > x - 2) %>%

    arrange(numVotes) %>%

    mutate(vote_rank = row_number(),
           popularity = rescale(vote_rank, to = c(0, 5))) %>%

    filter(startYear == x)

})


comedy_adj <- do.call(rbind, df_list) %>%

  arrange(averageRating) %>%

  mutate(rating_rank = row_number(),
         quality = rescale(rating_rank, to = c(0, 5)),
         adj_score = popularity + quality)


### rank the top 99 and lay them out in three columns

best_ever <- comedy_adj %>%

  arrange(-adj_score) %>%

  top_n(99, adj_score) %>%

  select(primaryTitle, startYear, popularity, quality) %>%

  mutate(rank = row_number(),
         facet = ifelse(rank < 34, 1,
                        ifelse(rank < 67, 2, 3))) %>%

  ## long titles are shortened so they fit their column
  
  mutate(label = paste0(rank, " - ", str_trunc(primaryTitle, 55), " (", startYear, ")")) %>%

  arrange(-rank) %>%

  mutate(label = factor(label, levels = label))


ggplot(best_ever, aes(-rank, y = 1, label = label)) +

  facet_wrap(~facet, scales = "free") +

  geom_tile(stat = "identity", fill = "darkgoldenrod2", alpha = 0.2) +

  geom_text(size = 5, family = "Trebuchet MS") +

  theme_few() +

  coord_flip() +

  xlab("") +

  ylab("") +

  ggtitle("IMDB Top 99 Comedy Movies", subtitle = "movies ranked using a blended score based on popularity and quality") +

  theme(axis.text = element_blank(),
        axis.ticks = element_blank(),
        axis.title = element_blank(),
        plot.title = element_text(size = 22, face = "bold", family = "Trebuchet MS", hjust = 0.5),
        plot.subtitle = element_text(size = 16, face = "italic", family = "Trebuchet MS", hjust = 0.5),
        strip.background = element_blank(),
        strip.text = element_blank())

ggsave(filename = "viz/top_99_comedy.png", height = 10.666, width = 21.333)
