##' Configure default behavior of NMdata functions
##' 
##' Configure default behavior across the functions in NMdata rather
##' than typing the arguments in all function calls. Configure for
##' your file organization, data set column names, and other NMdata
##' behavior. Also, you can control what data class NMdata functions
##' return (say data.tables or tibbles if you prefer one of those over
##' data.frames).
##'
##' @param ... NMdata options to modify. These are named arguments,
##'     like for base::options. Normally, multiple arguments can be
##'     used. The exception is if reset=TRUE is used which means all
##'     options are restored to default values. If NULL is passed to
##'     an argument, the argument is reset to default.  is See
##'     examples for how to use.
##'
##' @param allow.unknown Allow to store configuration of variables
##'     that are not pre-defined in NMdata. This should only be needed
##'     in cases where say another package wants to use the NMdata
##'     configuration system for variables unknown to NMdata.
##'
##' Parameters that can be controlled are:
##'
##' \itemize{
##'
##' \item{args.fread} Arguments passed to fread when reading _input_
##' data files (fread options for reading Nonmem output tables cannot
##' be configured at this point). If you change this, you are starting
##' from scratch, except from file. This means that existing default
##' argument values are all disregarded.
##'
##' \item{args.fwrite} Arguments passed to fwrite when writing csv
##' files (NMwriteData). If you use this, you have to supply all
##' arguments you want to use with fwrite, except for x (the data) and
##' file.
##'
##' \item{as.fun} A function that will be applied to data returned by various
##' data reading functions (NMscanData, NMreadTab, NMreadCsv, NMscanInput,
##' NMscanTables). Also, data processing functions like mergeCheck, findCovs,
##' findVars, flagsAssign, flagsCount take this into account, but slightly
##' differently. For these functions that take data as arguments, the as.fun
##' configuration is only taken into account if a the data passed to the
##' functions are not of class data.table. The argument as.fun to these
##' functions is always adhered to. Pass an actual function, say
##' as.fun=tibble::as_tibble. If you want data.table, use as.fun="data.table"
##' (not a function).
##'
##' \item{check.time} Logical, applies to NMscanData only. NMscanData by
##' defaults checks if output control stream is newer than input control stream
##' and input data. Set this to FALSE if you are in an environment where time
##' stamps cannot be relied on.
##' 
##' \item{col.flagc} The name of the column containing the character
##' flag values for data row omission. Default value is flag. Used
##' by flagsAssign, flagsCount.
##' 
##' \item{col.flagn} The name of the column containing numerical flag
##' values for data row omission. Default value is FLAG. Used by
##' flagsAssign, flagsCount, NMcheckData. 
##'
##' \item{col.model} The name of the column that will hold the name of
##' the model. See modelname too (which defines the values that the
##' column will hold).
##'
##' \item{col.nmout} A column of this name will be a logical
##' representing whether row was in output table or not.
##'
##' \item{col.nomtime} The name of the column holding nominal
##' time. This is only used for sorting columns by NMorderColumns.
##' 
##' \item{col.row} The name of the column containing a unique row
##' identifier. This is used by NMscanData when merge.by.row=TRUE, and
##' by NMorderColumns (row counter will be first column in data).
##'
##' \item{dir.psn} The directory in which to find psn executables like
##' `execute` and `update_inits`. Default is "" meaning that
##' executables must be in the system search path. Not used by NMdata.
##' 
##' \item{file.mod} A function that will derive the path to the input control
##' stream based on the path to the output control stream. Technically, it can
##' be a string too, but when using NMdataConf, this would make little sense
##' because it would direct all output control streams to the same input control
##' streams.
##'
##' \item{file.data} A function that will derive the path to the input
##' data based on the path to the output control stream. Technically,
##' it can be a string too, but when using NMdataConf, this would make
##' little sense because it would direct all output control streams to
##' the same input control streams.
##' 
##' \item{merge.by.row} Adjust the default combine method in
##' NMscanData.
##'
##' \item{modelname} A function that will translate the output control stream
##' path to a model name. Default is to strip .lst, so /path/to/run1.lst will
##' become run1. Technically, it can be a string too, but when using NMdataConf,
##' this would make little sense because it would translate all output control
##' streams model name.
##'
##' \item{path.nonmem} Path (a character string) to a nonmem
##' executable. Not used by NMdata. Default is NULL.
##' 
##' \item{quiet} For non-interactive scripts, you can switch off the
##' chatty behavior once and for all using this setting.
##'
##' \item{recover.rows} In NMscanData, Include rows from input data
##'     files that do not exist in output tables? This will be added
##'     to the $row dataset only, and $run, $id, and $occ datasets are
##'     created before this is taken into account. A column called
##'     nmout will be TRUE when the row was found in output tables,
##'     and FALSE when not. Default is FALSE.
##' 
##' \item{use.input} In NMscanData, merge with columns in input data?
##' Using this, you don't have to worry about remembering including
##' all relevant variables in the output tables. Default is TRUE.
##'
##' \item{use.rds} Affects NMscanData and NMscanInput. 
##'
##' }
##' @details Recommendation: Use
##' this function transparently in the code and not in a configuration file
##' hidden from other users.
##' 
##' @examples
##' ## get current defaults
##' NMdataConf()
##' ## change a parameter
##' NMdataConf(check.time=FALSE)
##' ## reset one parameter to default value
##' NMdataConf(modelname=NULL)
##' ## reset all parameters to defaults
##' NMdataConf(reset=TRUE)
##' @return If no arguments given, a list of active settings. If
##'     arguments given and no issues found, TRUE invisibly.
##' @export

