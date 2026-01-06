# ===================== Libraries =====================
library(shiny)
library(DBI)
library(RSQLite)
library(pool)
library(shinyjs)
library(toastui)
library(shinytoastr)
library(shinycssloaders)
library(shinyWidgets)

# ===================== External Files =====================
source("dashboard.R")
source("notes.R")
source("logs.R") 
source("archive.R")
source("trash.R") 
addResourcePath("images", "images")

# ===================== Database Connection =====================
pool <- dbPool(
  RSQLite::SQLite(),
  dbname = "student_app.sqlite"
)

conn <- poolCheckout(pool)

# 1. Users Table
dbExecute(conn, "CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL
)")

# Insert default user 
dbExecute(conn, "INSERT OR IGNORE INTO users (username, password) VALUES ('macy', 'macy123')")

# 2. Notes Table
dbExecute(conn, "CREATE TABLE IF NOT EXISTS notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    description TEXT,
    color TEXT,
    note_datetime TEXT,
    priority TEXT,
    status TEXT
)")

# 3. Archives Table
dbExecute(conn, "CREATE TABLE IF NOT EXISTS archives (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    description TEXT,
    note_datetime TEXT,
    priority TEXT,
    status TEXT,
    archived_at DATETIME DEFAULT CURRENT_TIMESTAMP
)")

# 4. Trash Table
dbExecute(conn, "CREATE TABLE IF NOT EXISTS trash (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    description TEXT,
    note_datetime TEXT,
    priority TEXT,
    status TEXT,
    deleted_at DATETIME DEFAULT CURRENT_TIMESTAMP
)")

poolReturn(conn)

