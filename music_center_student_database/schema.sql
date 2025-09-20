-- Music Center Student Registration Database Schema
-- Database: myapp
-- This script creates core tables for storing students, instruments, guardians, registrations, and lessons.

-- Ensure the correct database is selected
CREATE DATABASE IF NOT EXISTS myapp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE myapp;

-- Drop tables if needed (uncomment for idempotent rebuilds)
-- SET FOREIGN_KEY_CHECKS = 0;
-- DROP TABLE IF EXISTS lessons;
-- DROP TABLE IF EXISTS registrations;
-- DROP TABLE IF EXISTS student_guardians;
-- DROP TABLE IF EXISTS guardians;
-- DROP TABLE IF EXISTS students;
-- DROP TABLE IF EXISTS instruments;
-- SET FOREIGN_KEY_CHECKS = 1;

-- Instruments offered by the music center
CREATE TABLE IF NOT EXISTS instruments (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  family VARCHAR(100) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Students table
CREATE TABLE IF NOT EXISTS students (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  date_of_birth DATE NULL,
  age TINYINT UNSIGNED NULL, -- optional, for quick filtering; may be derived from DOB
  email VARCHAR(255) NULL,
  phone VARCHAR(30) NULL,
  address_line1 VARCHAR(255) NULL,
  address_line2 VARCHAR(255) NULL,
  city VARCHAR(100) NULL,
  state_province VARCHAR(100) NULL,
  postal_code VARCHAR(20) NULL,
  country VARCHAR(100) NULL,
  preferred_contact ENUM('email','phone','sms') DEFAULT 'email',
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_students_email UNIQUE KEY (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Guardians/Parents table (for minors)
CREATE TABLE IF NOT EXISTS guardians (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NULL,
  phone VARCHAR(30) NULL,
  relationship VARCHAR(50) NULL, -- e.g., Mother, Father, Guardian
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_guardians_email UNIQUE KEY (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Many-to-many between students and guardians
CREATE TABLE IF NOT EXISTS student_guardians (
  student_id INT UNSIGNED NOT NULL,
  guardian_id INT UNSIGNED NOT NULL,
  primary_contact BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (student_id, guardian_id),
  CONSTRAINT fk_student_guardians_student
    FOREIGN KEY (student_id) REFERENCES students(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_student_guardians_guardian
    FOREIGN KEY (guardian_id) REFERENCES guardians(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Registrations for students to specific instruments
CREATE TABLE IF NOT EXISTS registrations (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  student_id INT UNSIGNED NOT NULL,
  instrument_id INT UNSIGNED NOT NULL,
  skill_level ENUM('beginner','intermediate','advanced') DEFAULT 'beginner',
  registration_date DATE NOT NULL,
  status ENUM('active','inactive','waitlisted','completed','cancelled') DEFAULT 'active',
  preferred_days SET('Mon','Tue','Wed','Thu','Fri','Sat','Sun') NULL,
  preferred_time_slot VARCHAR(50) NULL, -- e.g., "15:00-16:00" or "evenings"
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_registrations_student
    FOREIGN KEY (student_id) REFERENCES students(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_registrations_instrument
    FOREIGN KEY (instrument_id) REFERENCES instruments(id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_registrations_student (student_id),
  INDEX idx_registrations_instrument (instrument_id),
  INDEX idx_registrations_status (status),
  INDEX idx_registrations_date (registration_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Optional table for scheduled lessons (future use)
CREATE TABLE IF NOT EXISTS lessons (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  registration_id INT UNSIGNED NOT NULL,
  scheduled_at DATETIME NOT NULL,
  duration_minutes SMALLINT UNSIGNED NOT NULL DEFAULT 60,
  room VARCHAR(50) NULL,
  instructor_name VARCHAR(150) NULL,
  status ENUM('scheduled','completed','cancelled','no_show') DEFAULT 'scheduled',
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_lessons_registration
    FOREIGN KEY (registration_id) REFERENCES registrations(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_lessons_registration (registration_id),
  INDEX idx_lessons_scheduled_at (scheduled_at),
  INDEX idx_lessons_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed common instruments (safe upsert)
INSERT INTO instruments (name, family)
VALUES 
  ('Piano', 'Keyboard'),
  ('Guitar', 'Strings'),
  ('Violin', 'Strings'),
  ('Cello', 'Strings'),
  ('Flute', 'Woodwind'),
  ('Clarinet', 'Woodwind'),
  ('Saxophone', 'Woodwind'),
  ('Trumpet', 'Brass'),
  ('Trombone', 'Brass'),
  ('Drums', 'Percussion'),
  ('Voice', 'Vocal')
ON DUPLICATE KEY UPDATE family = VALUES(family);

-- Helpful views
CREATE OR REPLACE VIEW v_student_registrations AS
SELECT
  r.id AS registration_id,
  s.id AS student_id,
  CONCAT(s.first_name, ' ', s.last_name) AS student_name,
  s.email AS student_email,
  s.phone AS student_phone,
  i.name AS instrument,
  r.skill_level,
  r.registration_date,
  r.status
FROM registrations r
JOIN students s ON s.id = r.student_id
JOIN instruments i ON i.id = r.instrument_id;

-- Example indexes for quick search
CREATE INDEX IF NOT EXISTS idx_students_last_first ON students (last_name, first_name);
CREATE INDEX IF NOT EXISTS idx_students_email ON students (email);

-- End of schema