NMdataConf <- function(...,allow.unknown=FALSE){
    
    dots <- list(...)
    if(length(dots)==0){
        ## dump existing options
        return(.NMdata$options)
    }

    names.args <- names(dots)
    if(is.null(names.args) || any(names.args=="")){
        stop("All arguments must be named.")
    }

    N.args <- length(dots)
    
### look for reset=TRUE. If so (and nothing else is given), set default values
    if("reset"%in%names.args) {
        reset <- dots$reset
        if(N.args>1) stop("reset cannot be combined with other arguments.")
        if(!is.logical(reset)) stop("reset must be logical")
        if(reset) {
            allopts <- NMdataConfOptions()
            names.args <- names(allopts)
            args <- lapply(allopts,function(x)x$default)
            N.args <- length(args)
        } else {
            return(.NMdata$options)
        }
    } else {
        
        args <- lapply(1:N.args,function(I){
            val <- dots[[I]]
            if(is.null(val)) val <- "default"
            ## if(is.character(val)&&length(val)==1&val=="default") val <- NULL
            NMdataDecideOption(names.args[I],val,allow.unknown=allow.unknown)
        })

    }
    
    ## if(!any(names(dots) %in% options.allowed)){
    ##     stop("not all option names recognized")
    ## }

    for(I in 1:N.args){
        .NMdata$options[[names.args[I]]] <- args[[I]]
    }
    invisible(TRUE)
}

##' Get NMdataConf parameter properties
##'
##' @param name Optionally, a single parameter name (say "as.fun").
##' @param allow.unknown Allow access to configuration of variables
##'     that are not pre-defined in NMdata. This should only be needed
##'     in cases where say another package wants to use the NMdata
##'     configuration system for variables unknown to NMdata.
##' @return If name is provided, a list representing one argument,
##'     otherwise a list with an element for each argument that can be
##'     customized using NMdataConf.
##' @keywords internal

## do not export

