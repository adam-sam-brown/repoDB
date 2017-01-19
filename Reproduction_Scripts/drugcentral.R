#####################################
# drugcentral.R                     #
# Parse DrugCentral information     #
# Adam Brown                        #
# Begun: 11/16/16                   #
# Last Update: 11/16/16             #
#####################################

## Read
identifier <- read.table('raw/DrugCentral/identifier.csv', sep=',',quote='"',header=T,stringsAsFactors = F)
indication <- read.table('raw/DrugCentral/omop_relationship.csv', sep=',',quote='"',header=T,stringsAsFactors = F)
synonyms <- read.table('raw/DrugCentral/synonyms.csv', sep=',',quote='"',header=T,stringsAsFactors = F)
dbapproved <- read.table('raw/DrugBank/drug_links.csv', sep=',',quote='"',header=T,stringsAsFactors = F)

## DrugBank IDs
drugcentral <- subset(identifier, identifier %in% dbapproved$DrugBank.ID & id_type == 'DRUGBANK_ID', select = c('struct_id', 'identifier'))
drugcentral$name <- sapply(drugcentral$identifier, function(x) subset(dbapproved, DrugBank.ID == x)$Name)

## Indications
indication$umls_cui[indication$umls_cui == ''] <- NA
drugcentral$DISEASE_MESH <- sapply(drugcentral$struct_id, function(x) {
    slice <- subset(indication, struct_id == x & relationship_name == 'indication')$concept_name
    if (length(slice) == 0) out <- NA
    else if (length(slice) == 1) out <- slice
    else out <- paste(slice, collapse = '|')
    return(out)
})

drugcentral$DISEASE_UMLS <- sapply(drugcentral$struct_id, function(x) {
    slice <- subset(indication, struct_id == x & relationship_name == 'indication')$umls_cui
    if (length(slice) == 0) out <- NA
    else if (length(slice) == 1) out <- slice
    else out <- paste(slice, collapse = '|')
    return(out)
})
drugcentral$DISEASE_UMLS[drugcentral$DISEASE_UMLS == ''] <- NA

## Synonyms
drugcentral$SYNONYM <- sapply(drugcentral$struct_id, function(x) {
    slice <- subset(synonyms, id == x)$name
    if (length(slice) == 0) out <- NA
    else if (length(slice) == 1) out <- slice
    else out <- toupper(paste(slice, collapse = '|'))
    return(out)
})