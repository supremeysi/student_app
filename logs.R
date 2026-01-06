library(shiny)
library(DBI)

# ================= UI =================
logsUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    tags$head(
      tags$link(
        rel = "stylesheet",
        href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css"
      ),
      
      # ===== AUDIO ELEMENT FOR ALERTS =====
      tags$audio(id = ns("deadline_sound"), 
                 src = "https://actions.google.com/sounds/v1/alarms/beep_short.ogg", 
                 type = "audio/ogg"),
      
      # ===== SCRIPTS =====
      tags$script(HTML(sprintf("
        function startVoice(inputId, shinyId) {
          var el = document.getElementById(inputId);
          if(!('webkitSpeechRecognition' in window)) return alert('Browser not supported');
          
          var recognition = new webkitSpeechRecognition();
          recognition.lang = 'en-US';
          
          recognition.onresult = function(e) {
            var val = e.results[0][0].transcript;
            el.value = val;
            
            Shiny.setInputValue(shinyId, val);
            
            $(el).trigger('input');
            $(el).trigger('change');
          };
          recognition.start();
        }
        
        Shiny.addCustomMessageHandler('play_deadline_sound', function(message) {
          var audio = document.getElementById(message.id);
          if(audio) { audio.currentTime = 0; audio.play(); }
        });
      "))),
      
      # ===== JAVASCRIPT FOR SELECT ALL & BATCH ACTIONS =====
      tags$script(HTML(paste0("
        $(document).on('change', '#", ns("select_all"), "', function() {
          $('.row-checkbox').prop('checked', this.checked);
          updateSelectedRows();
        });

        $(document).on('change', '.row-checkbox', function() {
          if ($('.row-checkbox:checked').length == $('.row-checkbox').length) {
            $('#", ns("select_all"), "').prop('checked', true);
          } else {
            $('#", ns("select_all"), "').prop('checked', false);
          }
          updateSelectedRows();
        });

        function updateSelectedRows() {
          var selected = [];
          $('.row-checkbox:checked').each(function() {
            selected.push($(this).val());
          });
          Shiny.setInputValue('", ns("selected_rows"), "', selected);
        }
        
       Shiny.addCustomMessageHandler('reset_checkboxes', function(message) {
         $('.row-checkbox').prop('checked', false);
         $('#' + message.selectAllId).prop('checked', false);
       Shiny.setInputValue(message.selectAllId.replace('-select_all', '-selected_rows'), null);
      });
      "))),
      
      # ===== STYLES  =====
      tags$style(HTML("
         body{
          background:#FFF5FA;
         }
        
        .btn-add, .btn-add:focus, .btn-add:active, .btn-add:hover {
          background: #F78FB3 !important;
          color: white !important;
          border: none !important;
          box-shadow: 0 4px 12px rgba(247, 143, 179, 0.4) !important;
          outline: none !important;
          transition: transform 0.2s ease;
        }
        
        .btn-add:hover {
          transform: translateY(-2px);
          filter: brightness(1.05);
        }

        .btn-add:active {
          transform: translateY(0px);
        }

        /* HEADER */
        .logs-header{
          display:flex;
          justify-content:space-between;
          align-items:center;
          margin-bottom:16px;
        }

        .logs-header h3{
          color:#D63384;
          font-weight:800;
          margin:0;
        }
        
        /* Test Sound Button */
        .btn-test-sound { 
          background:none; 
          border:none; 
          color:#F78FB3; 
          cursor:pointer; 
          font-size:16px; 
        }

        .btn-add{
          background:#F78FB3;
          color:white;
          border:none;
          padding:10px 22px;
          border-radius:30px;
          font-weight:600;
        }
        
        /* Priority and Status Columns */
        .table td:nth-child(4), 
        .table td:nth-child(5) {
          text-align: center;
          vertical-align: middle;
        }
        
         /* FILTER BAR */
        .filter-bar{
          display:flex;
          gap:12px;
          margin-bottom:14px;
        }

        .filter-bar input,
        .filter-bar select{
          border-radius:20px;
          border:1px solid #F3C4D6;
          padding:8px 14px;
        }

        /* ===== MODAL ===== */
        .modal-body {
          background: #FFF0F6;
          padding: 30px !important;
          display: block; 
          text-align: left;
       }

       .modal-title {
         color: #C2255C;
         font-weight: 800;
         font-size: 24px;
         margin-bottom: 5px;
         text-align: center; 
       }
      
       .modal-content {
         border-radius: 40px !important; 
         border: none !important;
         box-shadow: 0 25px 50px rgba(214, 51, 132, 0.2) !important;
       }

       #logs-status_container .selectize-control {
         width: 180px !important; 
      }

      .modal-section {
         background: white;
         border-radius: 25px; 
         padding: 20px;
         margin-bottom: 20px;
         border: 1px solid #F3C4D6;
         width: 100%;
      }

      /* Mic Button */
      .mic-btn {
        border: none;
        background: #F78FB3 !important; 
        color: white !important; 
        border-radius: 50%; 
        width: 45px;
        height: 45px;
        display: flex;
        align-items: center;
        justify-content: center;
        box-shadow: 0 4px 10px rgba(247, 143, 179, 0.3);
        transition: all 0.2s ease;
        flex-shrink: 0; 
      }

      .mic-btn:hover {
        background: #F06292 !important;
        transform: scale(1.1);
      }

      .input-mic-wrap {
        display: flex;
        align-items: flex-end; 
        gap: 15px;
        width: 100%;
      }

      .modal-section {
        background: white;
        border-radius: 20px;
        padding: 20px;
        margin-bottom: 15px;
        border: 1px solid #F3C4D6;
        width: 100%;
        text-align: left;
      }

      /* Footer alignment */
      .modal-actions {
        display: flex;
        gap: 15px;
        justify-content: flex-end !important; 
        width: 100%;
        margin-top: 20px;
      }
       
        /* SAVE BUTTONS */
        .save-btn,
        .cancel-btn{
          transition:all .25s ease;
        }

        .save-btn{
          background:#F78FB3;
          color:white;
          border:none;
          padding:10px 30px;
          border-radius:999px;
          font-weight:600;
        }

        .save-btn:hover{
          background:#F06292;
          transform:translateY(-2px);
        }
        
        /* CANCEL BUTTONS */
        .cancel-btn {
          background: #FFD6E8 !important; 
          color: #C2255C !important;
          border: none !important;
          padding: 10px 26px;
          border-radius: 999px;
          font-weight: 600;
        }

        .cancel-btn:hover {
          background: #F8BBD0 !important;
          transform: translateY(-2px);
        }

       /* FILTER BAR STYLE */
        .filter-bar { display:flex; gap:12px; margin-bottom:20px; background:white; padding:15px; border-radius:20px; box-shadow: 0 4px 15px rgba(0,0,0,0.05); }
        .filter-bar input, .filter-bar select { border-radius:20px; border:1px solid #F3C4D6; padding:8px 14px; outline:none; }

        /* TABLE STYLES */
        .table-container { background: white; border-radius: 30px; padding: 15px; box-shadow: 0 10px 30px rgba(247, 143, 179, 0.15); border: 2px solid #FFE4ED; }
        .table thead th { background: #FFD6E8 !important; color: #D63384 !important; text-align: center; padding: 18px !important; font-size: 13px; border:none !important; }
        .table tbody td { vertical-align: middle !important; text-align: center; color: #666; border-bottom: 1px solid #FFF0F6; }
        .table tbody td:nth-child(2), .table tbody td:nth-child(3) { text-align: left; }

        /* COMPLETED DESIGN */
        .note-completed { text-decoration: line-through; opacity: 0.6; color: #28a745 !important; }
        .status-badge { padding: 5px 12px; border-radius: 12px; font-size: 10px; font-weight: 700; display: inline-block; }
        .status-completed { background: #D1E7DD !important; color: #0F5132 !important; border: 1px solid #A3CFBB; }
        .status-pending { background: #FFF3CD; color: #856404; }

        /* PRIORITY PILLS */
        .priority-pill { padding: 6px 15px; border-radius: 20px; color: white; font-weight: 700; font-size: 11px; }
        .priority-high { background: #FF5A5A; }
        .priority-medium { background: #FFA534; }
        .priority-low { background: #57D163; }

        /* BATCH ACTIONS */
        .batch-actions-bar { background: #FFE4ED; padding: 15px 25px; border-radius: 20px; margin-bottom: 20px; display: flex; align-items: center; gap: 15px; border: 2px solid #F3C4D6; }
        .btn-bulk-delete { background: #FF5A5A !important; color: white !important; border: none; padding: 8px 18px; border-radius: 15px; font-weight: 600; cursor: pointer; opacity: 1 !important; }
        
        /* ACTION MENU */
        .action-menu { position:absolute; right:0; top:26px; background:white; border-radius:12px; box-shadow:0 8px 24px rgba(0,0,0,.15); width:140px; display:none; z-index:100; }
        .action-menu button { width:100%; border:none; background:none; padding:10px 14px; text-align:left; font-size:14px; }
        .action-menu button:hover { background:#FCE4EC; }
        
        .btn-add { background: #F78FB3; color: white; border-radius: 25px; padding: 10px 25px; font-weight: 700; border: none; }
        .btn-bulk-delete { background: #FF5A5A; color: white; border: none; padding: 8px 18px; border-radius: 15px; font-weight: 600; }
        
        /* ACTION MENU */
        .action-wrap{
          position:relative;
          text-align:center;
        }

        .action-btn{
          background:none;
          border:none;
          font-size:18px;
          cursor:pointer;
        }

        .action-menu{
          position:absolute;
          right:0;
          top:26px;
          background:white;
          border-radius:12px;
          box-shadow:0 8px 24px rgba(0,0,0,.15);
          width:140px;
          display:none;
          z-index:10;
        }

        .action-menu button{
          width:100%;
          border:none;
          background:none;
          padding:10px 14px;
          text-align:left;
          font-size:14px;
        }

        .action-menu button:hover{
          background:#FCE4EC;
        }
        
        .btn-complete {
          background: none;
          border: none;
          color: #28a745;
          font-size: 18px;
          cursor: pointer;
          margin-right: 10px;
          transition: transform 0.2s;
        }

        .btn-complete:hover {
          transform: scale(1.2);
          color: #218838;
        }

        .note-completed {
          text-decoration: line-through;
          opacity: 0.6;
          transition: all 0.3s ease;
        }

        .status-badge {
          padding: 4px 12px;
          border-radius: 12px;
          font-size: 11px;
          font-weight: 700;
          text-transform: uppercase;
        }
        .status-completed { background: #D1E7DD; color: #0F5132; }
        .status-pending { background: #FFF3CD; color: #856404; }
      "))
    ),
    
    # ===== HEADER ====== 
    div(class="logs-container",
        div(class="logs-header",
            h3("My Notes"),
            actionButton(ns("add"), "Add New Note", class="btn-add", icon = icon("plus"))
        ),
        
        # FILTER & SEARCH BAR
        div(class="filter-bar",
            textInput(ns("search"), NULL, placeholder = "Search notes...", width = "300px"),
            selectInput(ns("priorityFilter"), NULL, choices = c("All Priorities" = "All", "High", "Medium", "Low"), width = "150px")
        ),
        
        uiOutput(ns("batch_ui")),
        
        div(class="table-responsive table-container",
            tags$table(class="table",
                       tags$thead(
                         tags$tr(
                           tags$th(style="width: 50px;", tags$input(type="checkbox", id=ns("select_all"), 
                                                                    onclick=sprintf("$('.row-checkbox').prop('checked', this.checked).trigger('change');"))),
                           tags$th("Title"),
                           tags$th("Description"),
                           tags$th("Date & Time"),
                           tags$th("Priority"),
                           tags$th("Status"),
                           tags$th("Action")
                         )
                       ),
                       uiOutput(ns("rows"), container = tags$tbody)
            )
        )
    )
  )
}

# ================= SERVER =================
logsServer <- function(id, pool, global_refresh) {
  moduleServer(id, function(input, output, session) {
    
    ns <- session$ns
    refresh <- reactiveVal(0)
    
    # --- INTERNAL STATES ---
    refresh <- reactiveVal(0)
    editingId <- reactiveVal(NULL)
    idToDelete <- reactiveVal(NULL)
    idToArchive <- reactiveVal(NULL)
    remindedIds <- reactiveVal(integer())
    
    # ================= PRIORITY LOGIC =================
    detectPriority <- function(text) {
      text <- tolower(text)
      if (grepl("exam|deadline|urgent|submission|test|capstone|research|requirements|bills|scholarship|defense", text)) return("High")
      if (grepl("project|meeting|homework|group work|assignment|reviewer|documentation|workout", text)) return("Medium")
      "Low"
    }
    
    # Data Loading
    notesData <- reactive({
      refresh()
      global_refresh()
      dbGetQuery(pool, "SELECT * FROM notes ORDER BY note_datetime DESC")
    })
    
    
    # ===== FILTERED DATA =====
    filteredData <- reactive({
      df <- notesData()
      
      if (input$search != "") {
        df <- df[grepl(input$search, df$title, ignore.case = TRUE) |
                   grepl(input$search, df$description, ignore.case = TRUE), ]
      }
      
      if (input$priorityFilter != "All") {
        df <- df[df$priority == input$priorityFilter, ]
      }
      
      df
    })
    
    # ================= TABLE ROWS =================
    output$rows <- renderUI({
      df <- filteredData()
      if (is.null(df) || nrow(df) == 0) return(tags$tr(tags$td(colspan=7, style="padding:40px;", "No records found.")))
      
      tagList(lapply(seq_len(nrow(df)), function(i) {
        n <- df[i,]
        is_done <- n$status == "Completed"
        
        tags$tr(
          tags$td(tags$input(type="checkbox", class="row-checkbox", value=n$id)),
          tags$td(class = if(is_done) "note-completed" else "", style="font-weight:600;", n$title),
          tags$td(class = if(is_done) "note-completed" else "", n$description),
          tags$td(format(as.POSIXct(n$note_datetime), "%b %d, %I:%M %p")),
          tags$td(span(class=paste0("priority-pill priority-", tolower(n$priority)), n$priority)),
          tags$td(span(class=paste0("status-badge ", if(is_done) "status-completed" else "status-pending"), n$status)),
          tags$td(div(style="position:relative; display:flex; justify-content:center; gap:8px;",
                      if(!is_done) {
                        tags$button(tags$i(class="fa-solid fa-check-circle"), 
                                    style="color:#28a745; border:none; background:none; font-size:18px; cursor:pointer;",
                                    onclick=paste0("Shiny.setInputValue('", ns("quick_complete"), "',", n$id, ",{priority:'event'})"))
                      },
                      tags$button(tags$i(class="fa-solid fa-ellipsis-vertical"), 
                                  style="border:none; background:none; cursor:pointer; font-size:18px;",
                                  onclick="var menu = this.nextElementSibling; $('.action-menu').not(menu).hide(); $(menu).toggle();"),
                      div(class="action-menu",
                          tags$button("Edit", onclick=paste0("Shiny.setInputValue('", ns("edit"), "',", n$id, ",{priority:'event'})")),
                          # IBALIK ANG ARCHIVE ACTION
                          tags$button("Archive", onclick=paste0("Shiny.setInputValue('", ns("archive"), "',", n$id, ",{priority:'event'})")),
                          tags$button("Delete", style="color:red;", onclick=paste0("Shiny.setInputValue('", ns("delete"), "',", n$id, ",{priority:'event'})"))
                      )
          ))
        )
      }))
    })
    
    # BATCH DELETE LOGIC 
    output$batch_ui <- renderUI({
      if(is.null(input$selected_rows) || length(input$selected_rows) == 0) return(NULL)
      
      div(class="batch-actions-bar",
          span(tags$strong(length(input$selected_rows)), " notes selected", style="color:#D63384;"),
          actionButton(ns("bulk_delete"), "Move to Trash", class="btn-bulk-delete", icon = icon("trash"))
      )
    })
    
    observeEvent(input$bulk_delete, {
      req(input$selected_rows)
      ids <- as.integer(input$selected_rows)
      conn <- poolCheckout(pool)
      on.exit(poolReturn(conn))
      
      tryCatch({
        dbBegin(conn)
        dbExecute(conn, sprintf(
          "INSERT INTO trash (title, description, note_datetime, priority, status, deleted_at) 
           SELECT title, description, note_datetime, priority, status, datetime('now', 'localtime') FROM notes WHERE id IN (%s)",
          paste(ids, collapse = ",")
        ))
        dbExecute(conn, sprintf("DELETE FROM notes WHERE id IN (%s)", paste(ids, collapse = ",")))
        dbCommit(conn)
        
        # Reset selection after delete
        session$sendCustomMessage("reset_checkboxes", list(selectAllId = ns("select_all")))
        
        refresh(refresh() + 1)
        global_refresh(global_refresh() + 1)
        showNotification("Batch moved to trash!", type="message")
      }, error = function(e) {
        dbRollback(conn)
        showNotification(e$message, type="error")
      })
    })
    
    # ==== SOUND BUTTON ====
    observeEvent(input$test_sound, {
      session$sendCustomMessage("play_deadline_sound", list(id = session$ns("deadline_sound")))
    })
    
    # =========== MODAL FUNCTION ===============
    showNoteModal <- function(data = NULL) {
      current_time <- if(!is.null(data)) as.POSIXct(data$note_datetime) else Sys.time()
      
      showModal(
        modalDialog(
          size = "l", easyClose = FALSE, footer = NULL,
          div(class="modal-body",
              h4(if(is.null(data)) "Create New Note" else "Edit Note", class="modal-title"),
              
              tags$p("Organize your tasks and deadlines efficiently.", 
                     style = "color: #D63384; font-size: 14px; margin-bottom: 25px; opacity: 0.8;"),
              
              # TITLE SECTION
              div(class="modal-section",
                  div(class="input-mic-wrap",
                      div(style="flex-grow: 1;", 
                          textInput(ns("title"), "Title", value = data$title %||% "", width = "100%", placeholder = "Enter note title...")
                      ),
                      tags$button(tags$i(class="fa-solid fa-microphone"), class="mic-btn",
                                  onclick=sprintf("startVoice('%s', '%s')", ns("title"), ns("title")))
                  )
              ),
              
              # DESCRIPTION SECTION
              div(class="modal-section",
                  div(class="input-mic-wrap",
                      div(style="flex-grow: 1;", 
                          textAreaInput(ns("desc"), "Description", value = data$description %||% "", height = "100px", width = "100%", placeholder = "Enter details...")
                      ),
                      tags$button(tags$i(class="fa-solid fa-microphone"), class="mic-btn", style="margin-bottom: 5px;",
                                  onclick=sprintf("startVoice('%s', '%s')", ns("desc"), ns("desc")))
                  )
              ),
              
              # SECTION: DATE, TIME, AND STATUS
              div(class="modal-section",
                  fluidRow(
                    column(4, dateInput(ns("date"), "Deadline Date", value = as.Date(current_time), width = "100%")),
                    column(2, selectInput(ns("hour"), "Hour", choices = sprintf("%02d", 1:12), selected = format(current_time, "%I"), width = "100%")),
                    column(2, selectInput(ns("min"), "Min", choices = sprintf("%02d", seq(0, 55, by=5)), selected = format(current_time, "%M"), width = "100%")),
                    column(2, selectInput(ns("period"), "AM/PM", choices = c("AM", "PM"), selected = format(current_time, "%p"), width = "100%")),
                    column(2, 
                           div(id="status_container",
                               selectInput(ns("status"), "Status", 
                                           choices = c("Pending", "Not Started", "Started", "Completed"), 
                                           selected = data$status %||% "Pending", width = "100%")
                           )
                    )
                  )
              ),
              
              # ACTIONS
              div(class="modal-actions",
                  actionButton(ns("cancel"), "Cancel", class="cancel-btn"), 
                  actionButton(ns("save"), "Save Note", class="save-btn")
              )
          )
        )
      )
    }
    
    # ================= DELETE LOGIC =================
    observeEvent(input$delete, {
      idToDelete(input$delete) 
      
      showModal(modalDialog(
        title = NULL, footer = NULL, easyClose = TRUE, size = "m",
        div(style = "text-align: center; padding: 20px;",
            div(style = "display: flex; justify-content: center; margin-bottom: 20px;",
                tags$img(src = "images/delete-bunny.png", style = "width: 350px; height: 350px; object-fit: contain;")),
            
            h3("Move to Trash?", style = "color: #D63384; font-weight: 800;"),
            p("This note will be moved to Trash and automatically deleted after 7 days.", 
              style = "color: #666; font-size: 16px; margin-bottom: 20px;"),
            
            div(style = "display: flex; justify-content: center; gap: 15px;",
                actionButton(ns("confirm_delete_cancel"), "Cancel", class = "cancel-btn", style="width: 150px;"),
                actionButton(ns("confirm_remove"), "Move to Trash", class = "save-btn", style="width: 150px; background-color: #F78FB3;")
            )
        )
      ))
    })
    
    observeEvent(input$confirm_remove, {
      req(idToDelete())
      conn <- poolCheckout(pool)
      on.exit(poolReturn(conn))
      
      tryCatch({
        dbBegin(conn)
        
        dbExecute(conn, sqlInterpolate(conn, 
                                       "INSERT INTO archives (title, description, note_datetime, priority, status, deleted_at) 
                                       SELECT title, description, note_datetime, priority, status, datetime('now', 'localtime') FROM notes WHERE id = ?id", id = as.integer(idToDelete())))
        
        
        dbExecute(conn, sqlInterpolate(conn, "DELETE FROM notes WHERE id = ?id", id = as.integer(idToDelete())))
        
        dbCommit(conn) 
        
        refresh(refresh() + 1)        
        global_refresh(global_refresh() + 1) 
        
        removeModal()
        showNotification("Moved to Trash", type = "message")
        idToDelete(NULL) 
        
      }, error = function(e) {
        dbRollback(conn)
        message("SQL Error: ", e$message) 
        showNotification(paste("Error moving to trash:", e$message), type = "error")
      })
    })
    
    observeEvent(input$confirm_delete_cancel, {
      removeModal()
      idToDelete(NULL)
    })
    
    # ================= ARCHIVE LOGIC =================
    observeEvent(input$archive, {
      idToArchive(input$archive) 
      showModal(modalDialog(
        title = NULL, footer = NULL, easyClose = TRUE, size = "m",
        div(style = "text-align: center; padding: 20px;",
            div(style = "display: flex; justify-content: center; margin-bottom: 20px;",
                tags$img(src = "images/archive-bunny.png", style = "width: 350px; height: 350px; object-fit: contain;")),
            h3("Archive this note?", style = "color: #D63384; font-weight: 800;"),
            p("This note will be moved to your Archive folder.", 
              style = "color: #666; font-size: 16px; margin-bottom: 20px;"),
            div(style = "display: flex; justify-content: center; gap: 15px;",
                actionButton(ns("confirm_archive_cancel"), "Cancel", class = "cancel-btn", style="width: 120px;"),
                actionButton(ns("confirm_archive_move"), "Archive", class = "save-btn", 
                             style="width: 120px;"))
        )
      ))
    })
    
    observeEvent(input$confirm_archive_move, {
      req(idToArchive())
      conn <- poolCheckout(pool)
      on.exit(poolReturn(conn))
      tryCatch({
        dbBegin(conn)
        dbExecute(conn, sqlInterpolate(conn, 
                                       "INSERT INTO archives (title, description, note_datetime, priority, status, archived_at) 
                                       SELECT title, description, note_datetime, priority, status, datetime('now', 'localtime') FROM notes WHERE id = ?id", 
                                       id = as.integer(idToArchive())))
        dbExecute(conn, sqlInterpolate(conn, "DELETE FROM notes WHERE id = ?id", id = as.integer(idToArchive())))
        dbCommit(conn)
        
        global_refresh(global_refresh() + 1) 
        refresh(refresh() + 1) 
        removeModal()
        showNotification("Moved to Archive!", type = "message")
      }, error = function(e) {
        dbRollback(conn); showNotification(e$message, type = "error")
      })
    })
    
    observeEvent(input$confirm_archive_cancel, {
      removeModal()
      idToArchive(NULL)
    })
    
    # ================= SAVE & EDIT MODAL =================
    observeEvent(input$save, {
      if(is.null(input$title) || input$title == "") {
        showNotification("Please add a title!", type = "error")
        return()
      }
      
      time_string <- paste0(input$hour, ":", input$min, " ", input$period)
      time_24h <- format(strptime(time_string, "%I:%M %p"), "%H:%M:00")
      dt_str <- paste(as.character(input$date), time_24h)
      
      prio  <- detectPriority(paste(input$title, input$desc))
      
      tryCatch({
        if (is.null(editingId())) {
          query <- sqlInterpolate(pool, 
                                  "INSERT INTO notes (title, description, note_datetime, priority, status) 
             VALUES (?title, ?description, ?dt, ?priority, ?status)",
                                  title = input$title, description = input$desc, dt = dt_str, 
                                  priority = prio, status = input$status
          )
        } else {
          query <- sqlInterpolate(pool,
                                  "UPDATE notes SET title=?title, description=?description, 
             note_datetime=?dt, priority=?priority, status=?status WHERE id=?id",
                                  title = input$title, description = input$desc, dt = dt_str, 
                                  priority = prio, status = input$status, id = editingId()
          )
        }
        dbExecute(pool, query)
        
        removeModal()
        editingId(NULL)
        refresh(refresh() + 1)
        showNotification("Successfully Saved!", type = "message")
      }, error = function(e) {
        showNotification(paste("Database Error:", e$message), type = "error")
      })
    })
    
    # ================= QUICK LOGIC =================
    observeEvent(input$quick_complete, {
      req(input$quick_complete)
      
      tryCatch({
        dbExecute(pool, sqlInterpolate(pool, 
                                       "UPDATE notes SET status = 'Completed' WHERE id = ?id", 
                                       id = as.integer(input$quick_complete)))
        
        refresh(refresh() + 1)
        
        showNotification("Task marked as Completed! 🎉", type = "message")
      }, error = function(e) {
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    # EVENTS
    observeEvent(input$add, { editingId(NULL); showNoteModal() })
    
    observeEvent(input$edit, {
      df <- notesData()
      note <- df[df$id == input$edit, ]
      editingId(input$edit)
      showNoteModal(note)
    })
    
    observeEvent(input$cancel, { removeModal(); editingId(NULL) })
    
    # DEADLINE CHECKER
    observe({
      invalidateLater(30000, session)
      df <- notesData()
      now <- Sys.time()
      due <- df[as.POSIXct(df$note_datetime) <= now & !(df$id %in% remindedIds()) & df$status != "Completed", ]
      
      if (nrow(due) > 0) {
        session$sendCustomMessage("play_deadline_sound", list(id = ns("deadline_sound")))
        showNotification(paste("⏰ Deadline reached:", due$title[1]), type = "warning")
        remindedIds(c(remindedIds(), due$id))
      }
    })
  })
}