# ===================== UI =====================
ui <- fluidPage(
  
  tags$head(
    tags$link(
      rel = "stylesheet",
      href = "https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap"
    ),
    
    # ===== CSS =====
    tags$style(HTML("
      body {
        background-color: #FFF6C9; 
        font-family: 'Poppins', sans-serif;
      }

      .login-card {
        width: 450px;
        background: rgba(255, 255, 255, 0.95);
        padding: 50px 40px;
        border-radius: 40px;
        margin: 50px auto;
        box-shadow: 0px 15px 35px rgba(255, 164, 164, 0.2);
        text-align: center;
        border: 2px solid #FFFFFF;
      }

      .notify-logo {
        width: 220px;
        height: auto;
        margin-bottom: 10px;
      }

      .notify-sub {
        font-size: 24px; 
        font-weight: 700;
        margin-bottom: 35px;
        line-height: 1.3;
      }

      .input-box {
        position: relative;
        width: 100%;
        margin-bottom: 20px;
        display: flex;
        align-items: center;
      }

      .input-box .shiny-input-container {
        width: 100% !important;
        margin-bottom: 0 !important;
      }

      .input-box input {
        width: 100% !important;
        height: 55px;
        padding: 15px 50px 15px 60px !important; 
        border-radius: 30px !important;
        border: 2px solid #FFF5F5 !important;
        background: #FFFFFF !important;
        font-size: 15px;
        transition: all 0.3s ease;
      }

      .input-box input:focus {
        border-color: #FFA4A4 !important;
        box-shadow: 0px 0px 15px rgba(255, 164, 164, 0.2) !important;
        outline: none;
      }

      .icon-left {
        position: absolute;
        left: 22px;
        top: 50%;
        transform: translateY(-50%);
        width: 20px;
        z-index: 10;
        opacity: 0.5;
        pointer-events: none; 
      }

      .icon-eye {
        position: absolute;
        right: 22px;
        top: 50%;
        transform: translateY(-50%);
        width: 20px;
        z-index: 10;
        cursor: pointer;
        opacity: 0.6;
      }

      .login-btn {
        background: linear-gradient(135deg, #FFA4A4 0%, #FFB7B2 100%);
        font-weight: 600;
        color: white !important;
        border-radius: 30px;
        font-size: 18px;
        padding: 14px;
        width: 100%;
        border: none;
        margin-top: 10px;
        box-shadow: 0px 8px 20px rgba(255, 164, 164, 0.4);
        transition: all 0.4s ease;
      }

      .login-btn:hover {
        transform: translateY(-2px);
        box-shadow: 0px 12px 25px rgba(255, 164, 164, 0.5);
      }

      .error-msg {
        color: red;
        margin-top: 14px;
      }

      .welcome-card {
        width: 460px;
        background: #FFFFFF; 
        padding: 60px 45px;
        border-radius: 50px;
        margin: 100px auto;
        box-shadow: 0px 20px 50px rgba(255, 192, 203, 0.4); 
        text-align: center;
        border: 4px solid #FFF0F5; 
        position: relative;
      }

      .welcome-img {
        width: 230px;
        height: auto;
        margin-bottom: 25px;
        filter: drop-shadow(0px 8px 15px rgba(255, 182, 193, 0.3));
        animation: floatImage 3.5s ease-in-out infinite;
      }

      @keyframes floatImage {
        0%, 100% { transform: translateY(0); }
        50% { transform: translateY(-12px); }
      }

      .welcome-title {
        color: #FFB7B2; 
        font-size: 30px;
        font-weight: 700;
        margin-bottom: 12px;
        font-family: 'Poppins', sans-serif;
      }

      .welcome-text {
        color: #D2B4B4; 
        font-size: 15px;
        font-weight: 400;
        line-height: 1.6;
        margin-bottom: 40px;
      }

      .get-started {
        background: #FFD1DC; 
        color: #FFFFFF !important;
        border-radius: 30px;
        font-size: 18px;
        padding: 15px;
        width: 100%;
        border: none;
        font-weight: 600;
        letter-spacing: 0.5px;
        transition: all 0.4s ease;
        cursor: pointer;
        box-shadow: 0px 6px 15px rgba(255, 209, 220, 0.5);
      }

      .get-started:hover {
        background: #FFC0CB !important; 
        transform: translateY(-3px);
        box-shadow: 0px 10px 20px rgba(255, 182, 193, 0.6);
      }
      
    ")),
    
    tags$script(HTML("
      function togglePassword() {
        var p = document.getElementById('password');
        var e = document.getElementById('eye_icon');
        if (p.type === 'password') {
          p.type = 'text';
          e.src = 'images/eye-off.png';
        } else {
          p.type = 'password';
          e.src = 'images/eye.png';
        }
        
        let recognition;
      function startDictation(id){
        if (!('webkitSpeechRecognition' in window)) {
          alert('Speech recognition not supported');
          return;
        }
        recognition = new webkitSpeechRecognition();
        recognition.lang = 'en-US';
        recognition.onresult = function(e){
          document.getElementById(id).value += e.results[0][0].transcript;
        }
        recognition.start();
       }
      }
    "))
  ),
  
  uiOutput("page")
)

# ===================== SERVER =====================
server <- function(input, output, session) {
  global_refresh <- reactiveVal(0)
  
  # ==== PAGE STATE =====
  page_state <- reactiveVal("login")
  login_error <- reactiveVal("")
  logged_user <- reactiveVal("")
  
  dashboardServer("dash", pool, logged_user, global_refresh)
  
  logsServer("logs_page", pool, global_refresh)
  trashServer("trash_page", pool, global_refresh)
  archiveServer("archive_page", pool, global_refresh)
 
  
  output$page <- renderUI({
    
    if (page_state() == "login") {
      div(style = "display: flex; justify-content: center; align-items: center; min-height: 90vh;",
          div(class = "login-card",
              
              tags$img(src = "images/notify.png", class = "notify-logo"),
              
              div(class = "notify-sub",
                  tags$span("Log in ", style = "color:#5A9CB5;"),
                  tags$span("to stay ", style = "color:#FFA4A4;"),
                  tags$br(), 
                  tags$span("Notify", style = "color:#97A87A;"),
                  tags$span("-ed", style = "color:#FFA4A4;")
              ),
              
              # Username Field
              div(class = "input-box",
                  tags$img(src = "images/user.png", class = "icon-left"),
                  textInput("username", NULL, placeholder = "Enter username")
              ),
              
              # Password Field
              div(class = "input-box",
                  tags$img(src = "images/lock.png", class = "icon-left"),
                  passwordInput("password", NULL, placeholder = "Enter password"),
                  tags$img(
                    src = "images/eye.png",
                    class = "icon-eye",
                    id = "eye_icon",
                    onclick = "togglePassword()"
                  )
              ),
              
              actionButton("login", "Log in", class = "login-btn"),
              div(class = "error-msg", login_error())
          )
      )
    
      
    } else if (page_state() == "welcome") {
      div(style = "display: flex; justify-content: center; align-items: center; min-height: 90vh;",
          div(class = "welcome-card",
              tags$img(src = "images/welcome.png", class = "welcome-img"),
              div(class = "welcome-title", "Hello there! "),
              div(class = "welcome-text",
                  "Ready to organize your student life? We're so excited to help you get started with Notify!"
              ),
              actionButton("get_started", "Get Started", class = "get-started")
          )
      )
      
    } else {
      dashboardUI(id = "dash")
    }
  })
  
  # ===================== LOGIN =====================
  observeEvent(input$login, {
    
    if (input$username == "" || input$password == "") {
      login_error("Please enter both username and password")
      return()
    }
    
    res <- dbGetQuery(
      pool,
      sprintf(
        "SELECT * FROM users WHERE username='%s' AND password='%s'",
        input$username, input$password
      )
    )
    
    if (nrow(res) == 1) {
      logged_user(res$username)
      page_state("welcome")
      login_error("")
    } else {
      login_error("Invalid username or password")
    }
  })
  
  
  # ===================== GET STARTED =====================
  observeEvent(input$get_started, {
    page_state("dashboard")
  })
  
  session$onSessionEnded(function() {
    poolClose(pool)
  })
}

shinyApp(ui, server)










