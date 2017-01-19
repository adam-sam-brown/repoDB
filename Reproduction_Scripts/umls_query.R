#####################################
# umls_query.R                      #
# Retreive UMLS information         #
# Adam Brown                        #
# Begun: 11/16/16                   #
# Last Update: 11/30/16             #
#####################################

## Library
library('httr')
library('xml2')
library("stringr")

## UMLS
# Enter username and password for UMLS
# A UMLS license is required for the use of this script
MY_USERNAME <- '***'
MY_PASSWORD <- '***'

# Get Ticket Granting Ticket, Valid for 8 Hours
getTGT <- function(username, password) {
    AUTH_URI <- "https://utslogin.nlm.nih.gov/cas/v1/tickets"
    body <- list(username = username, password = password)
    TGT_RESPONSE <- POST(AUTH_URI, body = body, encode = "form")
    warn_for_status(TGT_RESPONSE)
    TGT_uri       <- headers(TGT_RESPONSE)$location
    TGT_timestamp <- Sys.time()
    return(list(TGT_uri,TGT_timestamp) )
}

tgt <- getTGT(MY_USERNAME,MY_PASSWORD)

# Get Service Ticket, Valid for 5 Minutes
getST <-function(TGT,VERBOSE) {
    timeout(15)
    AUTH_URI <- paste(tgt[[1]])
    ST_RESPONSE <- POST(AUTH_URI, 
                        body = list(service = "http://umlsks.nlm.nih.gov"), 
                        encode = "form")
    
    warn_for_status(ST_RESPONSE)
    ST <- content(ST_RESPONSE)
    
    if(VERBOSE){
        print(paste("getST: ", http_status(ST_RESPONSE)$message, sep = ""))
        print(paste("     st= ", ST, sep = ""))
        print(paste("    tgt= ", str_split(tgt, "/")[[1]][7], sep = ""))
    }
    
    # no sleeping time neccessary of run at LHC
    # random sleep of 5-10ms for each ST
    # sleep_time <- round(runif(1, 0.005, 0.010), digits = 3) 
    # Sys.sleep(sleep_time)
    
    return(ST)
}

paste("st=[", getST(tgt, TRUE),"]",sep="") #Debug

# Get Semantic Type
getSemTyp <- function(CUI) {
    res <- GET(paste0('https://uts-ws.nlm.nih.gov/rest/content/current/CUI/',CUI,'?ticket=', getST(tgt,VERBOSE=F)))
    con <- content(res)
    out <- con$result$semanticTypes[[1]]$name
    if (is.null(out)) return(NA)
    else return(out)
}

getName <- function(CUI) {
    res <- GET(paste0('https://uts-ws.nlm.nih.gov/rest/content/current/CUI/',CUI,'?ticket=', getST(tgt,VERBOSE=F)))
    con <- content(res)
    out <- con$result$name
    if (is.null(out)) return(NA)
    else return(out)
}

# Search
getCUI <-function(STRING,SEARCH_TYP,VERSION,VERBOSE){
    
    if(! SEARCH_TYP %in% c("exact","words","leftTruncation","rightTruncation","approximate","normalizedString")){
        warning("Invalid search type")
        break
    }
    
    if(VERBOSE){
        print(paste("START getCUI for [", STRING, "][",SEARCH_TYP,"]", sep = ""))
    }
    
    timeout(5)
    SEARCH_URI <- paste("https://uts-ws.nlm.nih.gov/rest/search",VERSION, sep = "/")
    
    concepts       <- list()
    page           <- 0
    attempt        <- 0
    MAX_attempt    <- 6        # maximum number of tries if a http error occurs [6 is good]
    SNOOZE_time    <- 10       # time (seconds) of the pause when error occurs [10 is good]
    Res            <- NULL
    sleep_time     <- 0        # no sleeping time neccessary of run at LHC
    
    repeat{
        
        page <- (page+1)
        concepts_cnt <- length(concepts)
        
        QUERY = list(string = STRING, 
                     ticket = getST(tgt, VERBOSE),
                     searchType=SEARCH_TYP,
                     pageNumber=page)
        
        response <- GET(url=SEARCH_URI, query=QUERY)
        
        # no sleeping time neccessary of run at LHC
        # sleep_time <- round(runif(1, 0.015, 0.025), digits = 3) # random sleep of 10-25ms
        # Sys.sleep(sleep_time)
        
        if(VERBOSE){
            print(paste("getCUI: random sleep (sec)= ", sleep_time, sep = ""))
        }
        
        
        if(http_error(response)){
            page <- 0
            
            if(attempt<MAX_attempt){
                attempt <- (attempt + 1)
                sleep_time <- SNOOZE_time*attempt*runif(1,0.5,1)
                message_for_status(response, paste("mapping term [", STRING, "]", 
                                                   "[Attempt #", attempt, "]", 
                                                   sep = ""))
                print(paste("[Now taking a ", sleep_time, " sec break]", sep = ""))
                
                Sys.sleep(sleep_time)
                next
            }
            stop("Too many failures, unable tor perform mapping.")
        }
        else
        {
            Res <- content(response)
            for(i in 1:length(Res$result$results)){
                concepts[[concepts_cnt+i]] <- c(Res$result$results[[i]]$ui,
                                                Res$result$results[[i]]$name,
                                                Res$result$results[[i]]$rootSource,
                                                Res$result$results[[i]]$uri)
            }
        }
        if(Res$result$results[[1]]$ui == "NONE"){
            break
        }
    }
    
    if(length(concepts) > 1){
        if(VERBOSE){
            print(paste("END getCUI for [", STRING, "][",(length(concepts)-1)," CUI found]", sep = ""))
        }
        concepts <- concepts[1:(length(concepts)-1)]
    }
    else
    {
        if(VERBOSE){
            print(paste("END getCUI for [", STRING, "][0 CUI found]", sep = ""))
        }
        concepts[[1]] <- c("NO_CONCEPT_MAPPED_TO","","","")
    }
    
    return(concepts) 
}