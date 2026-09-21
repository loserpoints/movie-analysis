# Movies

Exploratory analysis of film data, mostly horror — director careers, franchise
trajectories, and how ratings distribute across genres and years.

Written in R in 2019–2020. This is finished work, kept for reference rather
than actively maintained.

## Data

Two public sources, loaded into a local MariaDB database:

- **IMDb datasets** (`datasets.imdbws.com`) — titles, ratings, crew, episodes
  and names, published by IMDb as gzipped TSVs.
- **MovieLens** (GroupLens Research) — ratings, tags, links and the tag genome.

Building the database is three steps. The numbered scripts run in order, in
the same session:

1. `scripts/01_download_source_data.R` — downloads the source files
2. `scripts/02_create_tables.R` — creates the empty tables
3. `scripts/03_load_tables.R` — writes the downloaded data into them

Step 3 reads objects left in the session by step 1, so they can't be run
independently.

**These scripts were last run in 2020.** The IMDb dataset URLs are unchanged,
but MovieLens release names and file layouts have shifted since, so expect the
loading scripts to need adjustment before they run today.

## What's here

`scripts/04_horror_base.R` builds the data set the horror analyses share — the
horror movies with their ratings and directors, plus popularity and quality
scores derived from them. Each analysis script sources it, so it runs first
automatically.

The analyses live in `scripts/analysis/`:

| Script | Question it answers |
|---|---|
| `best_horror_directors.R` | Which horror directors have the strongest body of work? |
| `director_careers.R` | How does one director's rating trajectory look over a career? |
| `top_99_horror.R` | The best horror movies since 1960 |
| `top_99_slashers.R` | The same, narrowed to slashers via MovieLens tags |
| `best_horror_by_year.R` | The strongest horror movie of each year |
| `horror_ratings_scatter.R` | How a single year's horror releases spread across popularity and rating |
| `horror_franchises.R` | How franchises hold up across sequels |
| `top_99_sports_movies.R` | The same treatment applied to sports movies |
| `tv_series_ratings.R` | Episode ratings across the run of a series |

`horror_franchises.R`, `top_99_sports_movies.R` and `tv_series_ratings.R` run
their own queries and don't depend on the shared base.

`scripts/exploration.R` is scratch work — earlier versions of several of these
analyses, kept for reference. It writes to `data/` rather than `viz/` so
running it can't overwrite the committed charts.

Charts are in `viz/`, named after the script that produces them. Every script
writes there; paths are relative to the repository root, so run R from there.

## Running these

The database scripts read the password from an environment variable rather
than hardcoding it. Set it in `~/.Renviron`:

```
MOVIES_DB_PASSWORD=your_password_here
```

Then restart R. The scripts expect a local MariaDB instance with a `movies`
database.

## License

No license specified — personal analysis work, shared for reference.
