# Student App 
A task management application built using R Shiny and MySQL.

## Features:
- Task tracking (Pending, Started, Completed)
- Archive and Soft Delete (Trash) system
- Database integration for persistent storage
- Voice-to-text input (Speech Recognition)

## Setup Instructions:
1. **Database:** Run the provided `database.sql` script in your MySQL server to create the necessary tables.
2. **Environment:** Create a `.Renviron` file in the root directory and add your database credentials (DB_USER, DB_PASS, DB_HOST, DB_NAME).
3. **Run:** Open `app.R` in RStudio and click "Run App".