-- Wanderlust - MySQL Schema Initialization
-- Run once on a fresh RDS instance or local MySQL container.
-- The application (Sequelize sync) will also create these tables
-- automatically on first startup, so this script is provided for
-- explicit provisioning and documentation purposes.

CREATE DATABASE IF NOT EXISTS wanderlust
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE wanderlust;

CREATE TABLE IF NOT EXISTS users (
  id          INT          NOT NULL AUTO_INCREMENT,
  name        VARCHAR(255) NOT NULL,
  email       VARCHAR(255) NOT NULL,
  password    VARCHAR(255),
  avatar      VARCHAR(500),
  role        VARCHAR(50)  NOT NULL DEFAULT 'user',
  createdAt   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS posts (
  id             INT          NOT NULL AUTO_INCREMENT,
  authorName     VARCHAR(255) NOT NULL,
  title          VARCHAR(500) NOT NULL,
  imageLink      VARCHAR(500) NOT NULL,
  categories     JSON         NOT NULL,
  description    TEXT         NOT NULL,
  isFeaturedPost TINYINT(1)   NOT NULL DEFAULT 0,
  timeOfPost     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_posts_featured  (isFeaturedPost),
  INDEX idx_posts_timeOfPost (timeOfPost)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
