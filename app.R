#ui.R
library(shiny)

ui <- fluidPage(
  titlePanel("Hello World!"),
  
  #splitLayout/flowLayout/fluidRow/sidebarLayout
  
  sidebarLayout(
    sidebarPanel(
      sliderInput(inputId ="bins",
                 "Number of bins:",
                 min=5,
                 max=50,
                 value=30)
    ),
    mainPanel(
      plotOutput(outputId="displot")
    )
  )
  
)

# server.R

server <- function(input,output){
  output$displot <- renderPlot({
    x <- faithful[,2]
    bins <- seq(min(x),max(x),length.out = input$bins + 1)
    hist(x,breaks = bins, col = 'skyblue', border = 'white')
  })
}

shinyApp(ui=ui, server=server)


