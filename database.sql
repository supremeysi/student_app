-- ========================================================
-- STUDENT APP DATABASE SCHEMA
-- ========================================================

-- 1. USERS TABLE (For Login)
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(100) NOT NULL
);

-- Insert default user 
INSERT IGNORE INTO users (username, password)
VALUES ('macy', 'macy123');


-- 2. NOTES TABLE (Active Notes)
CREATE TABLE IF NOT EXISTS notes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255),
    description TEXT,
    color VARCHAR(50),
    note_datetime DATETIME,
    priority VARCHAR(50),
    status VARCHAR(50)
);


-- 3. ARCHIVES TABLE (Stored Notes)
CREATE TABLE IF NOT EXISTS archives (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255),
    description TEXT,
    note_datetime DATETIME,
    priority VARCHAR(50),
    status VARCHAR(50),
    archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- 4. TRASH TABLE (Deleted Notes)
CREATE TABLE IF NOT EXISTS trash (
     id INT AUTO_INCREMENT PRIMARY KEY,
     title VARCHAR(255),
     description TEXT,
     note_datetime DATETIME,
     priority VARCHAR(50),
     status VARCHAR(50),
     deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========================================================
-- END OF SCHEMA
-- ========================================================