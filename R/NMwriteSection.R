##' Replace ($)sections of a Nonmem control stream
##'
##' Just give the section name, the new lines and the file path, and the
##' "$section", and the input to Nonmem will be updated.
##'
##' @param files File paths to the models (control stream) to
##'     edit. See file.pattern too.
##' @param file.pattern Alternatively to files, you can supply a
##'     regular expression which will be passed to list.files as the
##'     pattern argument. If this is used, use dir argument as
##'     well. Also see data.file to only process models that use a
##'     specific data file.
##' @param dir If file.pattern is used, dir is the directory to search
##'     in.
##' @param section The name of the section to update with or without
##'     "$". Example: section="EST" or section="$EST" to edit the
##'     sections starting by $EST. Section specification is not
##'     case-sensitive. See ?NMreadSection too.
##' @param newlines The new text (including "$SECTION"). Better be
##'     broken into lines in a character vector since this is simply
##'     past to writeLines.
##' @param list.sections Named list of new sections, each element
##'     containing a section. Names must be section names, contents of
##'     each element are the new section lines for each section.
##' @param location In combination with `section`, this determines
##'     where the new section is inserter. Posible values are
##'     "replace" (default), "before", "after", "first", "last".
##' @param newfile path and filename to new run. If missing, the
##'     original file (from \code{files} or \code{file.pattern}) is
##'     overwritten (see the \code{backup} option below). If NULL,
##'     output is returned as a character vector rather than written.
##' @param backup In case you are overwriting the old file, do you
##'     want to backup the file (to say, backup_run001.mod)?
##' @param blank.append Append a blank line to output?
##' @param data.file Use this to limit the scope of models to those
##'     that use a specific input data data file. The string has to
##'     exactly match the one in $DATA or $INFILE in Nonmem.
##' @param write Default is to write to file. If write=FALSE,
##'     NMwriteSection returns the resulting input.txt without writing
##'     it.  to disk?  Default is FALSE.
##' @param quiet The default is to give some information along the way
##'     on what data is found. But consider setting this to TRUE for
##'     non-interactive use. Default can be configured using
##'     NMdataConf.
##' @param simplify If TRUE (default) and only one file is edited, the
##'     resulting rows are returned directly. If more than one file is
##'     edited, the result will always be a list with one element per
##'     file.
##' @details The new file will be written with unix-style line
##'     endings.
##' @return The new section text is returned. If write=TRUE, this is
##'     done invisibly.
##' @family Nonmem
##' 
##' @examples
##' newlines <- "$EST POSTHOC INTERACTION METHOD=1 NOABORT PRINT=5 MAXEVAL=9999 SIG=3"
##' NMwriteSection(files=system.file("examples/nonmem/xgxr001.mod", package = "NMdata"),
##' section="EST", newlines=newlines,newfile=NULL)
##' \dontrun{
##' text.nm <- NMwriteData(data)
##' NMwriteSection(dir="nonmem",
##'               file.pattern="^run.*\\.mod",
##'               list.sections=text.nm["INPUT"])
##' }
##' @export


