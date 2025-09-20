-- This file mirrors schema.sql as individual one-line statements suitable for execution via:
-- mysql -u<user> -p<password> -h <host> -P <port> -e "<SQL>"

CREATE DATABASE IF NOT EXISTS myapp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE myapp;

CREATE TABLE IF NOT EXISTS instruments (id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100) NOT NULL UNIQUE, family VARCHAR(100) NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS students (id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY, first_name VARCHAR(100) NOT NULL, last_name VARCHAR(100) NOT NULL, date_of_birth DATE NULL, age TINYINT UNSIGNED NULL, email VARCHAR(255) NULL, phone VARCHAR(30) NULL, address_line1 VARCHAR(255) NULL, address_line2 VARCHAR(255) NULL, city VARCHAR(100) NULL, state_province VARCHAR(100) NULL, postal_code VARCHAR(20) NULL, country VARCHAR(100) NULL, preferred_contact ENUM('email','phone','sms') DEFAULT 'email', notes TEXT NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, CONSTRAINT uq_students_email UNIQUE KEY (email)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS guardians (id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY, first_name VARCHAR(100) NOT NULL, last_name VARCHAR(100) NOT NULL, email VARCHAR(255) NULL, phone VARCHAR(30) NULL, relationship VARCHAR(50) NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, CONSTRAINT uq_guardians_email UNIQUE KEY (email)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS student_guardians (student_id INT UNSIGNED NOT NULL, guardian_id INT UNSIGNED NOT NULL, primary_contact BOOLEAN NOT NULL DEFAULT FALSE, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY (student_id, guardian_id), CONSTRAINT fk_student_guardians_student FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE ON UPDATE CASCADE, CONSTRAINT fk_student_guardians_guardian FOREIGN KEY (guardian_id) REFERENCES guardians(id) ON DELETE CASCADE ON UPDATE CASCADE) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS registrations (id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY, student_id INT UNSIGNED NOT NULL, instrument_id INT UNSIGNED NOT NULL, skill_level ENUM('beginner','intermediate','advanced') DEFAULT 'beginner', registration_date DATE NOT NULL, status ENUM('active','inactive','waitlisted','completed','cancelled') DEFAULT 'active', preferred_days SET('Mon','Tue','Wed','Thu','Fri','Sat','Sun') NULL, preferred_time_slot VARCHAR(50) NULL, notes TEXT NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, CONSTRAINT fk_registrations_student FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE ON UPDATE CASCADE, CONSTRAINT fk_registrations_instrument FOREIGN KEY (instrument_id) REFERENCES instruments(id) ON DELETE RESTRICT ON UPDATE CASCADE, INDEX idx_registrations_student (student_id), INDEX idx_registrations_instrument (instrument_id), INDEX idx_registrations_status (status), INDEX idx_registrations_date (registration_date)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS lessons (id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY, registration_id INT UNSIGNED NOT NULL, scheduled_at DATETIME NOT NULL, duration_minutes SMALLINT UNSIGNED NOT NULL DEFAULT 60, room VARCHAR(50) NULL, instructor_name VARCHAR(150) NULL, status ENUM('scheduled','completed','cancelled','no_show') DEFAULT 'scheduled', notes TEXT NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, CONSTRAINT fk_lessons_registration FOREIGN KEY (registration_id) REFERENCES registrations(id) ON DELETE CASCADE ON UPDATE CASCADE, INDEX idx_lessons_registration (registration_id), INDEX idx_lessons_scheduled_at (scheduled_at), INDEX idx_lessons_status (status)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO instruments (name, family) VALUES ('Piano','Keyboard') ON DUPLICATE KEY UPDATE family=VALUES(family);
INSERT INTO instruments (name, family) VALUES ('Guitar','Strings') ON DUPLICATE KEY UPDATE family=VALUES(family);
INSERT INTO instruments (name, family) VALUES ('Violin','Strings') ON DUPLICATE KEY UPDATE family=VALUES(family);
INSERT INTO instruments (name, family) VALUES ('Cello','Strings') ON DUPLICATE KEY UPDATE family=VALUES(family);
INSERT INTO instruments (name, family) VALUES ('Flute','Woodwind') ON DUPLICATE KEY UPDATE family=VALUES(family);
INSERT INTO instruments (name, family) VALUES ('Clarinet','Woodwind') ON DUPLICATE KEY UPDATE family=VALUES(family);
INSERT INTO instruments (name, family) VALUES ('Saxophone','Woodwind') ON DUPLICATE KEY UPDATE family=VALUES(family);
INSERT INTO instruments (name, family) VALUES ('Trumpet','Brass') ON DUPLICATE KEY UPDATE family=VALUES(family);
INSERT INTO instruments (name, family) VALUES ('Trombone','Brass') ON DUPLICATE KEY UPDATE family=VALUES(family);
INSERT INTO instruments (name, family) VALUES ('Drums','Percussion') ON DUPLICATE KEY UPDATE family=VALUES(family);
INSERT INTO instruments (name, family) VALUES ('Voice','Vocal') ON DUPLICATE KEY UPDATE family=VALUES(family);

CREATE OR REPLACE VIEW v_student_registrations AS SELECT r.id AS registration_id, s.id AS student_id, CONCAT(s.first_name, ' ', s.last_name) AS student_name, s.email AS student_email, s.phone AS student_phone, i.name AS instrument, r.skill_level, r.registration_date, r.status FROM registrations r JOIN students s ON s.id = r.student_id JOIN instruments i ON i.id = r.instrument_id;

CREATE INDEX idx_students_last_first ON students (last_name, first_name);
CREATE INDEX idx_students_email ON students (email);
