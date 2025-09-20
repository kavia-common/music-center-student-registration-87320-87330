-- Music Center Student Registration Database Schema
-- Database: myapp
-- This script creates core tables for storing students, courses, guardians, registrations, and lessons.

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
-- DROP TABLE IF EXISTS courses;
-- SET FOREIGN_KEY_CHECKS = 1;

-- Courses offered by the music center
CREATE TABLE IF NOT EXISTS courses (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name ENUM('Children Piano', 'Adult Piano', 'Others') NOT NULL,
  description TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Students table
CREATE TABLE IF NOT EXISTS students (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  student_name VARCHAR(200) NOT NULL,
  parent VARCHAR(200) NULL,
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

-- Registrations for students to specific courses
CREATE TABLE IF NOT EXISTS registrations (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  student_id INT UNSIGNED NOT NULL,
  course_id INT UNSIGNED NOT NULL,
  grade ENUM('1','2','3','4','5','6','7','8','9','10','11','12') NOT NULL,
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
  CONSTRAINT fk_registrations_course
    FOREIGN KEY (course_id) REFERENCES courses(id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_registrations_student (student_id),
  INDEX idx_registrations_course (course_id),
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

-- Seed available courses (safe upsert)
INSERT INTO courses (name, description)
VALUES 
  ('Children Piano', 'Piano lessons specially designed for children'),
  ('Adult Piano', 'Piano lessons for adults'),
  ('Others', 'Other music courses')
ON DUPLICATE KEY UPDATE description = VALUES(description);

-- Helpful views
CREATE OR REPLACE VIEW v_student_registrations AS
SELECT
  r.id AS registration_id,
  s.id AS student_id,
  s.student_name,
  s.parent,
  s.email AS student_email,
  s.phone AS student_phone,
  c.name AS course,
  r.grade,
  r.registration_date,
  r.status
FROM registrations r
JOIN students s ON s.id = r.student_id
JOIN courses c ON c.id = r.course_id;

-- Example indexes for quick search
CREATE INDEX IF NOT EXISTS idx_students_name ON students (student_name);
CREATE INDEX IF NOT EXISTS idx_students_email ON students (email);

-- End of schema