NMwriteSection <- function(files,file.pattern,dir,section,newlines,
                           list.sections,location="replace",newfile,
                           backup=TRUE,blank.append=TRUE,data.file,
                           write=TRUE,quiet,simplify=TRUE){

    
    
#### Section start: handle arguments ####
    if(missing(quiet)) quiet <- NULL
    quiet <- NMdataDecideOption("quiet",quiet)

    if(missing(files)) files <- NULL
    if(missing(dir)) dir <- NULL
    if(missing(file.pattern)) file.pattern <- NULL
    
    all.files <- getFilePaths(files=files,file.pattern=file.pattern,dir=dir,quiet=quiet)

    if(length(all.files)==0){
        message("No existing files matched. Nothing to do.")
        return(invisible(NULL))
    }

    
    if(!missing(data.file)){
        all.files <- all.files[sapply(all.files,function(file)NMextractDataFile(file,dir.data=NULL,file.mod=identity)$string==data.file)]
    }
    if(length(all.files)==0) stop("No files to process.")
    
    ## supply either section and newlines or a list
    if(!( (!missing(section)&&!missing(newlines)) ||
          !missing(list.sections)
    )
    ){
        stop("Either both section and newlines or list.sections must be supplied.")
    }
    if(missing(list.sections)){
        ## this must be list, not as.list. as.list would translate multiple lines into multiple sections.
        list.sections=list(newlines)
        names(list.sections) <- section
    } else {
        if(location!="replace"){
            messageWrap("Only location=replace is supported in combination with list.sections.",fun.msg=stop)
        }
    }
    
###  Section end: handle arguments


    NMwriteSectionOne <- function(file0,section,newlines,list.sections,newfile,
                                  backup=TRUE,blank.append=TRUE,write=TRUE){

        after <- NULL 
        before <- NULL
        mad.dl <- NULL
        
        file0 <- filePathSimple(file0)
        stopifnot(file.exists(file0))

        if(missing(newfile)) newfile <- file0
        if(!is.null(newfile)){
            newfile <- filePathSimple(newfile)
        }

        ## see below why we need to read the lines for now
        lines <- readLines(file0)

        ## put this part in a function to be sequentially applied for all elements in list.
        replaceOnePart <- function(lines,section,newlines){
            if(!quiet) message(paste("Writing",newfile))
            
            ## make sure section is capital and does not start with $.
            section <- gsub(" ","",section)
            section <- sub("^\\$","",section)
            section <- toupper(section)

            ## make sure newlines start with $SECTION
            newlines <- sub("^ +","",newlines)            
            if(blank.append) newlines <- c(newlines,"")
            
            idx.dlines <- NMreadSection(lines=lines,section=section,return="idx",keepEmpty=TRUE,
                                        keepName=TRUE,keepComments=TRUE,asOne=TRUE,
                                        cleanSpaces=FALSE)

            if(length(idx.dlines)==0&location%in%cc(replace,before,after)) {
                if(!quiet) message("Section not found. Nothing to be done.")
                return(lines)
            }
            
            if(length(idx.dlines)>1) {
                ## if th
                stopifnot(max(diff(idx.dlines))==1)
            }
            
            if(location%in%cc(replace,before,after)){
                min.dl <- min(idx.dlines)
                max.dl <- max(idx.dlines)

### these two cases need to be handled slightly differently so not supported for now
                
                stopifnot(min.dl>1)
            }
            nlines <- length(lines)
            
            if(location=="replace"){
                
                if(min.dl==1&&max.dl==nlines){
                    all.lines <- newlines
                } else if(min.dl==1){
                    all.lines <- c(newlines,lines[(mad.dl+1),nlines])
                } else if(max.dl==nlines){
                    all.lines <- c(lines[1:(min.dl-1)],newlines)
                } else {
                    all.lines <- c(lines[1:(min.dl-1)],
                                   newlines,
                                   lines[(max.dl+1):nlines])
                }
            }
            if(location=="before"){
                if(min.dl==1){
                    all.lines <- c(newlines,lines)
                } else {
                    all.lines <- c(lines[1:(min.dl-1)],
                                   newlines,
                                   lines[(min.dl:length(lines))]
                                   )
                } 
            }
            if(location=="after"){
                all.lines <- c(lines,newlines)
                if(min.dl>1){
                    all.lines <- c(lines[1:(max.dl)],
                                   newlines,
                                   lines[(max.dl+1):length(lines)]
                                   )
                } else {
                    all.lines <- lines
                }
            }
            if(location=="last"){
                all.lines <- c(lines,newlines)
            }
            all.lines
        }
        
        newlines <- lines
        for (I in 1:length(list.sections)) newlines <- replaceOnePart(lines=newlines,section=names(list.sections)[I],newlines=list.sections[[I]])
        
        if(is.null(newfile)) return(newlines)
        
        if(file0==newfile && backup ) {
            dir.backup <- file.path(dirname(file0),"NMdata_backup")
            ## make sure backup dir exists
            if(file.exists(dir.backup)&&!dir.exists(dir.backup)) messageWrap("Something called NMdata_backup is found and it is not a directory. Please remove or use backup=FALSE.",fun.msg=stop)
            if(!dir.exists(dir.backup)) dir.create(dir.backup)
            ## file.copy (file0,
            ##            sub("(.+/)([^/].+$)","\\1backup_\\2",x=file0)
            ##            )
            file.copy(file0,dir.backup,overwrite=T)
        }

        if(!write||is.null(file)){
            return(newlines)
        }
        
        con.newfile <- file(newfile,"wb")
        writeLines(newlines,con=con.newfile)
        close(con.newfile)
        return(invisible(newlines))
    }
    
    
    res <- lapply(all.files,NMwriteSectionOne,section=section,newlines=newlines,
                  list.sections=list.sections,newfile=newfile,
                  backup=backup,blank.append=blank.append,write=write)

    if(simplify&&length(res)==1) res <- res[[1]]
    
    return(invisible(res))
}
