rm#####################################
# assemble.R                        #
# Prepare data for shiny app        #
# Adam Brown                        #
# Begun: 11/16/16                   #
# Last Update: 11/16/16             #
#####################################

## Scripts
source('script/drugcentral.R')
source('script/clinicaltrials_gov.R')
source('script/umls_query.R')

## Build Indictaion Dictionary
inddict <- data.frame(raw=unlist(strsplit(drugcentral$DISEASE_MESH,'\\|')), cui=unlist(strsplit(drugcentral$DISEASE_UMLS,'\\|')), cuname = NA, semType = NA, stringsAsFactors = F)
inddict <- rbind(inddict, data.frame(raw=unlist(strsplit(clin$DISEASE_MESH,'\\|')), cui=NA, cuname=NA, semType=NA))
inddict$cui[inddict$cui == 'NA'] <- NA
inddict <- unique(inddict)
for (i in 1:nrow(inddict)) {
    # Get current
    raw <- inddict$raw[i]

    # If missing cui, attempt to fill
    if (is.na(inddict$cui[i])) {
        cuiL <- getCUI(raw, 'normalizedString','2016AB',F)
        if (length(cuiL) == 1 & cuiL[[1]][1] != 'NO_CONCEPT_MAPPED_TO') inddict$cui[i] <- cuiL[[1]][1]
        # Don't allow multiple/no matches
        else inddict$cui[i] <- NA
    }
    
    # Once filled, check if still NA
    if (is.na(inddict$cui[i])) next
    else {
        inddict$cuname[i] <- getName(inddict$cui[i])
        inddict$semType[i] <- getSemTyp(inddict$cui[i])
    }
}
inddict <- subset(inddict, !is.na(cui) & !is.na(cuname))
inddict <- unique(inddict)
inddict <- inddict[!duplicated(inddict$cuname),]
inddict <- subset(inddict, semType %in% c('Disease or Syndrome',
                                          'Neoplastic Process',
                                          'Pathologic Function',
                                          'Finding',
                                          'Mental or Behavioral Dysfunction',
                                          'Sign or Symptom',
                                          'Injury or Poisoning',
                                          'Congenital Abnormality',
                                          'Acquired Abnormality',
                                          'Cell or Molecular Dysfunction'))

save(inddict, file='raw/indication_dictionary.RData')

## Build dataframe
drug.fr <- data.frame(Drug = character(), Indication = character(),
                      drug_name = character(), drug_id = character(),
                      ind_name = character(), ind_id=character(),
                      sem_type = character())
for (i in 1:nrow(drugcentral)) {
    # Drug Handling
    drug <- drugcentral$name[i]
    id <- drugcentral$identifier[i]
    drugcomp <- paste0('<a href="http://www.drugbank.ca/drugs/',id,'" target="_blank">',drug,' (DBID: ', id, ')</a>')
    
    # Indication Handling
    if (is.na(drugcentral$DISEASE_MESH[i])) next
    inds <- unlist(strsplit(drugcentral$DISEASE_MESH[i],'\\|'))
    indcus <- unname(unlist(sapply(inds, function(x) subset(inddict, raw == x)$cui)))
    if (length(indcus) == 0) next
    indcunames <- unname(unlist(sapply(inds, function(x) subset(inddict, raw == x)$cuname)))
    indtypes <- unname(unlist(sapply(inds, function(x) subset(inddict, raw == x)$semType)))
    indcomp <- paste0(indcunames, ' (CUI: ', indcus, ')')
    
    # Expand
    dfcomp <- data.frame(Drug = rep(drugcomp, length(indcomp)), Indication = indcomp,
                         drug_name = rep(drug, length(indcomp)), drug_id = rep(id, length(indcomp)),
                         ind_name = indcunames, ind_id = indcus,
                         sem_type = indtypes,
                         stringsAsFactors = F)
    # Add to df
    drug.fr <- rbind(drug.fr, dfcomp)
}

# Add status = Approved, Placeholder for ExLink
drug.fr$TrialStatus <- rep('Approved', nrow(drug.fr))
drug.fr$status <- rep('Approved', nrow(drug.fr))
drug.fr$phase <- rep(NA, nrow(drug.fr))
drug.fr$DetailedStatus <- rep(NA, nrow(drug.fr))

# Failed drugs from Clinical Trials
failed <- data.frame(Drug = character(), Indication = character(),
                     drug_name = character(), drug_id = character(),
                     ind_name = character(), ind_id=character(),
                     sem_type = character())
for (i in 1:nrow(clin)) {
    # Drug Handling
    drugs <- unlist(strsplit(clin$DBNAME[i],'\\|'))
    ids <- unlist(strsplit(clin$identifier[i],'\\|'))
    drugcomp <- paste0('<a href="http://www.drugbank.ca/drugs/',ids,'" target="_blank">',drugs,' (DBID: ', ids, ')</a>')
    
    # Indication Handling
    inds <- unlist(strsplit(clin$DISEASE_MESH[i],'\\|'))
    indcus <- unname(unlist(sapply(inds, function(x) subset(inddict, raw == x)$cui)))
    if (length(indcus) == 0) next
    indcunames <- unname(unlist(sapply(inds, function(x) subset(inddict, raw == x)$cuname)))
    indtypes <- unname(unlist(sapply(inds, function(x) subset(inddict, raw == x)$semType)))
    indcomp <- paste0(indcunames, ' (CUI: ', indcus, ')')
    
    # Expand
    dfcomp_set <- expand.grid(c(1:length(drugcomp)), c(1:length(indcomp)))
    dfcomp <- data.frame(Drug = drugcomp[dfcomp_set$Var1], Indication = indcomp[dfcomp_set$Var2],
                         drug_name = drugs[dfcomp_set$Var1], drug_id = ids[dfcomp_set$Var1],
                         ind_name = indcunames[dfcomp_set$Var2], ind_id = indcus[dfcomp_set$Var2],
                         sem_type = indtypes[dfcomp_set$Var2],
                         stringsAsFactors = F)
    
    # Add status
    dfcomp$TrialStatus <- paste0('<a href="https://clinicaltrials.gov/ct2/show/',clin$NCT_ID[i],'" target="_blank">',clin$OVERALL_STATUS[i], ' (',clin$PHASE[i],')</a>')
    dfcomp$status <- clin$OVERALL_STATUS[i]
    dfcomp$phase <- clin$PHASE[i]
    dfcomp$DetailedStatus <- clin$WHY_STOPPED[i]
    
    # Ensure uniqueness
    goodrows <- rep(NA, nrow(dfcomp))
    for (j in 1:nrow(dfcomp)) {
        if (nrow(subset(drug.fr, Drug == dfcomp$Drug[j] & Indication == dfcomp$Indication[j])) == 0) goodrows[j] <- TRUE
        else goodrows[j] <- FALSE
    }
    
    # Add to df
    failed <- rbind(failed, dfcomp[goodrows,])
}

## Combine
drug.fr <- rbind(drug.fr, failed)
drug.fr <- unique(drug.fr)
drug.fr$NCT <- gsub('<a href="https://clinicaltrials.gov/ct2/show/|" target="_blank">.*|Approved','', drug.fr$TrialStatus)
drug.fr$NCT[drug.fr$NCT == ''] <- NA

########
# Save #
########

save(drug.fr, file='repoDB/data/shiny.RData')
