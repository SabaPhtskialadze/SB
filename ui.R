library(shiny)
library(shinyWidgets)
library(leaflet)
library(plotly)

# Define UI for application that draws a histogram
ui <- fluidPage(
  
  titlePanel("Video Games Analysis", windowTitle = "Video Games Analysis"),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,  # Adjust the width of the sidebar
      img(src = "game.jpg", alt = "Games", style = "height: 120px; display: block; margin-left: auto; margin-right: auto;"),
      tags$h4("Filters", style = "text-align: center; margin-top: 20px;"),
      sliderInput("minFreq",
                  "Word Frequency:",
                  min = 400,
                  max = 500,
                  value = 450),
      sliderInput("numTopTerms",
                  "Number of Top Terms:",
                  min = 1,
                  max = 20,
                  value = 8),
      fluidRow(
        column(6, actionButton("reset", "Reset Filters", class = "btn-primary")),
        column(6, actionButton("aboutBtn", "About", class = "btn-info"))
      )
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
      width = 9,  
      tabsetPanel(
        tabPanel("Word Frequency",
                 fluidRow(
                   column(6, plotOutput("bigramGraph", height = "320px")),
                   column(6, plotOutput("Tf", height = "320px"))
                 ),
                 fluidRow(
                   column(6, plotOutput("wordcloud", height = "430px")),
                   column(6, plotOutput("wordcloudtf", height = "430px"))
                 )
        ),
        tabPanel("N_Grams",
                 fluidRow(
                   column(6, plotOutput("Bigram", height = "500px")),
                   column(6, plotOutput("Trigrams", height = "500px"))
                 )
        )
      )
    )
  )
)

