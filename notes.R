# notesUI function
notesUI <- function(id) {
  ns <- NS(id)
  tagList(
    tags$head(
      tags$link(rel="stylesheet", href="https://cdn.jsdelivr.net/npm/fullcalendar@6.1.10/index.global.min.css"),
      tags$script(src="https://cdn.jsdelivr.net/npm/fullcalendar@6.1.10/index.global.min.js"),
      tags$script(src="https://cdn.jsdelivr.net/npm/canvas-confetti@1.6.0/dist/confetti.browser.min.js"),
      
      tags$style(HTML(paste0("
        /* --- GLOBAL & FONTS --- */
        @import url('https://fonts.googleapis.com/css2?family=Nunito:wght@400;700;850&display=swap');
        body { background-color: #FFF5F7; font-family: 'Nunito', sans-serif; }

        .greeting-card, .stat-card, .calendar-container, .progress-container {
          animation: slideUpFade 0.8s ease-out forwards;
          opacity: 0;
        }
        @keyframes slideUpFade {
          from { opacity: 0; transform: translateY(20px); }
          to { opacity: 1; transform: translateY(0); }
        }
        
        .notif-dropdown {
          display: none; 
          position: absolute; 
          right: 0; 
          top: 55px; 
          width: 320px; 
          background: white; 
          border-radius: 20px; 
          z-index: 9999; 
          border: 1px solid #FFE4E1; 
          box-shadow: 0 15px 35px rgba(255, 182, 193, 0.25);
          overflow: hidden;
        }
        .notif-dropdown::before {
          content: '';
          position: absolute;
          top: -10px;
          right: 20px;
          border-left: 10px solid transparent;
          border-right: 10px solid transparent;
          border-bottom: 10px solid white;
        }
        .notif-header {
          padding: 15px 20px;
          background: #FFF9FA;
          border-bottom: 1px solid #FFE4E1;
          display: flex;
          justify-content: space-between;
          align-items: center;
        }
        .notif-item {
          padding: 15px 20px;
          display: flex;
          align-items: center;
          gap: 12px;
          border-bottom: 1px solid #FFF0F3;
          transition: background 0.2s;
        }
        .notif-item:hover { background: #FFFDFE; }
        .notif-icon-pink {
          width: 35px;
          height: 35px;
          background: #FFE4E1;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          color: #FF85A1;
        }

        /* --- CENTERED MODAL --- */
        .modal-body {
          text-align: center !important;
          display: flex;
          flex-direction: column;
          align-items: center;
          padding: 30px !important;
        }
        .details-box {
          width: 100%;
          display: flex;
          flex-direction: column;
          align-items: center;
        }
        .modal-footer {
          justify-content: center !important;
          border: none !important;
          padding-bottom: 25px !important;
        }

        /* Bell Badge */
        .pink-red-dot {
          position: absolute;
          top: 5px;
          right: 5px;
          width: 10px;
          height: 10px;
          background: #FF4D6D;
          border-radius: 50%;
          border: 2px solid white;
        }

        /* --- HEADER AREA --- */
        .header-top {
          display: flex;
          justify-content: flex-end;
          align-items: center;
          padding: 10px 30px;
        }

        /* --- STATS DASHBOARD (Paayos na Cards) --- */
        .stats-container { display: flex; gap: 15px; margin-bottom: 20px; flex-wrap: wrap; }
        .stat-card {
           flex: 1; min-width: 140px; background: white; padding: 20px 10px; border-radius: 25px;
           text-align: center; border: 2px solid #FFD1DC; box-shadow: 0 8px 15px rgba(255, 182, 193, 0.2);
           transition: all 0.3s ease;
        }
        .stat-card:hover { transform: translateY(-5px); box-shadow: 0 12px 20px rgba(255, 182, 193, 0.3); }
        .stat-card i { font-size: 24px; margin-bottom: 8px; }
        .stat-card h3 { font-size: 28px; font-weight: 850; margin: 0; color: #D63384; }
        .stat-card p { font-size: 11px; color: #FF85A1; font-weight: 700; margin: 0; text-transform: uppercase; }

        /* --- PROGRESS BAR (Paayos na Progress) --- */
        .progress-container { 
          background: white; padding: 20px 25px; border-radius: 25px; margin-bottom: 30px; 
          border: 2px solid #FFD1DC; box-shadow: 0 5px 15px rgba(255, 182, 193, 0.1);
        }
        .progress-label { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
        .progress-label span { color: #D63384; font-weight: 850; font-size: 15px; }
        .custom-progress { height: 14px; background-color: #FFF0F3; border-radius: 10px; overflow: hidden; }
        .custom-progress-bar { 
          height: 100%; 
          background: linear-gradient(90deg, #FFB7B2 0%, #FF758F 100%); 
          border-radius: 10px; 
          transition: width 1s ease-in-out; 
        }

        /* --- GREETING CARD --- */
        .greeting-card { 
          background: linear-gradient(135deg, #FF85A1 0%, #FFB7B2 100%) !important; 
          padding: 30px 40px; border-radius: 35px; position: relative; color: white; margin-bottom: 25px;
          box-shadow: 0 10px 25px rgba(255, 133, 161, 0.3);
        }
        .bunny-img { position: absolute; right: 20px; bottom: -10px; width: 220px; animation: float 4s ease-in-out infinite; }
        @keyframes float { 0%, 100% { transform: translateY(0px); } 50% { transform: translateY(-15px); } }

        /* --- CALENDAR --- */
        .calendar-container { 
          background: white; padding: 25px; border-radius: 35px; border: 3px solid #FFD1DC; 
          box-shadow: 0 10px 30px rgba(255, 182, 193, 0.2); 
        }
        .fc-toolbar-title { color: #D63384 !important; font-weight: 850 !important; }
        .fc-button-primary { 
          background-color: #FF85A1 !important; border: none !important; border-radius: 12px !important;
          font-weight: 700 !important; 
        }
        .fc-button-primary:hover { background-color: #FF4D6D !important; }
        .fc-col-header-cell { background-color: #FF85A1; color: #D63384; padding: 10px 0 !important; }
        .fc-daygrid-day-number { color: #FF85A1; font-weight: 700; padding: 8px !important; }
        .fc-day-today { background-color: #FFF0F3 !important; }
        
        /* Modal Style */
        .modal-content { border-radius: 35px !important; border: 4px solid #FFD1DC !important; }
        .btn-close-girly { background: #FF85A1 !important; color: white !important; border-radius: 20px !important; border: none !important; font-weight: 800; padding: 8px 25px !important; }
      ")))
    ),
    
    # HEADER
    div(class="header-top",
        div(class="notif-wrapper", style="position:relative;",
            tags$audio(
              id = ns("notif_sound"), 
              src = "sounds/notification.mp3", 
              type = "audio/mpeg",
              preload = "auto"
            ),
            div(id = ns("bell_btn"), style="cursor:pointer; position:relative; padding: 5px;",
                tags$i(class="fa-solid fa-bell", style="font-size: 26px; color: #FF85A1;"),
                uiOutput(ns("bell_dot"))
            ),
            div(id = ns("notif_box"), class="notif-dropdown", style="display:none; position:absolute; right:0; top:45px; width:280px; background:white; border-radius:20px; z-index:9999; border:2px solid #FFD1DC; box-shadow: 0 5px 15px rgba(0,0,0,0.1);",
                div(style="padding:15px; background:#FFF9FA; border-radius:20px 20px 0 0; text-align:center;", tags$b("Notifications ", style="color:#D63384;")),
                uiOutput(ns("notif_list"))
            )
        )
    ),
    
    # GREETING
    div(class="greeting-card",
        div(style="max-width: 65%;", 
            h2(uiOutput(ns("display_greeting")), style="font-weight:850; font-size: 34px; margin:0;"),
            p("Keep shining! You're doing a great job today. ", style="font-size:16px; opacity:0.95; font-weight: 600;")
        ),
        tags$img(src="images/bunny.png", class="bunny-img")
    ),
    
    # STATS & PROGRESS
    uiOutput(ns("stats_dashboard")),
    
    # CALENDAR
    div(class="calendar-container",
        div(id = ns("calendar_full"))
    ),
    
    tags$script(HTML(sprintf("
      function initCalendar() {
        var el = document.getElementById('%s-calendar_full');
        if (!el) return;
        el.innerHTML = '';
        var calendar = new FullCalendar.Calendar(el, {
          initialView: 'dayGridMonth',
          height: 650,
          displayEventTime: true,
          eventDisplay: 'block', 
          headerToolbar: { left: 'prev,next today', center: 'title', right: 'dayGridMonth' },
          eventClick: function(info) {
            info.el.style.opacity = '0.5';
            Shiny.setInputValue('%s-event_clicked', {
              title: info.event.title,
              description: info.event.extendedProps.description,
              start: info.event.start,
              priority: info.event.extendedProps.priority,
              nonce: Math.random() 
            }, {priority: 'event'});
            setTimeout(function() { info.el.style.opacity = '1'; }, 300);
          }
        });
        calendar.render();
        window.notesCalendar = calendar;
        Shiny.setInputValue('%s-calendar_ready', Math.random());
      }

      Shiny.addCustomMessageHandler('refresh-calendar', function(events) {
        if (window.notesCalendar) {
          window.notesCalendar.removeAllEvents();
          window.notesCalendar.addEventSource(events);
        }
      });

      Shiny.addCustomMessageHandler('play-notif-sound', function(message) {
        var audio = document.getElementById(message.id);
        if (audio) {
          audio.currentTime = 0;
          audio.play().catch(function(e) { console.log('Autoplay blocked'); });
        }
      });

      $(document).on('shiny:visualchange', function() { setTimeout(initCalendar, 200); });

      $(document).on('click', '#%s-bell_btn', function(e) {
          e.stopPropagation();
          var box = $('#%s-notif_box');
          box.fadeToggle(200);
          Shiny.setInputValue('%s-bell_clicked', Math.random(), {priority: 'event'});
      });

      $(document).on('click', function(e) {
          if (!$(e.target).closest('.notif-wrapper').length) {
              $('.notif-dropdown').fadeOut(200);
          }
      });
    ", id, id, id, id, id, id))) 
  )
}

# ============== SERVER =============
notesServer <- function(id, pool, user) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # State tracking
    has_unread <- reactiveVal(FALSE)
    already_notified <- reactiveVal(list())
    
    notes_data <- reactive({
      invalidateLater(5000)
      dbGetQuery(pool, "SELECT * FROM notes")
    })
    
    # ========= CALENDAR LOGIC  =============
    observe({
      df <- notes_data()
      calendar_df <- df[tolower(df$status) != "completed", ]
      
      if (nrow(calendar_df) == 0) {
        session$sendCustomMessage("refresh-calendar", list())
        return()
      }
      
      events <- lapply(1:nrow(calendar_df), function(i) {
        prio <- trimws(calendar_df$priority[i])
        
        evt_color <- dplyr::case_when(
          prio == "High"   ~ "#FFADAD", 
          prio == "Medium" ~ "#FFD6A5", 
          prio == "Low"    ~ "#CAFFBF", 
          TRUE             ~ "#FFC6FF"  
        )
        
        list(
          title = paste0("[", prio, "] ", calendar_df$title[i]), 
          start = calendar_df$note_datetime[i], 
          backgroundColor = evt_color, 
          borderColor = evt_color,
          textColor = if(prio == "Low") "#5D4037" else "white", 
          extendedProps = list(
            description = calendar_df$description[i], 
            priority = prio
          )
        )
      })
      session$sendCustomMessage("refresh-calendar", events)
    })
    
    # --- DOT LOGIC ---
    output$bell_dot <- renderUI({
      req(has_unread())
      div(class = "pink-red-dot")
    })
    
    observeEvent(input$bell_clicked, {
      has_unread(FALSE)
    })
    
    # --- NOTIFICATION LIST ---
    output$notif_list <- renderUI({
      df <- notes_data()
      now <- Sys.time()
      urgent <- df[tolower(df$status) != "completed" & as.POSIXct(df$note_datetime) <= (now + 86400), ]
      
      if (nrow(urgent) == 0) {
        return(div(style="padding:20px; text-align:center; color:#B28D8D;", "No new notifications "))
      }
      
      lapply(1:nrow(urgent), function(i) {
        div(class="notif-item",
            div(class="notif-icon-pink", tags$i(class="fa-solid fa-star")),
            div(class="notif-content",
                p(style="margin:0; font-weight:700; font-size:13px; color:#D63384;", urgent$title[i]),
                p(style="margin:0; font-size:11px; color:#7A5C5C;", 
                  paste("Approaching at", format(as.POSIXct(urgent$note_datetime[i]), "%I:%M %p")))
            )
        )
      })
    })
    
    # --- ALERTS & SOUNDS ---
    observe({
      df <- notes_data()
      now <- Sys.time()
      
      new_urgent <- df[tolower(df$status) != "completed" & 
                         as.POSIXct(df$note_datetime) > now & 
                         as.POSIXct(df$note_datetime) <= (now + 3600), ]
      
      if (nrow(new_urgent) > 0) {
        triggered <- FALSE
        current_notified <- already_notified()
        
        for (i in seq_len(nrow(new_urgent))) {
          task_id <- as.character(new_urgent$id[i]) 
          if (!(task_id %in% current_notified)) {
            current_notified <- c(current_notified, task_id)
            triggered <- TRUE
          }
        }
        
        if (triggered) {
          already_notified(current_notified)
          has_unread(TRUE)
          session$sendCustomMessage("play-notif-sound", list(id = ns("notif_sound")))
        }
      }
    })
    
    # --- DASHBOARD LOGIC  ---
    completion_pct <- reactive({
      df <- notes_data()
      if (is.null(df) || nrow(df) == 0) return(0)
      completed <- sum(tolower(df$status) == "completed", na.rm = TRUE)
      total <- nrow(df)
      return(round((completed / total) * 100))
    })
    
    output$stats_dashboard <- renderUI({
      df <- notes_data()
      total <- if(is.null(df)) 0 else nrow(df)
      completed <- if(is.null(df)) 0 else sum(tolower(df$status) == "completed", na.rm = TRUE)
      pending <- total - completed
      pct <- completion_pct()
      
      tagList(
        div(class="stats-container",
            div(class="stat-card", tags$i(class="fa-solid fa-heart", style="color: #FF9AA2;"), h3(total), p("ALL NOTES")),
            div(class="stat-card", tags$i(class="fa-solid fa-star", style="color: #FFA534;"), h3(pending), p("PENDING")),
            div(class="stat-card", tags$i(class="fa-solid fa-circle-check", style="color: #57D163;"), h3(completed), p("COMPLETED"))
        ),
        div(class="progress-container",
            div(class="progress-label",
                span(if(total > 0 && pct == 100) "Yay! All tasks completed! " else paste0(pct, "% done!")),
                span(tags$i(class="fa-solid fa-rabbit"), style="color: #FF9AA2;")
            ),
            div(class="custom-progress",
                div(class="custom-progress-bar", style = sprintf("width: %d%%; background: %s;", pct, if(pct == 100) "#57D163" else "#FF758F"))
            )
        )
      )
    })
    
    # ========= GREETINGS & MODAL =============
    output$display_greeting <- renderUI({
      h <- as.numeric(format(Sys.time(), "%H", tz = "Asia/Manila"))
      msg <- if(h < 12) "Good Morning" else if(h < 18) "Good Afternoon" else "Good Evening"
      paste0(msg, "!") 
    })
    
    observeEvent(input$event_clicked, {
      req(input$event_clicked)
      event <- input$event_clicked
      showModal(modalDialog(
        title = NULL, 
        div(class="details-box",
            tags$i(class="fa-solid fa-circle-info", style="font-size: 50px; color: #FFD1DC; margin-bottom: 15px;"),
            h2(strong(event$title), style="color: #D63384; margin: 0; font-weight: 850;"),
            tags$hr(style="border-top: 2px solid #FFF0F3; width: 80%; margin: 20px 0;"),
            p(style="font-size: 18px; color: #7A5C5C;", event$description %||% "No description."),
            p(style="color: #FF85A1; font-weight: 600;", format(as.POSIXct(event$start), "%B %d, %Y at %I:%M %p"))
        ),
        footer = actionButton(ns("close_details"), "Got it!", class="btn-close-girly"),
        easyClose = TRUE
      ))
    })
    
    observeEvent(input$close_details, { removeModal() })
  })
}