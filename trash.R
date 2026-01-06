library(shiny)
library(DBI)

# ================= UI =================
trashUI <- function(id) {
  ns <- NS(id)
  tagList(
    # Header Section 
    div(class="logs-header",
        style="margin-bottom: 25px; padding: 10px; display: flex; justify-content: space-between; align-items: center;",
        div(
          h3("Trash", style="color: #D63384; font-weight: 800; font-size: 28px; margin-bottom: 5px;"),
          tags$p("Notes in Trash are automatically deleted after 7 days.", 
                 style="color: #B28D8D; font-size: 14px; font-weight: 500;")
        ),
        # Empty Trash
        actionButton(ns("empty_all"), "Empty Trash", 
                     class="btn-close-girly", 
                     style="background: #FF5A5A !important; box-shadow: 0 4px 15px rgba(255, 90, 90, 0.3);")
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
              tags$th("Date Deleted", style="border: none; color: #FF9AA2; padding: 15px;"),
              tags$th("Action", style="border: none; color: #FF9AA2; border-radius: 0 15px 15px 0; padding: 15px; text-align: center;")
            )
          ),
          uiOutput(ns("trash_rows"), container = tags$tbody)
        )
    )
  )
}

# ================= SERVER =================
trashServer <- function(id, pool, global_refresh) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    trashData <- reactive({
      global_refresh()
      dbGetQuery(pool, "SELECT id, title, description, priority, note_datetime, deleted_at FROM trash ORDER BY deleted_at DESC")
    })
    
    # --- RENDER ROWS  ---
    output$trash_rows <- renderUI({
      df <- trashData()
      if (nrow(df) == 0) {
        return(tags$tr(tags$td(colspan=5, style="text-align:center; padding: 40px; color: #B28D8D;", 
                               tags$i(class="fa-solid fa-trash-can", style="font-size: 30px; display: block; margin-bottom: 10px; opacity: 0.5;"),
                               "Trash is empty.")))
      }
      
      tagList(lapply(seq_len(nrow(df)), function(i) {
        n <- df[i,]
        prio_color <- switch(n$priority, "High" = "#FF5A5A", "Medium" = "#FFA534", "Low" = "#57D163", "#F78FB3")
        
        formatted_date <- if (is.na(n$deleted_at) || n$deleted_at == "" || n$deleted_at == "NA") {
          "No Date"
        } else {
          format(as.POSIXct(n$deleted_at), "%b %d, %I:%M %p")
        }
        
        tags$tr(
          style="background: white; box-shadow: 0 4px 15px rgba(0,0,0,0.02);",
          tags$td(strong(n$title), style="padding: 15px; vertical-align: middle;"),
          tags$td(n$description, style="padding: 15px; vertical-align: middle; color: #7A5C5C; max-width: 300px;"),
          tags$td(style="padding: 15px; vertical-align: middle; text-align: center;",
                  span(n$priority, style=paste0("background:", prio_color, "; color: white; padding: 5px 15px; border-radius: 20px; font-size: 11px; font-weight: 700;"))),
          tags$td(style="padding: 15px; vertical-align: middle; color: #B28D8D; font-size: 13px;",
                  tags$i(class="fa-regular fa-calendar-xmark", style="margin-right: 5px;"),
                  formatted_date),
          tags$td(
            style="padding: 15px; vertical-align: middle; text-align: center;",
            div(class="action-wrap", style="position: relative; display: inline-block;",
                tags$button(tags$i(class="fa-solid fa-ellipsis-vertical"), class="action-btn",
                            style="background: #FFF0F3; border: none; border-radius: 10px; padding: 5px 12px; color: #FF9AA2;",
                            onclick="event.stopPropagation(); var menu = this.nextElementSibling; $('.action-menu').not(menu).hide(); $(menu).toggle();"),
                div(class="action-menu", 
                    style="display: none; position: absolute; right: 0; z-index: 1000; background: white; border-radius: 15px; box-shadow: 0 10px 25px rgba(0,0,0,0.1); min-width: 140px; padding: 8px; border: 1px solid #FFF0F3;",
                    tags$button("Restore", style="display: block; width: 100%; text-align: left; padding: 10px 15px; border: none; background: none; color: #D63384; font-weight: 600; font-size: 13px;",
                                onclick=sprintf("Shiny.setInputValue('%s', %d, {priority:'event'})", ns("restore"), n$id)),
                    tags$hr(style="margin: 4px 0; border-top: 1px solid #FFF0F3;"),
                    tags$button("Delete Forever", style="display: block; width: 100%; text-align: left; padding: 10px 15px; border: none; background: none; color: #ff5a5a; font-weight: 600; font-size: 13px;",
                                onclick=sprintf("Shiny.setInputValue('%s', %d, {priority:'event'})", ns("permanent_delete"), n$id))
                )
            )
          )
        )
      }))
    })
    
    # EMPTY TRASH LOGIC 
    observeEvent(input$empty_all, {
      showModal(modalDialog(
        title = "Empty Trash?",
        "Are you sure you want to permanently delete all notes in the trash? This action cannot be undone.",
        footer = tagList(
          modalButton("Cancel"),
          actionButton(ns("confirm_empty"), "Yes, Empty All", class="btn-danger", style="border-radius: 15px;")
        ),
        size = "s", easyClose = TRUE
      ))
    })
    
    observeEvent(input$confirm_empty, {
      removeModal()
      dbExecute(pool, "DELETE FROM trash")
      global_refresh(global_refresh() + 1)
      showNotification("Trash has been cleared completely.", type = "warning")
    })
    
    # RESTORE LOGIC
    observeEvent(input$restore, {
      req(input$restore)
      conn <- poolCheckout(pool); on.exit(poolReturn(conn))
      tryCatch({
        dbBegin(conn)
        dbExecute(conn, sqlInterpolate(conn, 
                                       "INSERT INTO notes (title, description, note_datetime, priority, status) 
           SELECT title, description, note_datetime, priority, status 
           FROM trash WHERE id = ?id", 
                                       id = as.integer(input$restore)))
        
        dbExecute(conn, sqlInterpolate(conn, "DELETE FROM trash WHERE id = ?id", id = as.integer(input$restore)))
        
        dbCommit(conn)
        global_refresh(global_refresh() + 1)
        showNotification("Note restored!", type = "message")
      }, error = function(e) { 
        dbRollback(conn)
        showNotification(e$message, type = "error") 
      })
    })
    
    # PERMANENT DELETE LOGIC
    observeEvent(input$permanent_delete, {
      req(input$permanent_delete)
      dbExecute(pool, sqlInterpolate(pool, "DELETE FROM trash WHERE id = ?id", id = as.integer(input$permanent_delete)))
      global_refresh(global_refresh() + 1)
      showNotification("Deleted forever.", type = "warning")
    })
  })
}