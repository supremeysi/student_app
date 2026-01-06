dashboardUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    tags$head(
      tags$link(
        rel = "stylesheet", 
        href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css"
      ),
      tags$style(HTML("
        body { margin: 0; font-family: 'Poppins', sans-serif; background: #F6F7FB; }

        /* PAGE TRANSITION */
        @keyframes pageFadeIn {
          from { opacity: 0; transform: translateY(20px); }
          to { opacity: 1; transform: translateY(0); }
        }
        .page-transition { animation: pageFadeIn 0.5s ease-out forwards; }

        /* SIDEBAR */
        .sidebar {
          position: fixed; left: 0; top: 0; height: 100vh; width: 260px;
          background: #FFF4B8; padding: 25px 18px; display: flex;
          flex-direction: column; z-index: 100;
        }
        .logo img { width: 170px; display: block; margin: 0 auto 35px; }

        .menu-btn {
          display: flex; align-items: center; gap: 14px; padding: 12px 22px;
          border-radius: 30px; margin-bottom: 14px; background: transparent !important;
          border: none !important; width: 100%; font-size: 15px; cursor: pointer;
          color: #444 !important; transition: all 0.3s ease;
        }
        .menu-btn:hover, .menu-btn.active {
          background: #FF9AA2 !important; color: white !important; transform: translateX(8px);
        }

        .logout-btn { margin-top: auto; }
        .main { margin-left: 260px; min-height: 100vh; }
        .page-content { padding: 40px; }

        .modal-content { border-radius: 35px !important; border: none !important; }
        .logout-modal { text-align: center; padding: 20px; }
        
        .logout-modal img { 
          width: 180px; 
          display: block; 
          margin: 0 auto 20px; 
        }
        
        .logout-modal h4 { color: #FF9AA2; font-weight: 800; }
        .btn-modal {
          border: none !important; border-radius: 25px !important;
          padding: 12px 35px !important; font-weight: 700;
        }
        .btn-cancel { background: #FFD1D1 !important; color: #FF6B6B !important; }
        .btn-logout { background: #FF9AA2 !important; color: white !important; }
      "))
    ),
    
    uiOutput(ns("sidebar_ui")),
    
    div(class = "main",
        div(class = "page-content",
            withSpinner(
              uiOutput(ns("page_container")),
              image = "images/loading-bunny.png", 
              image.width = "300px"
            )
        )
    )
  ) 
}

# =========== SERVER ===============
dashboardServer <- function(id, pool, logged_user, global_refresh) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    current_page <- reactiveVal("dashboard")
    
    notesServer("notes_page", pool, user)
    logsServer("logs_page", pool, global_refresh)    
    archiveServer("archive_page", pool, global_refresh) 
    trashServer("trash_page", pool, global_refresh)
    
    # Navigation logic
    observeEvent(input$dashboard, current_page("dashboard"))
    observeEvent(input$logs, current_page("logs"))
    observeEvent(input$archive, current_page("archive"))
    observeEvent(input$trash, current_page("trash"))
    
    # Sidebar UI render
    output$sidebar_ui <- renderUI({
      page <- current_page()
      div(class = "sidebar",
          div(class = "logo", tags$img(src = "images/notify.png")),
          div(class = "menu",
              actionButton(ns("dashboard"), tagList(tags$i(class="fa-solid fa-lightbulb"), "Dashboard"), 
                           class = paste0("menu-btn", if(page == "dashboard") " active" else "")),
              actionButton(ns("logs"), tagList(tags$i(class="fa-solid fa-book"), "Logs Notes"), 
                           class = paste0("menu-btn", if(page == "logs") " active" else "")),
              actionButton(ns("archive"), tagList(tags$i(class="fa-solid fa-box-archive"), "Archive"), 
                           class = paste0("menu-btn", if(page == "archive") " active" else "")),
              actionButton(ns("trash"), tagList(tags$i(class="fa-solid fa-trash"), "Trash"), 
                           class = paste0("menu-btn", if(page == "trash") " active" else ""))
          ),
          actionButton(ns("logout"), tagList(tags$i(class="fa-solid fa-right-from-bracket"), "Log out"), 
                       class = "menu-btn logout-btn")
      )
    })
    
    output$page_container <- renderUI({
      page <- current_page()
      
      div(class = "page-transition",
          switch(
            page,
            "dashboard" = notesUI(ns("notes_page")), 
            "logs"      = logsUI(ns("logs_page")),
            "archive"   = archiveUI(ns("archive_page")),
            "trash"     = trashUI(ns("trash_page")),
            h3("Page not found", style="text-align:center; color:#FF9AA2;")
          )
      )
    })
    
    # ====== LOG OUT========
    observeEvent(input$logout, {
      showModal(modalDialog(
        div(class = "logout-modal",
            tags$img(src = "images/sad-bunny.png"),
            tags$h4("Leaving so soon?"),
            p("Are you sure you want to log out?", style="color: #B28D8D;"),
            div(class = "logout-actions",
                actionButton(ns("cancel_logout"), "Cancel", class = "btn-modal btn-cancel"),
                actionButton(ns("confirm_logout_btn"), "Log out", class = "btn-modal btn-logout")
            )
        ),
        footer = NULL, easyClose = TRUE, fade = TRUE
      ))
    })
    
    observeEvent(input$cancel_logout, { removeModal() })
    observeEvent(input$confirm_logout_btn, {
      removeModal()
      session$reload() 
    })
  })
}