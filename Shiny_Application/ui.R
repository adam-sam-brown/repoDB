########
# Load #
########

## Libraries
library(shiny)
library(DT)

#################
# UI Definition #
#################

shinyUI(fluidPage(
    ## Header
    headerPanel('',
                tags$head(
                    tags$img(src="logo.png", height="80px", width='275px', 
                             style = "padding-left: 25px; padding-top: 15px")
                )
    ),
    
    tags$br(),
    
    ## Define Navigation
    navlistPanel(
        ## Overview Panel
        tabPanel(
            "Introduction",
            
            p("repoDB contains a standard set of drug repositioning successes and failures that can be
              used to fairly and reproducibly benchmark computational repositioning methods. repoDB data
              was extracted from ", 
              a('DrugCentral', href='http://drugcentral.org/'),
              "and ",
              a('ClinicalTrials.gov.', href='http://clinicaltrials.gov')
            ),
            
            p("The repoDB website has several functionalities, which can be accessed from the navigation bar:",
              tags$ul(
                  tags$li("Drug-centric searching"),
                  tags$li("Disease-centric searching"),
                  tags$li("Full repoDB download")
              )
            ),
            
            p("You can explore the types and characteristics of data in repoDB in the plot below."),
            plotOutput('summary_plot')
            
        ),
        
        ## Drug Search Panel
        tabPanel(
            "Drug Search",
            
            p('repoDB contains information about 1,571 currently approved drugs (as annotated in DrugBank).
                To search repoDB for a specific drug, select a drug and the current statuses you\'d like to display.
                Drugs are listed with their DrugBank IDs, for easier integration into your existing pipelines.
                Search results can be downloaded as a tab-separated values file using the download button below the table
                of drug indications.'
                
            ),
            uiOutput('drugdrop'),
            checkboxGroupInput('drugcheck',
                               'Select the status categories you\'d like to display',
                               choices = c('Approved','Terminated','Withdrawn','Suspended'),
                               selected = c('Approved','Terminated','Withdrawn','Suspended'),
                               inline=T
            ),
            checkboxGroupInput('phasecheckdrug',
                               'Select the phases you\'d like to display',
                               choices = c('Phase 0', 'Phase 1', 'Phase 2', 'Phase 3'),
                               selected = c('Phase 0', 'Phase 1', 'Phase 2', 'Phase 3'),
                               inline = T
                               
            ),
            tags$hr(),
            dataTableOutput('drugtable'),
            downloadButton(
                outputId = 'drugdownload',
                label = 'Download the current search results'
            )
        ),
        tabPanel(
            "Disease Search",
            
            p(
                'repoDB contains information about 2,051 diseases, all mapped to UMLS terms for easier 
                integration into your existing pipelines. To search for a specific disease,
                select a disease and the current statuses you\'d like to display.
                Search results can be downloaded as a tab-separated values file using the download button below the table
                of drug indications.'
            ),
            uiOutput('inddrop'),
            checkboxGroupInput('indcheck',
                               'Select the status categories you\'d like to display',
                               choices = c('Approved','Terminated','Withdrawn','Suspended'),
                               selected = c('Approved','Terminated','Withdrawn','Suspended'),
                               inline=T
            ),
            checkboxGroupInput('phasecheckind',
                               'Select the phases you\'d like to display',
                               choices = c('Phase 0', 'Phase 1', 'Phase 2', 'Phase 3'),
                               selected = c('Phase 0', 'Phase 1', 'Phase 2', 'Phase 3'),
                               inline = T
                               
            ),
            tags$hr(),
            dataTableOutput('indtable'),
            downloadButton(
                outputId = 'inddownload',
                label = 'Download the current search results'
            )
        ),
        tabPanel(
            "Download",
            
            p(
              "The full repoDB database is available for download using the button below.
              Please note that the data is presented as-is, and not all entries have been
              validated before publication."  
            ),
            downloadButton(
                outputId = 'downloadFull',
                label = 'Download the full repoDB Dataset'
            )
        ),
        tabPanel(
            "Citing repoDB",
            
            p(
                "To acknowledge use of the repoDB resource, please cite the following paper:" 
            ),
            tags$code(
                "Brown AS and Patel CJ. repoDB: A New Standard for Drug Repositioning Validation.",
                em("Scientific Data."),
                "170029 (2017)."
            ),
            tags$br(),
            tags$br(),
            p(
                "repoDB was built using the October 25, 2016 build of ",
                a("DrugCentral,", href='http://drugcentral.org/download'),
                "the March 27, 2016 build of the ",
                a("AACT database,", href='https://www.ctti-clinicaltrials.org/aact-database'),
                "and the 2016AB Release of the ",
                a("Unified Medical Language System.", href='https://www.nlm.nih.gov/research/umls/'),
                "Metformin and recycling symbol used under CC0 license from wikimedia commons. Database symbol by Designmodo,
                used under a CC3.0 licnesne."
            ),
            p (
                strong("By using the repoDB database, users agree to cite our work, as well as AACT,
                       DrugCentral, and UMLS for their role in data curation. This data is available under a ",
                       a('Creative Commons Attribution 4.0 International License.',href='https://creativecommons.org/licenses/by/4.0/')
                       )
            )
        ),
        tabPanel(
            "Version History",
            p("As repoDB is improved and augmented with new data, we will track any substantial changes made to repoDB here:"),
            tags$ul(
                tags$li(strong('v1.0 (March 14, 2017)'), ' - Initial release'),
                tags$li(strong('v1.1 (June 26, 2017)'), ' - Fixed a bug in the ClinicalTrials.gov parser that created multiple DrugBank Identifiers for a
                        single drug (many thanks to Cristina Leal for spotting the error).'),
                tags$li(strong('v1.2 (July 28, 2017)'), ' -', code('Version History'), ' tab was added to address discrepancies introduced in totals for Terminated
                        Withdrawn, and Suspended drug-disease pairs versus published values due to bugfix in v1.1 (many thanks to Beste Turanli for
                        spotting the discrepancy).')
            )
        )
    
        
    ),
    

    
    ## Footer
    tags$hr(),
    p(
        strong('repoDB is intended for educational and scientific research purposes only.'),
        'This work is licensed under a ',
        a('Creative Commons Attribution 4.0 International License.',href="http://creativecommons.org/licenses/by/4.0/"),
        'repoDB was developed by AS Brown and CJ Patel. See the "Citing repoDB" tab for citation information',
        'For more projects, visit the ', a('Patel Group Homepage.', href='http://www.chiragjpgroup.org/')
    )
))