NMdataConfOptions <- function(name,allow.unknown=TRUE){

    all.options <- list(
        args.fread=list(
            default=list(na.strings=".",header=TRUE)
           ,is.allowed=is.list
           ,msg.not.allowed="args.fread must be a list of named arguments."
           ,process=function(x){
               if("file"%in%names(x)){
                   stop("args.fread cannot contain file.")
               }
               x
           }
        )
       ,
        args.fwrite=list(
            default=list(na=".",quote=FALSE,row.names=FALSE,scipen=0)
           ,is.allowed=is.list
           ,msg.not.allowed="args.fwrite must be a list of named arguments."
           ,process=function(x){
               if("file"%in%names(x)){
                   stop("args.fwrite cannot contain file.")
               }
               x
           }
        )
       ,
        as.fun=list(
            default=as.data.frame
           ,is.allowed=function(x){
               is.function(x) || (length(x)==1 && is.character(x) && x%in%c("none","data.table"))
           }
          ,msg.not.allowed="as.fun must be a function or the string \"data.table\""
          ,process=function(x){
              if(is.character(x)&&length(x)==1&&x%in%c("none")){
                  .Deprecated("as.fun=none","as.fun=none deprecated (still working but will be removed). Use as.fun=data.table.")
              }
              if(is.character(x)&&length(x)==1&&x%in%c("none","data.table")){
                  ## return(identity)
                  ## this is a trick to ensure data.tables are printed first time
                  return(function(DT)DT[])
              }
              x
          }
        )
       ,
        check.time=list(
            default=TRUE
            ## has to be length 1 character or function
           ,is.allowed=is.logical
           ,msg.not.allowed="check.time must be logical"
           ,process=identity
        )
       ,
        tz.lst=list(
            default=NULL
            ## has to be length 1 character or function
           ,is.allowed=function(x)is.null(x)||(is.character(x)&&length(x)==1)
           ,msg.not.allowed="tz.lst must be a character vector of lenght 1."
           ,process=identity
        )
       ,
        col.model=list(
            default="model"
           ,is.allowed=function(x) (is.character(x) && length(x)==1)
           ,msg.not.allowed="col.model must be a character vector of length 1."
           ,process=identity
        )
       ,
        col.nmout=list(
            default="nmout"
           ,is.allowed=function(x) (is.character(x) && length(x)==1)
           ,msg.not.allowed="col.nmout must be a character vector of length 1."
           ,process=identity
        )
       ,
        col.nomtime=list(
            default="NOMTIME"
           ,is.allowed=function(x) (is.character(x) && length(x)==1)
           ,msg.not.allowed="col.nomtime must be a character vector of length 1."
           ,process=identity
        )
       ,
        col.flagc=list(
            default="flag"
           ,is.allowed=function(x) (is.character(x) && length(x)==1)
           ,msg.not.allowed="col.flagc must be a character vector of length 1."
           ,process=identity
        )
       ,
        col.flagn=list(
            default="FLAG"
           ,is.allowed=function(x) length(x)==1 && ((is.logical(x) && x==FALSE) || is.character(x) )
           ,msg.not.allowed="col.flagn must be a character vector of length 1."
           ,process=function(x) {if(is.logical(x) && x==FALSE) {
                                     return(NULL)
                                 } else {
                                     return(x)
                                 }
           }
        )
       ,
        col.row=list(
            default="ROW"
           ,is.allowed=function(x) (is.character(x) && length(x)==1)
           ,msg.not.allowed="col.row must be a character vector of length 1."
           ,process=identity
        )
       ,
        dir.psn=list(
            default=""
            ## has to be length 1 character 
           ,is.allowed=function(x) is.character(x) && length(x)==1 
           ,msg.not.allowed="dir.psn must be a single text string."
           ,process=identity
        )
       ,
        file.mod=list(
            default=function(file) fnExtension(file,ext=".mod")
            ## has to be length 1 character or function
           ,is.allowed=function(x) is.function(x) || (length(x)==1 && is.character(x))
           ,msg.not.allowed="file.mod must be a function or a character of length 1"
           ,process=function(x) {
               if(is.character(x)) return(function(file) x)
               x
           }
        )
       ,
        file.data=list(
            default="extract"
            ## has to be length 1 character or function
           ,is.allowed=function(x) is.function(x) || (length(x)==1 && is.character(x))
           ,msg.not.allowed="file.data must be NULL, a function or a character of length 1. To force extracting data file from control stream, use file.data=\"extract\"."
           ,process=function(x) {
               if(is.character(x)&&x!="extract") return(function(file) x)
               x
           }
        )
       ,
        merge.by.row=list(
            default="ifAvailable"
            ## has to be length 1 character 
           ,is.allowed=function(x)is.logical(x) || (is.character(x) && length(x)==1 && x=="ifAvailable")
           ,msg.not.allowed="merge.by.row must be logical or the string \"ifAvailable\"."
           ,process=identity
        )
       ,
        modelname=list(
            default=function(file) fnExtension(basename(file),"")
            ## has to be length 1 character or function
           ,is.allowed=function(x) is.function(x) || (length(x)==1 && is.character(x))
           ,msg.not.allowed="modelname must be either a function or a character."
           ,process=function(x) {
               if(is.character(x)) return(function(file) x)
               x
           }
        )
       ,
        path.nonmem=list(
            default=NULL
            ## has to be length 1 character 
           ,is.allowed=function(x) is.null(x) || (is.character(x) && length(x)==1) 
           ,msg.not.allowed="path.nonmem must be a single text string."
           ,process=identity
        )
       ,
        quiet=list(
            default=FALSE
           ,is.allowed=is.logical
           ,msg.not.allowed="quiet must be logical"
           ,process=identity
        )
       ,
        recover.rows=list(
            default=FALSE
            ## has to be length 1 character or function
           ,is.allowed=is.logical
           ,msg.not.allowed="recover.rows must be logical"
           ,process=identity
        )
       ,
        use.input=list(
            default=TRUE
           ,is.allowed=is.logical
           ,msg.not.allowed="use.input must be logical"
           ,process=identity
        )
       ,
        use.rds=list(
            default=TRUE
           ,is.allowed=is.logical
           ,msg.not.allowed="use.rds must be logical"
           ,process=identity
        )
    )

    if(!missing(name)&&!is.null(name)){

        if(length(name)==1){
            if(name%in%names(all.options)){
                return(all.options[[name]])
            } else if(allow.unknown) {
                return(NULL)
            } else {
                messageWrap("Option not found",fun.msg=stop,track.msg=FALSE)
            }
        } else {
            messageWrap("if name is given, it must be a character of length 1",fun.msg=stop,track.msg=FALSE)
        }
        
    } else {
        return(all.options)
    }
}


