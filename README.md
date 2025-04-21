# Renewable Energy Trends Dashboard

Hi there! My name is Assel, and this is my IWV subject project. This Shiny app dashboard visualizes global renewable energy production trends using data from [Our World in Data](https://ourworldindata.org/). The dashboard includes several features such as time series analysis, regression analysis, and maps displaying 4-year changes in different energy sources.

## Features

- **Time Series Analysis:**  
  Visualize the production trends over time with separate lines for each country and an overall total.

- **Regression Analysis:**  
  Analyze the relationship between GDP (used as a proxy for investment) and renewable energy production.

- **Map Visualizations:**  
  Interactive maps display the 4-year percentage changes for Solar, Wind, and Hydro (Water) energy production. The app uses a reusable function to render the maps.

## How to Run the App

1. **Clone the repository**
    git clone https://github.com/<your-username>/<your-repo>.git
    cd <your-repo>
2. **Install the required R packages** (skip if you use `renv` or already have them)
    Rscript -e "install.packages(c('shiny', 'tidyverse', 'leaflet', 'plotly', 'broom'))"
    *or, with **renv***
    Rscript -e "renv::restore()"
3. **Run the application**
    R -e "shiny::runApp()"
    The app will automatically open at <http://127.0.0.1:PORT> in your default browser (the *PORT* number is chosen at runtime).
