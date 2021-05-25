library(tidyverse)
library(readxl)
library(drc)
library(lmtest)
library(sandwich)
library(shiny)
library(jsonlite)
library(shinybusy)

# Define UI for application that draws the plot
ui <- fluidPage(

    # Application title
    titlePanel(title="Curve fitting and IC50 for response plot"),
    
    # Sidebar with a selection list 
    sidebarLayout(
        sidebarPanel(
            fluidRow(
                column(10, uiOutput("compounds"))
            )),
        
        # Show a plot of the generated distribution
        mainPanel(
            plotOutput("distPlot")
        )
    )
)


# Define server logic required to draw a histogram
server <- function(session, input, output){
    setwd(path.expand('~'))
    screenId <- 2603
    observe({
        query <- parseQueryString(session$clientData$url_search)
        if (!is.null(query[['screenId']])) {
            name <- query[['screenId']]
        }
    })
    show_modal_spinner(text="Loading data from IDR...")
    TABLE_URL <- "https://idr.openmicroscopy.org/webgateway/table/Screen/"
    url = paste(TABLE_URL, screenId, "/query/?query=*", sep="")
    json <- jsonlite::fromJSON(url)
    frame <- data.frame(json$data$rows)
    colnames(frame) <- json$data$columns
    
    
    colnames(frame)[names(frame) == 'Compound Name'] <- "CompoundName"
    colnames(frame)[names(frame) == 'Compound InChIKey'] <- 'InChIKey'
    colnames(frame)[names(frame) == 'Compound Concentration (microMolar)'] <- "Concentration"
    colnames(frame)[names(frame) == 'Percentage Inhibition (DPC)'] <- "Inhibition"
    remove_modal_spinner()
    output$compounds <- renderUI({
        compounds <- unique(as.vector(frame["CompoundName"]))
        cn <- vector()
        for(i in 1:nrow(compounds)) {
            cn <- c(cn, toString(compounds[i,]))
        }
        selectInput("compound", h4("Select Compound"), choices = sort(cn), selected = "Remdesivir")
    })
    dfcopy <- cbind(frame)
    data <- reactive({

        dfcopy <- filter(dfcopy, CompoundName == input$compound)
        df1 <- subset(dfcopy, select=c("Concentration", "Inhibition"))
        data <- mutate_all(df1, function(x) as.numeric(as.character(x)))
    })

    testall.LL.4 <- reactive({
        tryCatch({
            tt <- drm(Inhibition ~ Concentration, data = data(), fct = LL.4(), type = "continuous",
                          control = drmc(errorm=FALSE))
            if(is.null(tt$convergence)){
                drm(Inhibition ~ Concentration, data = data(), fct = LL.4(), type = "continuous", 
                    control = drmc(errorm=FALSE))
            }else{
                print("Fitting impossible")
                testall.LL.4 <- list()
            }
        }, error = function(e) {
            testall.LL.4 <- list()
        })
        
    })
    
    newdata <- reactive({
        newdata <- expand.grid(Concentration=data()[,2])
        pm <- as.data.frame(predict(testall.LL.4(), newdata = newdata, interval = "confidence"))
        newdata$p <- pm()[,1]
        newdata$pmin <- pm()[,2]
        newdata$pmax <- pm()[,3]
        newdata <- as.data.frame(newdata, stringsAsFactors = F)
    })
    
    IC50 <- reactive({
        
        if(is.null(testall.LL.4()$convergence)){
            
            IC50 <- ED(testall.LL.4(), 50, interval = "delta")[1]
            
        }else{
            
            IC50 <- 0
            
        }
        
    })
    
    Legend <-reactive({
        
        t <- which.min(abs(data()$Concentration - IC50()[1]))
        u <- which.max(abs(data()$Concentration - IC50()[1]))
        
        maxconc <- data()$Inhibition[nrow(data())]
        
        if(nrow(data()) < 8){
            ifelse(max(data()$Inhibition)-min(data()$Inhibition) < 40 | IC50()[1] > 30, "IC50 not plausible",
                   ifelse(data()$Inhibition[7] < data()$Inhibition[6], "Tox present @max.conc",
                          ifelse(data()$Inhibition[u]-data()$Inhibition[t] > 0, "Inhibitor","Probably Activator")))
        }else{
            ifelse(max(data()$Inhibition)-min(data()$Inhibition) < 40 | IC50()[1] > 30 , "IC50 not plausible",
                   ifelse(data()$Inhibition[8] < data()$Inhibition[7], "Tox present @max.conc",
                          ifelse(data()$Inhibition[u]-data()$Inhibition[t] > 0, "Inhibitor","Probably Activator")))
            
        }
        
    })
    
    output$distPlot <- renderPlot({

        if(length(testall.LL.4()) != 0){
           plot(testall.LL.4(), type = "bars", log = "x", bp = .0105, #type = "confidence",
                ylim = c(-100, 150),
                ylab = "Inhibition (percent)",
                xlab = paste("Concentration of ", input$compound, " (uM)",sep = ""))
            abline(h = 50, col = 'coral2', lwd = 2)
            abline(v = IC50()[1] , col = "cyan", lwd =1)
            #text(x = 0.03, y = 100, Legend())
            text(x = 0.05, y = 90, paste("calculated IC50 = ", round(IC50()[1],2), "uM", sep = "" ))
            #text(x = 0.03, y = 80, paste("calculated pIC50 = ", round(-6+log10(IC50()[1]),2), sep = "" ))
            
        }else{
            plot(1, type = "n",                         # Remove all elements of plot
                 ylab = "",
                 xlim = c(0, 100), ylim = c(0, 100),
                 xlab = paste("Concentration of ", input$compound, " (uM)",sep = ""))
            text(x = 50, y = 55, "Non fitting curve")
        }
        
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
#runGadget(ui, server, viewer = dialogViewer("IDR_Imaging_IC50", width = 700, height = 750))
