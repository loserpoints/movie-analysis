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

Building the database is three steps, run in order and in the same session:

1. `scripts/Data gathering (public).R` — downloads the source files
2. `scripts/Create MySQL Tables.R` — creates the empty tables
3. `scripts/Update MySQL database.R` — writes the downloaded data into them

Step 3 reads objects left in the session by step 1, so they can't be run
independently.

**These scripts were last run in 2020.** The IMDb dataset URLs are unchanged,
but MovieLens release names and file layouts have shifted since, so expect the
loading scripts to need adjustment before they run today.

## What's here

`scripts/Horror base.R` builds the data set the horror analyses share — the
horror movies with their ratings and directors, plus popularity and quality
scores derived from them. Each analysis script sources it, so it runs first
automatically.

| Script | Question it answers |
|---|---|
| `Best horror directors.R` | Which horror directors have the strongest body of work? |
| `Career plots.R` | How does a director's rating trajectory look over a career? |
| `Slashers.R` | How do slasher films rate against horror generally? |
| `Horror franchises.R` | How do franchises hold up across sequels? |
| `Best of the year.R`, `Best ever.R` | Top-rated titles by year and all-time |
| `Sports Movies.R`, `TV Series.R` | The same treatment for other categories |
| `Exploration.R` | Scratch work, kept deliberately |

`Horror franchises.R`, `Sports Movies.R` and `TV Series.R` run their own
queries and don't depend on the shared base.

Charts are in `viz/`.

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
