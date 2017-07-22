#####################
# Server Definition #
#####################

## Options
options(warn=-1)

## Data
load('data/shiny.RData')

require(shiny)
require(DT)
require(ggplot2)

## Status Summary Plotting
df_status <- data.frame(status = names(table(drug.fr$status)), count = as.integer(table(drug.fr$status)))

shinyServer(function(input, output) {
    # Infographic definition
    output$summary_plot <- renderPlot({
        ggplot(df_status, aes(factor(status), count)) +
            geom_bar(stat='identity',width=0.5, aes(fill=factor(status))) +
            geom_text(aes(label=count),vjust = 1.5, color=c('black','white','white','white'))+
            labs(x=NULL, y=NULL) +
            theme_bw() +
            theme(panel.grid.major = element_blank(),
                  panel.grid.minor = element_blank()) +
            theme(legend.position='none') +
            scale_fill_manual(values=c('grey','black','black','black'))
    })
    
    # Dropmenu Definition
    output$drugdrop <- renderUI({
        selectizeInput(
            inputId = 'drugdrop',
            label = 'Select a drug from the dropdown menu, or enter a search term:',
            choices = sort(unique(drug.fr$drug_name)),
            selected = 'Sitagliptin',
            width = '100%',
            multiple = F,
            options = list(maxOptions = length(unique(drug.fr$drug_name)))
        )
    })
    
    output$inddrop <- renderUI({
        selectizeInput(
            inputId = 'inddrop',
            label = 'Select an indication from the dropdown menu, or enter a search term:',
            choices = sort(unique(drug.fr$ind_name)),
            selected = 'Diabetes Mellitus, Non-Insulin-Dependent',
            width = '100%', 
            multiple = F,
            options = list(maxOptions = length(unique(drug.fr$ind_name)))
        )
    })
    
    # Reactive Datatable Subsetting
    drugreact <- reactive({
        drugtable <- subset(drug.fr, drug_name == input$drugdrop & status %in% input$drugcheck & (is.na(phase) | phase %in% input$phasecheckdrug),
                            select = c('Drug', 'Indication', 'TrialStatus', 'DetailedStatus'))
        return(drugtable)
    })
    
    indreact <- reactive({
        indtable <- subset(drug.fr, ind_name == input$inddrop & status %in% input$indcheck & (is.na(phase) | phase %in% input$phasecheckind),
                           select = c('Drug', 'Indication', 'TrialStatus','DetailedStatus'))
        return(indtable)
    })
    
    # Reactive UI Datatable Definition
    output$drugtable <- renderDataTable({
        DT::datatable(drugreact(), options = list(pageLength = 5), rownames = F, escape = F)
    })
    output$indtable <- renderDataTable({
        DT::datatable(indreact(), options = list(pageLength = 5), rownames = F, escape = F)
    })
    
    # Subset download handlers
    output$drugdownload <- downloadHandler(
        filename = 'drugsearch.tsv',
        content = function(file) {
            drugtable <- subset(drug.fr, drug_name == input$drugdrop & status %in% input$drugcheck & (is.na(phase) | phase %in% input$phasecheckdrug),
                                select = c('drug_name','drug_id','ind_name','ind_id','NCT','status','phase','DetailedStatus'))
            write.table(drugtable, file, sep='\t', row.names = F)
        }
    )
    
    output$inddownload <- downloadHandler(
        filename = 'diseasesearch.tsv',
        content = function(file) {
            indtable <- subset(drug.fr, ind_name == input$inddrop & status %in% input$drugcheck & (is.na(phase) | phase %in% input$phasecheckdrug),
                               select = c('drug_name','drug_id','ind_name','ind_id','NCT','status','phase','DetailedStatus'))
            write.table(indtable, file, sep='\t', row.names = F)
        }
    )
    
    # Full download handler
    output$downloadFull <- downloadHandler(
        filename = 'full.csv',
        content = function(file) {
            table <- subset(drug.fr, select = c('drug_name','drug_id','ind_name','ind_id','NCT','status','phase','DetailedStatus'))
            write.table(table, file, sep = ',', row.names = FALSE)
        }
    )
    
})
