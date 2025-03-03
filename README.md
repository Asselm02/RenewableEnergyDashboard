# Renewable Energy Trends Dashboard

Hi there! My name is Assel, and this is my IWV subject project. This Shiny app dashboard visualizes global renewable energy production trends using data from [Our World in Data](https://ourworldindata.org/). The dashboard includes several features such as time series analysis, regression analysis, and maps displaying 4-year changes in different energy sources.

## Features

- **Time Series Analysis:**  
  Visualize the production trends over time with separate lines for each country and an overall total.

- **Regression Analysis:**  
  Analyze the relationship between GDP (used as a proxy for investment) and renewable energy production.

- **Map Visualizations:**  
  Interactive maps display the 4-year percentage changes for Solar, Wind, and Hydro (Water) energy production. The app uses a reusable function to render the maps.

## Fixed Issues

During the development, I worked on several improvements:

1. **Issue #2:**  
   The UI controls are now hidden when viewing the map tabs using a `conditionalPanel`.

2. **Issue #3:**  
   The time series chart now displays separate lines for each country, in addition to a dashed line for total production.

3. **Issue #4:**  
   The app now defaults to using all countries when none is selected, preventing errors in the analysis tabs.

4. **Issue #5:**  
   The chart axes now include appropriate units (e.g., "Year (Gyr)" and "Production (GWh)").

5. **Issue #6:**  
   I added a brief description to the app that includes the data source information.

6. **Issue #8:**  
   The map rendering code has been refactored into a reusable function to keep the code clean and avoid repetition.

## How to Run the App

1. Clone the repository:
   ```bash
   git clone <your-repo-url>
   cd <your-repo-directory>
