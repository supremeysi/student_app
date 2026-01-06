library(shiny)
library(DBI)

# ================= UI =================
archiveUI <- function(id) {
  ns <- NS(id)
  tagList(
    # Header Section
    div(class="logs-header",
        style="margin-bottom: 25px; padding: 10px;",
        div(
          h3("Archive", style="color: #D63384; font-weight: 800; font-size: 28px; margin-bottom: 5px;"),
          tags$p("Stored notes that are no longer active. You can restore or permanently delete them.", 
                 style="color: #B28D8D; font-size: 14px; font-weight: 500;")
        )
    ),
    
    # Table Container
    div(class="table-responsive",
        style="background: white; border-radius: 25px; padding: 20px; box-shadow: 0 10px 30px rgba(255, 182, 193, 0.1); border: 1px solid #FFF0F3;",
        tags$table(
          class="table custom-table", 
          style="width: 100%; border-collapse: separate; border-spacing: 0 10px;",
          tags$thead(
            tags$tr(
              style="background: #FFF9FA;",
              tags$th("Title", style="border: none; color: #FF9AA2; border-radius: 15px 0 0 15px; padding: 15px;"),
              tags$th("Description", style="border: none; color: #FF9AA2; padding: 15px;"),
              tags$th("Priority", style="border: none; color: #FF9AA2; padding: 15px; text-align: center;"),
              tags$th("Date Archived", style="border: none; color: #FF9AA2; padding: 15px;"),
              tags$th("Action", style="border: none; color: #FF9AA2; border-radius: 0 15px 15px 0; padding: 15px; text-align: center;")
            )
          ),
          uiOutput(ns("archive_rows"), container = tags$tbody)
        )
    )
  )
}

# ================= SERVER =================
archiveServer <- function(id, pool, global_refresh) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    archiveData <- reactive({
      global_refresh()
      dbGetQuery(pool, "SELECT id, title, description, priority, note_datetime, CAST(archived_at AS CHAR) as archived_at FROM archives ORDER BY archived_at DESC")
    })
    
    output$archive_rows <- renderUI({
      df <- archiveData()
      if (nrow(df) == 0) {
        return(tags$tr(tags$td(colspan=5, style="text-align:center; padding: 40px; color: #B28D8D;", 
                               tags$i(class="fa-solid fa-box-open", style="font-size: 30px; display: block; margin-bottom: 10px; opacity: 0.5;"),
                               "The archive is empty.")))
      }
      
      tagList(lapply(seq_len(nrow(df)), function(i) {
        n <- df[i,]
        
        prio_color <- switch(n$priority, 
                             "High" = "#FF5A5A", 
                             "Medium" = "#FFA534", 
                             "Low" = "#57D163", 
                             "#F78FB3")
        
        tags$tr(
          style="background: white; box-shadow: 0 4px 15px rgba(0,0,0,0.02); transition: transform 0.2s;",
          tags$td(strong(n$title), style="padding: 15px; vertical-align: middle;"),
          tags$td(n$description, style="padding: 15px; vertical-align: middle; color: #7A5C5C; max-width: 300px;"),
          tags$td(
            style="padding: 15px; vertical-align: middle; text-align: center;",
            span(n$priority, style=paste0("background:", prio_color, "; color: white; padding: 5px 15px; border-radius: 20px; font-size: 11px; font-weight: 700; text-transform: uppercase;"))
          ),
          tags$td(
            style="padding: 15px; vertical-align: middle; color: #B28D8D; font-size: 13px;",
            tags$i(class="fa-regular fa-clock", style="margin-right: 5px;"),
            format(as.POSIXct(n$archived_at), "%b %d, %I:%M %p")
          ),
          tags$td(
            style="padding: 15px; vertical-align: middle; text-align: center;",
            div(class="action-wrap", style="position: relative; display: inline-block;",
                tags$button(tags$i(class="fa-solid fa-ellipsis-vertical"), 
                            class="action-btn",
                            style="background: #FFF0F3; border: none; border-radius: 10px; padding: 5px 12px; color: #FF9AA2;",
                            onclick="event.stopPropagation(); var menu = this.nextElementSibling; $('.action-menu').not(menu).hide(); $(menu).toggle();"),
                div(class="action-menu", 
                    style="display: none; position: absolute; right: 0; z-index: 1000; background: white; border-radius: 15px; box-shadow: 0 10px 25px rgba(0,0,0,0.1); min-width: 140px; padding: 8px; border: 1px solid #FFF0F3;",
                    # TEXT ONLY BUTTONS
                    tags$button("Unarchive", 
                                style="display: block; width: 100%; text-align: left; padding: 10px 15px; border: none; background: none; color: #D63384; font-weight: 600; font-size: 13px;",
                                onclick=sprintf("Shiny.setInputValue('%s', %d, {priority:'event'})", ns("restore_archive"), n$id)),
                    tags$hr(style="margin: 4px 0; border-top: 1px solid #FFF0F3;"),
                    tags$button("Move to Trash", 
                                style="display: block; width: 100%; text-align: left; padding: 10px 15px; border: none; background: none; color: #ff5a5a; font-weight: 600; font-size: 13px;",
                                onclick=sprintf("Shiny.setInputValue('%s', %d, {priority:'event'})", ns("move_to_trash"), n$id))
                )
            )
          )
        )
      }))
    })
    
    # RESTORE LOGIC 
    observeEvent(input$restore_archive, {
      req(input$restore_archive)
      conn <- poolCheckout(pool); on.exit(poolReturn(conn))
      
      tryCatch({
        dbBegin(conn)
        dbExecute(conn, sqlInterpolate(conn, 
                                       "INSERT INTO archives (title, description, note_datetime, priority, status, archived_at) 
                                        SELECT title, description, note_datetime, priority, status, datetime('now', 'localtime') 
                                        FROM notes WHERE id = ?id", id = as.integer(idToArchive())))
        
        dbExecute(conn, sqlInterpolate(conn, "DELETE FROM archives WHERE id = ?id", id = as.integer(input$restore_archive)))
        dbCommit(conn)
        
        global_refresh(global_refresh() + 1)
        showNotification("Note restored to main board!", type = "message")
      }, error = function(e) {
        dbRollback(conn)
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    # MOVE TO TRASH LOGIC 
    observeEvent(input$move_to_trash, {
      req(input$move_to_trash)
      conn <- poolCheckout(pool); on.exit(poolReturn(conn))
      
      tryCatch({
        dbBegin(conn)
        dbExecute(conn, sqlInterpolate(conn, 
                                       "INSERT INTO trash (title, description, note_datetime, priority, status, deleted_at) 
           SELECT title, description, note_datetime, priority, status, datetime('now', 'localtime') 
           FROM archives WHERE id = ?id", 
                                       id = as.integer(input$move_to_trash)))
        
        # 2. Burahin sa archives table
        dbExecute(conn, sqlInterpolate(conn, "DELETE FROM archives WHERE id = ?id", id = as.integer(input$move_to_trash)))
        dbCommit(conn)
        
        global_refresh(global_refresh() + 1)
        showNotification("Moved to Trash permanently", type = "warning")
      }, error = function(e) {
        dbRollback(conn); showNotification(e$message, type = "error")
      })
    })
  })
}