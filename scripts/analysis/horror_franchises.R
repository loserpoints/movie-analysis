### load required packages

library(RMariaDB)
library(tidyverse)
library(ggrepel)
library(ggthemes)
library(scales)
library(extrafont)


### load fonts for viz

if (.Platform$OS.type == "windows") loadfonts(device = "win")


### download list of franchise movies from imdb user
###
### note: imdb now requires a logged-in session for list exports, so this
### download returns a sign-in page rather than the csv. the file has to be
### exported by hand from the list page and saved to the path below.

download.file("https://www.imdb.com/list/ls022487858/export?ref_=ttls_otexp", destfile = "data/imdb/horror_franchises.csv")


### format franchise data for joining with rest of db

horror_franchises <- read_csv("data/imdb/horror_franchises.csv") %>%
  
  separate(Description, into = c("Franchise1", "Franchise"), sep = "\\[b]") %>%
  
  separate(Franchise, into = c("Franchise", "Franchise2"), sep = "\\[/b]") %>%
  
  select(-Franchise1, -Franchise2) %>%
  
  fill(Franchise, .direction = "down") %>%
  
  select(tconst = Const, franchise = Franchise)


### fetch and format imdb data from local database

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
	
    "

horror_db <- dbSendQuery(movies_db, horror_query)

horror <- dbFetch(horror_db)

dbClearResult(horror_db)


### join db with franchise data and filter


horror_franchises <- 
  
  left_join(horror, horror_franchises, by = c("tconst")) %>%
  
  filter(
    !is.na(franchise) | grepl("Horror", genres),
    !is.na(franchise) | titleType == "movie",
    !grepl("Documentary", genres),
    numVotes >= 500,
    as.numeric(runtimeMinutes) > 75
  )


### create the scaled popularity and quality metrics based on number of reviews and average rating

years <- unique(as.numeric(horror_franchises$startYear))

df_list <- lapply(years, function(x) {
  
  df <- horror_franchises %>%
    
    filter(startYear < x + 2, 
           startYear > x - 2) %>%
    
    arrange(numVotes) %>%
    
    mutate(vote_rank = row_number(),
           popularity = rescale(vote_rank, to = c(0, 5))) %>%
    
    filter(startYear == x)
  
})


horror_franchises <- do.call(rbind, df_list) %>%
  
  arrange(averageRating) %>%
  
  mutate(rating_rank = row_number(),
         quality = rescale(rating_rank, to = c(0, 5)),
         adj_score = popularity + quality) %>%
  
  filter(!is.na(franchise))


### reformat data to show number of films and average rating per franchise

franchise_scatter <- horror_franchises %>%
  
  select(franchise, adj_score) %>%
  
  group_by(franchise) %>%
  
  add_tally() %>%
  
  summarize_all(mean) %>%
  
  filter(n > 2) %>%
  
  mutate(
      facet = case_when(
        n == 3 ~ "3 Movies",
        n == 4 ~ "4 Movies",
        n > 4 & n < 8 ~ "5-7 Movies",
        n > 7 ~ "8-12 Movies",
        TRUE ~ as.character(n)
    )
  )


### plot franchises some smart way i haven't figured out yet

ggplot(franchise_scatter, aes(facet, adj_score, label = franchise)) +
  
  facet_wrap(~facet, nrow = 1, scales = "free_x") +
  
  geom_hline(yintercept = mean(horror_franchises$adj_score), linetype = "dashed", color = "gray54") +
  
  geom_point(size = 4, color = "gray54") +
  
  geom_label_repel(fill = "firebrick4", color = "white", fontface = "bold", family = "Trebuchet MS", segment.color = "gray54", size = 3) +
  
  theme_few() +
  
  xlab("") +
  
  ylab("Average Rating\n") +
  
  ggtitle("Horror Franchise Average Ratings and Number of Movies in Series", subtitle = "All data via IMDB") +
  
  theme(axis.text.y = element_text(size = 16, face = "bold", family = "Trebuchet MS"),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        axis.title = element_text(size = 18, face = "bold", family = "Trebuchet MS"),
        plot.title = element_text(size = 22, face = "bold", family = "Trebuchet MS", hjust = 0.5),
        plot.subtitle = element_text(size = 16, face = "italic", family = "Trebuchet MS", hjust = 0.5),
        strip.background = element_rect(fill = "gray24"),
        strip.text = element_text(size = 16, color = "white", face = "bold", family = "Trebuchet MS"))

ggsave("viz/horror_franchises_faceted.png", width = 21.333, height = 10.666)





### filter data just for specific franchises

franchise_comparison <- horror_franchises %>%
  
  filter(
    franchise == "Halloween" |
      franchise == "Friday the 13th" |
      franchise == "A Nightmare on Elm Street")


freddy_v_jason_dup <- horror_franchises %>%
  
  filter(primaryTitle == "Freddy vs. Jason") %>%
  
  mutate(franchise = "A Nightmare on Elm Street")


franchise_comparison <- rbind(franchise_comparison, freddy_v_jason_dup) %>%
  
  mutate(startYear = as.numeric(startYear))


ggplot(franchise_comparison, aes(startYear, adj_score, color = franchise, label = primaryTitle)) +
  
  facet_wrap(~franchise, nrow = 1) +
  
  geom_hline(yintercept = mean(horror_franchises$adj_score), linetype = "dashed", color = "gray54") +
  
  geom_point(size = 4) +
  
  geom_line(size = 1.5) +
  
  geom_label_repel(fill = "gray81", color = "gray54", family = "Trebuchet MS", segment.color = "gray54", size = 3, alpha = 0.75) +
  
  theme_few() +
  
  xlab("\nYear") +
  
  ylab("Average Rating\n") +
  
  ylim(5, 10) +
  
  scale_color_manual(values = c("firebrick3", "black", "darkorange2"), name = "Franchise") +
  
  ggtitle("Comparing the Big Three Horror Franchises Over Time", subtitle = "All data via IMDB") +
  
  theme(axis.text = element_text(size = 16, face = "bold", family = "Trebuchet MS"),
        axis.title = element_text(size = 18, face = "bold", family = "Trebuchet MS"),
        plot.title = element_text(size = 22, face = "bold", family = "Trebuchet MS", hjust = 0.5),
        plot.subtitle = element_text(size = 16, face = "italic", family = "Trebuchet MS", hjust = 0.5),
        strip.background = element_rect(fill = "gray27"),
        strip.text = element_text(size = 16, color = "white", face = "bold", family = "Trebuchet MS"),
        legend.position = "bottom",
        legend.title = element_text(size = 14, family = "Trebuchet MS"),
        legend.text = element_text(size = 12, family = "Trebuchet MS"))

ggsave("viz/horror_franchises_comparison.png", width = 21.333, height = 10.666)