##' Determine active parameter value based on argument and NMdataConf setting
##' @param name The name of the parameter, say "as.fun"
##' @param argument The value to pass. If missing or NULL, the value returned by NMdataConf/NMdataGetOption will typically be used.
##' @return Active argument value.
##' @keywords internal

## Do not export.
NMdataDecideOption <- function(name,argument,allow.unknown=FALSE){
    
    values.option <- NMdataConfOptions(name,allow.unknown=allow.unknown)
    ## TODO. This is wrong. This means nothing is pre-defined for the option. It doesn't mean no value is configured.
    ## if nothing found and unknown parameters allowed, we just use the supplied value
    is.unknown <- is.null(values.option)
    if(is.unknown && allow.unknown) {
        ##return(argument)
        ## define a tmp object that serves purpose?
        values.option <- list(default=NULL
                             ,is.allowed=function(x)TRUE
                             ,process=identity
                              )
    }
    
    if(!missing(argument) && is.character(argument) && length(argument)==1 && argument=="default") {
        return(values.option$default)
    }


    ## if(is.null(argument)) {
    ##     return(values.option$default)
    ## }

    

    if(missing(argument)||is.null(argument)) return(NMdataGetOption(name))
    ## if(!(is.null(values.option)&&allow.unknown)){
    if(!values.option$is.allowed(argument)) messageWrap(values.option$msg.not.allowed,fun.msg=stop,track.msg = FALSE)
    argument <- values.option$process(argument)
    ## } else {
    ##     argument <- NULL
    ## }



    return(argument)
}

##' Look up default configuration of an argument
##' @param ... argument to look up. Only one argument can be looked up.
##' @return The value active in configuration
##' @keywords internal

## This is only used by NMdataDecideOption
## do not export.
NMdataGetOption <- function(...){

    dots <- list(...)

    if(length(dots)!=1) stop("exactly one argument must be given.")

    .NMdata$options[[dots[[1]]]]
    
}
