-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Oct 02, 2026 at 07:48 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `gac-database`
--

-- --------------------------------------------------------

--
-- Table structure for table `branch_restrooms`
--

CREATE TABLE `branch_restrooms` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `branch` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `area_type` varchar(255) NOT NULL DEFAULT 'customer',
  `has_male` tinyint(1) NOT NULL DEFAULT 1,
  `has_female` tinyint(1) NOT NULL DEFAULT 1,
  `has_pwd` tinyint(1) NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `sort_order` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `branch_restrooms`
--

INSERT INTO `branch_restrooms` (`id`, `branch`, `name`, `area_type`, `has_male`, `has_female`, `has_pwd`, `is_active`, `sort_order`, `created_at`, `updated_at`) VALUES
(1, 'MITSUBISHI SUCAT', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(3, 'SUZUKI PASONG TAMO', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(4, 'SUZUKI PASONG TAMO', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(5, 'HONDA MAKATI', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(6, 'HONDA MAKATI', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(7, 'HYUNDAI MAKATI', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(8, 'HYUNDAI MAKATI', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(9, 'KIA OTIS', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(10, 'KIA OTIS', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(11, 'HONDA FAIRVIEW', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(12, 'HONDA FAIRVIEW', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(13, 'MITSUBISHI QUEZON AVENUE', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(14, 'MITSUBISHI QUEZON AVENUE', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(15, 'HONDA MARCOS HIGHWAY', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(16, 'HONDA MARCOS HIGHWAY', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(17, 'HONDA CAINTA', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(18, 'HONDA CAINTA', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(19, 'GEELY CAINTA', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(20, 'GEELY CAINTA', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(21, 'MITSUBISHI PASIG', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(22, 'MITSUBISHI PASIG', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(23, 'HONDA ALABANG', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(24, 'HONDA ALABANG', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(25, 'MG LAS PINAS', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(26, 'MG LAS PINAS', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(27, 'CHANGAN BACOOR (old Nissan)', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(28, 'CHANGAN BACOOR (old Nissan)', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(29, 'KIA DASMARINAS', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(30, 'KIA DASMARINAS', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(31, 'MG MARILAO', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(32, 'MG MARILAO', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(33, 'MG/GEELY ANGELES', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(34, 'MG/GEELY ANGELES', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(35, 'GEELY TARLAC', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(36, 'GEELY TARLAC', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(37, 'HONDA ISABELA', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(38, 'HONDA ISABELA', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(39, 'SUZUKI SANTA ROSA', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(40, 'SUZUKI SANTA ROSA', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(41, 'MITSUBISHI CALAMBA', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(42, 'MITSUBISHI CALAMBA', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(43, 'GEELY LIPA', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(44, 'GEELY LIPA', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(45, 'SUZUKI ALAMINOS', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(46, 'SUZUKI ALAMINOS', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(47, 'KIA SAN PABLO', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(48, 'KIA SAN PABLO', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(49, 'MG SAN PABLO', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(50, 'MG SAN PABLO', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(51, 'MITSUBISHI PILI', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(52, 'MITSUBISHI PILI', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(53, 'MITSUBISHI LEGAZPI', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(54, 'MITSUBISHI LEGAZPI', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(55, 'MITSUBISHI GREENHILLS', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(56, 'MITSUBISHI GREENHILLS', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(57, 'HONDA MANILA BAY', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(58, 'HONDA MANILA BAY', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(59, 'HYUNDAI MANDAUE', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(60, 'HYUNDAI MANDAUE', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(61, 'KIA / GEELY MANDAUE', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(62, 'KIA / GEELY MANDAUE', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(63, 'MERCEDES-BENZ MANDAUE', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(64, 'MERCEDES-BENZ MANDAUE', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(65, 'OMODA & JAECOO CEBU CITY', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(66, 'OMODA & JAECOO CEBU CITY', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(67, 'MITSUBISHI TALISAY', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(68, 'MITSUBISHI TALISAY', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(69, 'HONDA TALISAY', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(70, 'HONDA TALISAY', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(71, 'GEELY TALISAY', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(72, 'GEELY TALISAY', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(73, 'MITSUBISHI GORORDO', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(74, 'MITSUBISHI GORORDO', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(75, 'MG NRA', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(76, 'MG NRA', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(77, 'KIA NRA', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(78, 'KIA NRA', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(79, 'GEELY CEBU', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(80, 'GEELY CEBU', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(81, 'JETOUR TALISAY', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(82, 'JETOUR TALISAY', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(83, 'MERCEDES-BENZ BOHOL', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(84, 'MERCEDES-BENZ BOHOL', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(85, 'GEELY BACOLOD', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(86, 'GEELY BACOLOD', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(87, 'HONDA MANDAUE', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(88, 'HONDA MANDAUE', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(89, 'MITSUBISHI MATINA', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(90, 'MITSUBISHI MATINA', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(91, 'HYUNDAI BUHANGIN', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(92, 'HYUNDAI BUHANGIN', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(93, 'JAECO & OMODA LANANG', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(94, 'JAECO & OMODA LANANG', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(95, 'MITSUBISHI DIGOS', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(96, 'MITSUBISHI DIGOS', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(97, 'BRP KIDAPAWAN', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(98, 'BRP KIDAPAWAN', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(99, 'MITSUBISHI COTABATO CITY', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(100, 'MITSUBISHI COTABATO CITY', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(101, 'MITSUBISHI TAGUM', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(102, 'MITSUBISHI TAGUM', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(103, 'MITSUBISHI PANABO', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(104, 'MITSUBISHI PANABO', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(105, 'GEELY SAN FRANCISCO', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(106, 'GEELY SAN FRANCISCO', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(107, 'MITSUBISHI NEGROS', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(108, 'MITSUBISHI NEGROS', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(109, 'MITSUBISHI BACOLOD', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(110, 'MITSUBISHI BACOLOD', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(111, 'MITSUBISHI CAGAYAN DE ORO', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(112, 'MITSUBISHI CAGAYAN DE ORO', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(113, 'HONDA BUTUAN', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(114, 'HONDA BUTUAN', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(115, 'KIA VALENCIA', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(116, 'KIA VALENCIA', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(117, 'JAECO & OMODA ILIGIAN', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(118, 'JAECO & OMODA ILIGIAN', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(119, 'HONDA DIPOLOG', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(120, 'HONDA DIPOLOG', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(121, 'Makati', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(122, 'Makati', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(123, 'Pasong Tamo', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(124, 'Pasong Tamo', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(125, 'Otis', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(126, 'Otis', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(127, 'Fairview', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(128, 'Fairview', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(129, 'Quezon Avenue', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(130, 'Quezon Avenue', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(131, 'Marcos Highway', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(132, 'Marcos Highway', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(133, 'Cainta', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(134, 'Cainta', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(135, 'Pasig', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(136, 'Pasig', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(137, 'Sucat', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(138, 'Sucat', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(139, 'Alabang', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(140, 'Alabang', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(141, 'Las Pinas', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(142, 'Las Pinas', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(143, 'Bacoor (Old Nissan)', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(144, 'Bacoor (Old Nissan)', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(145, 'Dasmarinas', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(146, 'Dasmarinas', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(147, 'Marilao', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(148, 'Marilao', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(149, 'Angeles', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(150, 'Angeles', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(151, 'Tarlac', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(152, 'Tarlac', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(153, 'Isabela', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(154, 'Isabela', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(155, 'Santa Rosa', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(156, 'Santa Rosa', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(157, 'Calamba', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(158, 'Calamba', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(159, 'Lipa', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(160, 'Lipa', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(161, 'Alaminos', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(162, 'Alaminos', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(163, 'San Pablo', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(164, 'San Pablo', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(165, 'Pili', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(166, 'Pili', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(167, 'Legazpi', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(168, 'Legazpi', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(169, 'Greenhills', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(170, 'Greenhills', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(171, 'Manila Bay', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(172, 'Manila Bay', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(173, 'Mandaue', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(174, 'Mandaue', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(175, 'Cebu City', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(176, 'Cebu City', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(177, 'Talisay', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(178, 'Talisay', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(179, 'Gorordo', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(180, 'Gorordo', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(181, 'NRA', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(182, 'NRA', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(183, 'Cebu', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(184, 'Cebu', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(185, 'Bohol', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(186, 'Bohol', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(187, 'Bacolod', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(188, 'Bacolod', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(189, 'Matina', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(190, 'Matina', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(191, 'Buhangin', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(192, 'Buhangin', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(193, 'Lanang', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(194, 'Lanang', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(195, 'Digos', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(196, 'Digos', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(197, 'Kidapawan', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(198, 'Kidapawan', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(199, 'Cotabato City', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(200, 'Cotabato City', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(201, 'Tagum', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(202, 'Tagum', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(203, 'Panabo', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(204, 'Panabo', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(205, 'San Francisco', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(206, 'San Francisco', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(207, 'Negros', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(208, 'Negros', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(209, 'Cagayan de Oro', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(210, 'Cagayan de Oro', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(211, 'Butuan', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(212, 'Butuan', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(213, 'Valencia', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(214, 'Valencia', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(215, 'Iligian', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(216, 'Iligian', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(217, 'Dipolog', 'Customer Area Restroom', 'customer', 1, 1, 1, 1, 1, '2026-09-24 02:46:56', '2026-09-24 02:46:56'),
(218, 'Dipolog', 'Office Restroom', 'office', 1, 1, 0, 1, 2, '2026-09-24 02:46:56', '2026-09-24 02:46:56');

-- --------------------------------------------------------

--
-- Table structure for table `cache`
--

CREATE TABLE `cache` (
  `key` varchar(255) NOT NULL,
  `value` mediumtext NOT NULL,
  `expiration` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `cache`
--

INSERT INTO `cache` (`key`, `value`, `expiration`) VALUES
('laravel-cache-6cb5bb9b67d5af5e7f80c02dc185aac943ccb0d3', 'i:2;', 1790571961),
('laravel-cache-6cb5bb9b67d5af5e7f80c02dc185aac943ccb0d3:timer', 'i:1790571961;', 1790571961);

-- --------------------------------------------------------

--
-- Table structure for table `cache_locks`
--

CREATE TABLE `cache_locks` (
  `key` varchar(255) NOT NULL,
  `owner` varchar(255) NOT NULL,
  `expiration` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `checklist_items`
--

CREATE TABLE `checklist_items` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `checklist_template_id` bigint(20) UNSIGNED NOT NULL,
  `checklist_section_id` bigint(20) UNSIGNED NOT NULL,
  `key` varchar(100) NOT NULL,
  `prompt` text NOT NULL,
  `sort_order` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `checklist_items`
--

INSERT INTO `checklist_items` (`id`, `checklist_template_id`, `checklist_section_id`, `key`, `prompt`, `sort_order`, `metadata`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'item-1', 'Is the parking area clearly visible and easy for customers to find, with well-defined parking lines and proper signage?', 0, '{\"number\":1}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(2, 1, 1, 'item-2', 'Is the parking area clean, free from dirt and debris, and well maintained?', 1, '{\"number\":2}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(3, 1, 2, 'item-3', 'Is the area clean and well-organized, with no unnecessary items on the floor?', 0, '{\"number\":3}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(4, 1, 2, 'item-4', 'Are there no broken or damaged tiles?', 1, '{\"number\":4}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(5, 1, 2, 'item-5', 'Are all the lights in the showroom functioning properly?', 2, '{\"number\":5}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(6, 1, 2, 'item-6', 'Are the sales materials (posters, banners, and illuminated signage) current, well-maintained, clean, and properly organized?', 3, '{\"number\":6}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(7, 1, 2, 'item-7', 'Are the windows clean and free from fingerprints, watermarks, tape, or any other marks?', 4, '{\"number\":7}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(8, 1, 2, 'item-8', 'Are the ceilings and walls free from dirt, damage, and water leakage?', 5, '{\"number\":8}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(9, 1, 2, 'item-9', 'Are the sales negotiation tables and chairs clean and properly sanitized?', 6, '{\"number\":9}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(10, 1, 2, 'item-10', 'Is free Wi-Fi available and easily accessible to customers?', 7, '{\"number\":10}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(11, 1, 2, 'item-11', 'Is the ventilation and A/C system adequate and fully operational?', 8, '{\"number\":11}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(12, 1, 3, 'item-12', 'Is the reception area kept neat and tidy, with the surroundings free from dirt, waste, and visible personal belongings?', 0, '{\"number\":12}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(13, 1, 3, 'item-13', 'Are the reception counter and chairs clean and free from damage?', 1, '{\"number\":13}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(14, 1, 4, 'item-14', 'Is the vehicle display area clean, free from dirt and waste, and properly sanitized?', 0, '{\"number\":14}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(15, 1, 4, 'item-15', 'Is at least one unit of each MG model displayed in the showroom, including the latest model year and a mix of high-end variants?', 1, '{\"number\":15}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(16, 1, 4, 'item-16', 'Is an information stand available near each display unit?', 2, '{\"number\":16}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(17, 1, 4, 'item-17', 'Are the displayed vehicles clean and free of protective coverings?', 3, '{\"number\":17}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(18, 1, 4, 'item-18', 'Are the engine compartments clean?', 4, '{\"number\":18}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(19, 1, 4, 'item-19', 'Are the display units unlocked?', 5, '{\"number\":19}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(20, 1, 4, 'item-20', 'Are genuine floor mats installed, with no paper mats in use?', 6, '{\"number\":20}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(21, 1, 4, 'item-21', 'Is the battery charged or connected to a floor power supply, with all electrical equipment functioning properly?', 7, '{\"number\":21}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(22, 1, 4, 'item-22', 'Are the vehicle interiors clean?', 8, '{\"number\":22}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(23, 1, 4, 'item-23', 'Is sufficient space maintained between the vehicles?', 9, '{\"number\":23}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(24, 1, 4, 'item-24', 'Are the test-drive units available, organized, and properly sanitized?', 10, '{\"number\":24}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(25, 1, 5, 'item-25', 'Is the area clean and well-organized, with no unnecessary items on the floor?', 0, '{\"number\":25}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(26, 1, 5, 'item-26', 'Are there no broken or damaged tiles?', 1, '{\"number\":26}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(27, 1, 5, 'item-27', 'Are all the lights in the service reception area functioning properly?', 2, '{\"number\":27}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(28, 1, 5, 'item-28', 'Are the windows clean and free from fingerprints, watermarks, tape, or any other marks?', 3, '{\"number\":28}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(29, 1, 5, 'item-29', 'Are the ceilings and walls free from dirt, damage, and water leakage?', 4, '{\"number\":29}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(30, 1, 5, 'item-30', 'Are the service reception tables and chairs clean and properly sanitized?', 5, '{\"number\":30}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(31, 1, 5, 'item-31', 'Is free Wi-Fi available and easily accessible to customers?', 6, '{\"number\":31}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(32, 1, 5, 'item-32', 'Is the ventilation and A/C system adequate and fully operational?', 7, '{\"number\":32}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(33, 1, 6, 'item-33', 'Is the working bay clean, free from dirt and waste, and properly sanitized?', 0, '{\"number\":33}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(34, 1, 6, 'item-34', 'Are all trolleys stored within the painted work bay when not in use, with no unnecessary items such as drinking bottles or shoes left behind?', 1, '{\"number\":34}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(35, 1, 6, 'item-35', 'Are there no used parts or empty plastic containers left in the work bay?', 2, '{\"number\":35}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(36, 1, 6, 'item-36', 'Are the lifters clean and returned to their normal down position when not in use and at the end of working hours?', 3, '{\"number\":36}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(37, 1, 6, 'item-37', 'Are the vehicle windows closed at all times, except when repairs are in progress?', 4, '{\"number\":37}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(38, 1, 6, 'item-38', 'Are the tools organized, complete, and placed in their proper locations?', 5, '{\"number\":38}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(39, 1, 6, 'item-39', 'Are the service reception counter and chairs clean and free from damage?', 6, '{\"number\":39}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(40, 1, 7, 'item-40', 'Are the necessary supplies, such as paper products, soap, and hand-drying facilities, available?', 0, '{\"number\":40}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(41, 1, 7, 'item-41', 'Is the restroom free from dirt and waste, including the floor, walls, and tiles?', 1, '{\"number\":41}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(42, 1, 7, 'item-42', 'Are the sinks and faucets in proper working condition?', 2, '{\"number\":42}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(43, 1, 7, 'item-43', 'Are the toilet bowls and urinals in proper working condition?', 3, '{\"number\":43}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(44, 1, 7, 'item-44', 'Is the female restroom clean and sanitized, with no water splashes around the sink or unnecessary items on the floor?', 4, '{\"number\":44}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(45, 1, 7, 'item-45', 'Is the male restroom clean and sanitized, with no water splashes around the sink or unnecessary items on the floor?', 5, '{\"number\":45}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(46, 1, 7, 'item-46', 'Is the PWD restroom clean and sanitized, with no water splashes around the sink or unnecessary items on the floor?', 6, '{\"number\":46}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(47, 1, 7, 'item-47', 'Is the restroom checklist updated?', 7, '{\"number\":47}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(48, 1, 8, 'item-48', 'Are complimentary snacks, such as biscuits, available?', 0, '{\"number\":48}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(49, 1, 8, 'item-49', 'Are complimentary refreshments, including coffee and water, available?', 1, '{\"number\":49}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(50, 1, 8, 'item-50', 'Are the seats and sofas comfortable, undamaged, and properly sanitized?', 2, '{\"number\":50}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(51, 1, 8, 'item-51', 'Is the LED television in working condition and well maintained?', 3, '{\"number\":51}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(52, 1, 8, 'item-52', 'Is the ventilation and A/C system adequate and fully operational?', 4, '{\"number\":52}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(53, 1, 8, 'item-53', 'Is free Wi-Fi available and easily accessible to customers?', 5, '{\"number\":53}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(54, 1, 9, 'item-54', 'Are the sales executives wearing the prescribed uniform and ID badge?', 0, '{\"number\":54}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(55, 1, 9, 'item-55', 'Are the sales executives well-groomed and dressed in the proper uniform?', 1, '{\"number\":55}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(56, 1, 9, 'item-56', 'Do the sales executives have the complete Sales Kit, including the price list, business cards, and bank application form?', 2, '{\"number\":56}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(143, 4, 26, 'item-1', 'Is the parking area clearly visible and easy for customers to find parking, with well-defined parking lines and proper signage?', 0, '{\"number\":1}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(144, 4, 26, 'item-2', 'Is the parking area clean and free from dirt and Dirt? (well maintained)?', 1, '{\"number\":2}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(145, 4, 27, 'item-3', 'Is the area clean and well-organized, with no unnecessary items on the floor?', 0, '{\"number\":3}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(146, 4, 27, 'item-4', 'Are there no broken or damaged tiles?', 1, '{\"number\":4}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(147, 4, 27, 'item-5', 'Are all the lights in the showroom functioning properly', 2, '{\"number\":5}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(148, 4, 27, 'item-6', 'Are the sales materials (posters, banners, and illuminated signage) current, well-maintained, clean, and properly organized?', 3, '{\"number\":6}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(149, 4, 27, 'item-7', 'Are the windows clean, free from fingerprints, watermarks, tape, or any other marks?', 4, '{\"number\":7}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(150, 4, 27, 'item-8', 'Are the ceilings and walls free of dirt, damage and water leakage?', 5, '{\"number\":8}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(151, 4, 27, 'item-9', 'Are the sales negotiation tables and chairs clean and properly sanitized?', 6, '{\"number\":9}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(152, 4, 27, 'item-10', 'Is free Wi-Fi available and easily accessible to customers?', 7, '{\"number\":10}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(153, 4, 27, 'item-11', 'Is the ventilation and A/C system adequate and fully operational?', 8, '{\"number\":11}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(154, 4, 28, 'item-12', 'Reception area is kept neat and tidy. Surrounding area are kept free of dirt and waste. No personal belongings shown.', 0, '{\"number\":12}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(155, 4, 28, 'item-13', 'The reception counter and chairs are clean and free from damage.', 1, '{\"number\":13}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(156, 4, 106, 'item-14', 'Test drive vehicle are maintained clean.', 0, '{\"number\":14}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(157, 4, 106, 'item-15', 'Test drive vehicle are fully functional and complies with regular PMS.', 1, '{\"number\":15}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(158, 4, 106, 'item-16', 'Test drive vehicle are free from damage', 2, '{\"number\":16}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(159, 4, 29, 'item-17', 'Is the car display area clean, free of dirt and waste, and properly sanitized?', 0, '{\"number\":17}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(160, 4, 29, 'item-18', 'Is at least one unit of each MG model displayed in the showroom, and does it include the latest model year with a mix of high-end variants?', 1, '{\"number\":18}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(161, 4, 29, 'item-19', 'Is there an information stand available near each display unit?', 2, '{\"number\":19}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(162, 4, 29, 'item-20', 'Are the displayed cars kept clean and free of protective coverings?', 3, '{\"number\":20}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(163, 4, 29, 'item-21', 'Are the engine compartments clean?', 4, '{\"number\":21}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(164, 4, 29, 'item-22', 'Are the display units unlocked?', 5, '{\"number\":22}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(165, 4, 29, 'item-23', 'Are genuine floor mats installed? And no paper mat is installed?', 6, '{\"number\":23}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(166, 4, 29, 'item-24', 'Is the battery charged, or is there a power supply from the floor, with all electric equipment functioning properly?', 7, '{\"number\":24}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(167, 4, 29, 'item-25', 'Are the vehicle interiors clean?', 8, '{\"number\":25}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(168, 4, 29, 'item-26', 'Is there enough space secured between the vehicles?', 9, '{\"number\":26}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(169, 4, 29, 'item-27', 'Are the test drive units available, organized, and properly sanitized?', 10, '{\"number\":27}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(170, 4, 30, 'item-28', 'Are the necessary items (e.g., papers, soap, hand dryers) available?', 0, '{\"number\":28}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(171, 4, 30, 'item-29', 'Is the restroom free from dirt and waste, including the floor, walls, and tiles?', 1, '{\"number\":29}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(172, 4, 30, 'item-30', 'Are the sinks and faucets in proper working condition?', 2, '{\"number\":30}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(173, 4, 30, 'item-31', 'Are the toilet bowls and urinals in proper working condition?', 3, '{\"number\":31}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(174, 4, 30, 'item-32', 'Is the Female restroom clean and sanitized, with no water splashes around the sink or unnecessary items on the floor?', 4, '{\"number\":32}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(175, 4, 30, 'item-33', 'Is the Male restroom clean and sanitized, with no water splashes around the sink or unnecessary items on the floor?', 5, '{\"number\":33}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(176, 4, 30, 'item-34', 'Is the PWD restroom clean and sanitized, with no water splashes around the sink or unnecessary items on the floor?', 6, '{\"number\":34}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(177, 4, 30, 'item-35', 'Is the restroom checklist updated?', 7, '{\"number\":35}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(178, 4, 31, 'item-36', 'Are there free snacks available? ( Biscuits, etc.)', 0, '{\"number\":36}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(179, 4, 31, 'item-37', 'Are there available free refreshments (Coffee and Water)?', 1, '{\"number\":37}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(180, 4, 31, 'item-38', 'Are the seats/sofas comfortable, undamaged, and properly sanitized?', 2, '{\"number\":38}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(181, 4, 31, 'item-39', 'Is the LED television in working condition and well-maintained?', 3, '{\"number\":39}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(182, 4, 31, 'item-40', 'Is the ventilation and A/C system adequate and fully operational?', 4, '{\"number\":40}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(183, 4, 31, 'item-41', 'Is  free Wi-Fi available and easily accessible to customers?', 5, '{\"number\":41}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(184, 5, 33, 'item-1', 'Is the service parking area clearly visible and easy for customers to find parking, with well-defined parking lines and proper signage?', 0, '{\"number\":1}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(185, 5, 33, 'item-2', 'Is the parking area clean and free from dirt and Dirt? (well maintained)?', 1, '{\"number\":2}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(186, 5, 34, 'item-3', 'Is the area clean and well-organized, with no unnecessary items on the floor?', 0, '{\"number\":3}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(187, 5, 34, 'item-4', 'Are there no broken or damaged tiles?', 1, '{\"number\":4}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(188, 5, 34, 'item-5', 'Are all the lights in the showroom functioning properly', 2, '{\"number\":5}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(189, 5, 34, 'item-6', 'Are the windows clean, free from fingerprints, watermarks, tape, or any other marks?', 3, '{\"number\":6}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(190, 5, 34, 'item-7', 'Are the ceilings and walls free of dirt, damage and water leakage?', 4, '{\"number\":7}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(191, 5, 34, 'item-8', 'Are the service reception tables and chairs clean and properly sanitized?', 5, '{\"number\":8}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(192, 5, 34, 'item-9', 'Is free Wi-Fi available and easily accessible to customers?', 6, '{\"number\":9}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(193, 5, 34, 'item-10', 'Is the ventilation and A/C system adequate and fully operational?', 7, '{\"number\":10}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(194, 5, 34, 'item-11', 'The reception counter and chairs are clean and free from damage.', 8, '{\"number\":11}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(195, 5, 35, 'item-12', 'Is the working bay clean, free of dirt and waste, and properly sanitized?', 0, '{\"number\":12}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(196, 5, 35, 'item-13', 'Are all trolleys stored within the painted work bay when not in use, with no unnecessary items such as drinking bottles, shoes, etc., left behind?', 1, '{\"number\":13}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(197, 5, 35, 'item-14', 'Are there no used parts or empty plastic containers left in the work bay?', 2, '{\"number\":14}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(198, 5, 35, 'item-15', 'Are the lifters clean and returned to their normal (down) position when not in use and at the end of working hours?', 3, '{\"number\":15}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(199, 5, 35, 'item-16', 'Are the vehicle windows closed at all times, except when repairs are in progress?', 4, '{\"number\":16}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(200, 5, 35, 'item-17', 'Are the tools organized, complete, and placed in their proper locations?', 5, '{\"number\":17}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(201, 5, 36, 'item-18', 'Are the necessary items (e.g., papers, soap, hand dryers) available?', 0, '{\"number\":18}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(202, 5, 36, 'item-19', 'Is the restroom free from dirt and waste, including the floor, walls, and tiles?', 1, '{\"number\":19}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(203, 5, 36, 'item-20', 'Are the sinks and faucets in proper working condition?', 2, '{\"number\":20}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(204, 5, 36, 'item-21', 'Are the toilet bowls and urinals in proper working condition?', 3, '{\"number\":21}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(205, 5, 36, 'item-22', 'Is the Female restroom clean and sanitized, with no water splashes around the sink or unnecessary items on the floor?', 4, '{\"number\":22}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(206, 5, 36, 'item-23', 'Is the Male restroom clean and sanitized, with no water splashes around the sink or unnecessary items on the floor?', 5, '{\"number\":23}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(207, 5, 36, 'item-24', 'Is the PWD restroom clean and sanitized, with no water splashes around the sink or unnecessary items on the floor?', 6, '{\"number\":24}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(208, 5, 36, 'item-25', 'Is the restroom checklist updated?', 7, '{\"number\":25}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(209, 5, 37, 'item-26', 'Are there free snacks available? ( Biscuits, etc.)', 0, '{\"number\":26}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(210, 5, 37, 'item-27', 'Are there available free refreshments (Coffee and Water)?', 1, '{\"number\":27}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(211, 5, 37, 'item-28', 'Are the seats/sofas comfortable, undamaged, and properly sanitized?', 2, '{\"number\":28}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(212, 5, 37, 'item-29', 'Is the LED television in working condition and well-maintained?', 3, '{\"number\":29}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(213, 5, 37, 'item-30', 'Is the ventilation and A/C system adequate and fully operational?', 4, '{\"number\":30}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(214, 5, 37, 'item-31', 'Is  free Wi-Fi available and easily accessible to customers?', 5, '{\"number\":31}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(215, 5, 38, 'item-32', 'Are they wearing the prescribed uniform and ID badge?', 0, '{\"number\":32}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(216, 5, 38, 'item-33', 'Are they well-groomed and dressed in the proper uniform?', 1, '{\"number\":33}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(307, 6, 83, 'dos-1', 'Fascia or badge sign and letterings are complete, undamaged, clean, no watermarks, no obstructions, no discoloration and stains', 0, '{\"number\":1,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Facade\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"property_management\",\"how_to_check\":\"1. Check through observation if it meets the MMPC VI Standard Requirements\",\"code\":\"1\",\"label\":\"Facade\",\"description\":\"Fascia or badge sign and letterings are complete, undamaged, clean, no watermarks, no obstructions, no discoloration and stains\",\"responsible_role\":\"GM\"}', 1, '2026-09-05 08:08:23', '2026-09-12 01:12:23'),
(308, 6, 83, 'dos-2', 'Pylon (Single/Two-Post / Tower / Wall Projecting) sign/s and letterings are complete, undamaged, clean, no watermarks, no obstructions, no discoloration and stains', 1, '{\"number\":2,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Facade\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"property_management\",\"how_to_check\":\"1. Check through observation if it meets the MMPC VI Standard Requirements\",\"code\":\"2\",\"label\":\"Facade\",\"description\":\"Pylon (Single\\/Two-Post \\/ Tower \\/ Wall Projecting) sign\\/s and letterings are complete, undamaged, clean, no watermarks, no obstructions, no discoloration and stains\",\"responsible_role\":\"GM\"}', 1, '2026-09-05 08:08:23', '2026-09-12 01:07:11'),
(309, 6, 83, 'dos-3', 'All exterior Visual Identity including building walls, exterior paint and finishes, are clean and free from damage.', 2, '{\"number\":3,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Facade\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"property_management\",\"how_to_check\":\"1. Check through observation if it meets the MMPC VI Standard Requirements\",\"code\":\"3\",\"label\":\"Facade\",\"description\":\"All exterior Visual Identity including building walls, exterior paint and finishes, are clean and free from damage.\",\"responsible_role\":\"GM\"}', 1, '2026-09-05 08:08:23', '2026-09-12 01:07:11'),
(310, 6, 83, 'dos-4', 'Showroom glass is clean, free from cracks, scratches, damage, dust, stains and water marks', 3, '{\"number\":4,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Facade\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"property_management\",\"how_to_check\":\"1. Check through observation if compliant\",\"code\":\"4\",\"label\":\"Facade\",\"description\":\"Showroom glass is clean, free from cracks, scratches, damage, dust, stains and water marks\",\"responsible_role\":\"GM\"}', 1, '2026-09-05 08:08:23', '2026-09-12 01:07:11'),
(311, 6, 83, 'dos-5', '\"Customer Parking\" signs are available, undamaged and well maintained', 4, '{\"number\":5,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Facade\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"property_management\",\"how_to_check\":\"1. Check through observation if it meets the MMPC VI Standard Requirements\",\"code\":\"5\",\"label\":\"Facade\",\"description\":\"\\\"Customer Parking\\\" signs are available, undamaged and well maintained\",\"responsible_role\":\"GM\"}', 1, '2026-09-05 08:08:23', '2026-09-12 01:07:11'),
(312, 6, 83, 'dos-6', 'No new units \"stock\" parked in customer parking area.', 5, '{\"number\":6,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Facade\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":null,\"escalation\":null,\"how_to_check\":\"1. Check through observation if compliant\",\"code\":\"6\",\"label\":\"Facade\",\"description\":\"No new units \\\"stock\\\" parked in customer parking area.\",\"responsible_role\":\"GM\"}', 1, '2026-09-05 08:08:23', '2026-09-12 01:07:11'),
(313, 6, 83, 'dos-7', 'PWD parking slot and ramp with railings should be unobstructed and painted with standard PWD Logo.', 6, '{\"number\":7,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Facade\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"property_management\",\"how_to_check\":\"1. Check through observation if compliant\",\"code\":\"7\",\"label\":\"Facade\",\"description\":\"PWD parking slot and ramp with railings should be unobstructed and painted with standard PWD Logo.\",\"responsible_role\":\"GM\"}', 1, '2026-09-05 08:08:23', '2026-09-12 01:07:11'),
(314, 6, 83, 'dos-13', 'Reception Desk is installed in the entrance following the VI Standards; desk is clean, organized, and free of unecessary items; accent wall remains free of any designs', 7, '{\"number\":8,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check if it meets the MMPC VI Standard Requirements\\n2. Check if there are no designs on the accent wall\\n3. Check if the reception desk is clean, organized, and free of unnecessary items (5S)\",\"code\":\"8\",\"label\":\"Showroom Area\",\"description\":\"Reception Desk is installed in the entrance following the VI Standards; desk is clean, organized, and free of unecessary items; accent wall remains free of any designs\",\"responsible_role\":\"GM\"}', 1, '2026-09-05 08:08:23', '2026-09-12 01:07:11'),
(315, 6, 83, 'dos-14', 'No duplicate vehicle model variants were displayed', 8, '{\"number\":9,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check if all displayed units have no duplicate vehicle model variants\\n\\nNote: Check the unit inventory (if necessary)\",\"code\":\"9\",\"label\":\"Showroom Area\",\"description\":\"No duplicate vehicle model variants were displayed\",\"responsible_role\":\"GM\"}', 1, '2026-09-05 08:08:23', '2026-09-12 01:07:11'),
(316, 6, 83, 'dos-15', 'Display units are clean and in good condition (no dents, scratches, fingerprints, etc.)', 9, '{\"number\":10,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check if the display units are compliant\",\"code\":\"10\",\"label\":\"Showroom Area\",\"description\":\"Display units are clean and in good condition (no dents, scratches, fingerprints, etc.)\",\"responsible_role\":\"GM\"}', 1, '2026-09-05 08:08:23', '2026-09-12 01:07:11'),
(317, 6, 83, 'dos-16', 'All displayed cars have their corresponding and updated specs stands.', 10, '{\"number\":11,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check if all displayed units have corresponding specs stands\\n2. Check if the specs sheet is updated and matches the displayed unit\",\"code\":\"11\",\"label\":\"Showroom Area\",\"description\":\"All displayed cars have their corresponding and updated specs stands.\",\"responsible_role\":\"GM\"}', 1, '2026-09-05 08:08:23', '2026-09-12 01:07:11'),
(318, 6, 83, 'dos-23', 'Showroom Tiles or tiles has no damages', 15, '{\"number\":16,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"property_management\",\"how_to_check\":\"1. Check if there are no broken or damaged tiles on the showroom floor\",\"code\":\"16\",\"label\":\"Showroom Area\",\"description\":\"Showroom Tiles or tiles has no damages\",\"responsible_role\":\"GM\"}', 1, '2026-09-05 08:08:23', '2026-09-12 01:07:11'),
(319, 6, 83, 'dos-24', 'Ceiling of showroom should be cob web free; no discoloration and stains', 16, '{\"number\":17,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"property_management\",\"how_to_check\":\"1. Check if the showroom ceiling is clean and free from cob web, no discolorations and stains\",\"code\":\"17\",\"label\":\"Showroom Area\",\"description\":\"Ceiling of showroom should be cob web free; no discoloration and stains\",\"responsible_role\":\"GM\"}', 1, '2026-09-05 08:08:23', '2026-09-12 01:07:11'),
(320, 6, 83, 'dos-25', 'No busted lights in the Showroom Area and Customer Lounge', 17, '{\"number\":18,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"property_management\",\"how_to_check\":\"1. Check if there are no busted lights in the showroom\",\"code\":\"18\",\"label\":\"Showroom Area\",\"description\":\"No busted lights in the Showroom Area and Customer Lounge\",\"responsible_role\":\"GM\"}', 1, '2026-09-05 08:08:23', '2026-09-12 01:07:11'),
(321, 6, 83, 'dos-26', 'Directional signs to Sales, Service, and Parts follow MMPC VI standards, undamaged and visible.', 18, '{\"number\":19,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"property_management\",\"how_to_check\":\"1. Check if the directional signages are compliant\",\"code\":\"19\",\"label\":\"Showroom Area\",\"description\":\"Directional signs to Sales, Service, and Parts follow MMPC VI standards, undamaged and visible.\",\"responsible_role\":\"GM\"}', 1, '2026-09-05 08:08:23', '2026-09-12 01:07:11'),
(322, 6, 83, 'dos-27', 'All showroom lighted signages, banners and tarpaulins are up to date and in good condition and no damages', 19, '{\"number\":20,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"MARKETING\\nPM\",\"how_to_check\":\"1. Check if the displays are within the current lineup only, no FUSO, Adventure, or any old model and no damages\",\"code\":\"20\",\"label\":\"Showroom Area\",\"description\":\"All showroom lighted signages, banners and tarpaulins are up to date and in good condition and no damages\",\"responsible_role\":\"GM\"}', 1, '2026-09-05 08:08:23', '2026-09-12 01:07:11'),
(323, 6, 83, 'dos-28', 'All installed A/C systems in the showroom and sales lounge are functioning properly', 20, '{\"number\":21,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"property_management\",\"how_to_check\":\"1. Check all A\\/C systems if they are properly functioning\\n2. Check the thermometer in the following areas and ensure the thermostat does not exceed 27\\u00b0C:\\n-Showroom\\/Negotiation Area\\n-Showroom lounge\",\"code\":\"21\",\"label\":\"Showroom Area\",\"description\":\"All installed A\\/C systems in the showroom and sales lounge are functioning properly\",\"responsible_role\":\"GM\"}', 1, '2026-09-05 08:08:23', '2026-09-12 01:07:11'),
(324, 6, 83, 'dos-29', 'The sofas/chairs in the customer lounge and the negotiation area are in good condition, sufficient, organized, clean, and comply with MMPC VI Standard Requirements', 21, '{\"number\":22,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> GM to submit request to purchasing\\n> BOM to monitor progress until compliant.\",\"escalation\":\"PURCHASING\",\"how_to_check\":\"1. Check if the customer lounge and negotiation area have enough sofas\\/chairs that are comfortable, well-maintained, free from tears, and meet the MMPC VI Standard Requirements\\n2. Check if the dealer is not using monobloc chairs in the showroom area\",\"code\":\"22\",\"label\":\"Showroom Area\",\"description\":\"The sofas\\/chairs in the customer lounge and the negotiation area are in good condition, sufficient, organized, clean, and comply with MMPC VI Standard Requirements\",\"responsible_role\":\"GM\"}', 1, '2026-09-05 08:08:23', '2026-09-12 01:07:11'),
(325, 6, 83, 'dos-34', 'Rest Rooms must have clean water supply, toilet bowl, sink, urinal, bidet, trash cans, tissue, paper towel or hand dryer, and hand wash soap; no foul smell', 22, '{\"number\":23,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> Remind utility personnel of daily 5S task.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check all restrooms designated for customers (Male, Female, PWD)\\n2. Check if the restrooms are well-lit\",\"code\":\"23\",\"label\":\"Showroom Area\",\"description\":\"Rest Rooms must have clean water supply, toilet bowl, sink, urinal, bidet, trash cans, tissue, paper towel or hand dryer, and hand wash soap; no foul smell\",\"responsible_role\":\"GM\"}', 1, '2026-09-05 08:08:23', '2026-09-12 01:07:11'),
(326, 6, 84, 'dos-8', 'Test drive vehicle are maintained clean, fully functional and is readily available for use.', 0, '{\"number\":24,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Product Presentation and Test Drive\",\"subject\":\"Test Drive\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> SM to advise BOM of any damage\\n> BOM prepare request for PMS or damage repair and send to Inventory\\n> BOM must maintain aTest drive monitoring file record which includes, km reading, PMS and damage record. \\n> PMS interval will be based on prescribed km reading or prescribed months whichever comes first.\",\"escalation\":\"INVENTORY\",\"how_to_check\":\"1. Check if the designated test drive units is compliant\",\"code\":\"24\",\"label\":\"Test Drive\",\"description\":\"Test drive vehicle are maintained clean, fully functional and is readily available for use.\",\"responsible_role\":\"GM\"}', 1, '2026-09-05 08:08:23', '2026-09-12 01:07:11'),
(327, 6, 84, 'dos-9', '> Test drive parking area with a roof (tent) should be installed in front of the showroom\n> Test drive advertisement with Dealer\'s contact number visibly displayed at the dealership', 1, '{\"number\":25,\"level\":\"Beyond\",\"category\":\"Beyond\",\"coverage\":\"Product Presentation and Test Drive\",\"subject\":\"Test Drive\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> prepare request for tent design standards from marketing\\n> submit purchase request with design to Purchasing\",\"escalation\":\"MARKETING \\/ PURCHASING\",\"how_to_check\":\"1. Check through observation if the testdrive advertisement and dealership contact details are updated\",\"code\":\"25\",\"label\":\"Test Drive\",\"description\":\"> Test drive parking area with a roof (tent) should be installed in front of the showroom\\n> Test drive advertisement with Dealer\'s contact number visibly displayed at the dealership\",\"responsible_role\":\"GM\"}', 1, '2026-09-05 08:08:23', '2026-09-12 01:07:11'),
(328, 6, 84, 'dos-10', 'Test drive route map is available', 2, '{\"number\":26,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Product Presentation and Test Drive\",\"subject\":\"Test Drive\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check if route map is available\\n> advise GM if no route map is available.\\n> follow up until compliant.\",\"escalation\":\"MARKETING\",\"how_to_check\":\"1. Check if the testdrive route map is available at the showroom area\\n2. Check if there are 2 - 3 test drive route map available\",\"code\":\"26\",\"label\":\"Test Drive\",\"description\":\"Test drive route map is available\",\"responsible_role\":\"GM\"}', 1, '2026-09-05 08:08:23', '2026-09-12 01:07:11'),
(329, 2, 60, 'dos-as-1', 'Check accuracy of manpower list from latest submission to Network Training Department (NTD).', 1, '{\"number\":1,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Manpower\",\"subject\":\"Manpower Count\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check if latest submitted file of manpower list is accurate with actual manpower allocation.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(330, 2, 60, 'dos-as-2', 'Dealer has at least 1 designated Aftersales Training person in charge.', 2, '{\"number\":2,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Manpower\",\"subject\":\"Training Requirements\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS HEAD\",\"how_to_check\":\"Verify if dealer have assigned 1 Aftersales Training PIC as aligned with MMPC NTD Database.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(331, 2, 60, 'dos-as-3', 'All Customer Relations Department personnel are accredited following these timelines:\n*Level 1: within 30 days upon hiring\n*Level 2: within 3-6 months upon hiring\n*Level 3: within 1 year upon hiring', 3, '{\"number\":3,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Manpower\",\"subject\":\"Training Requirements\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"CE CENTRAL\",\"how_to_check\":\"Check the training record from Training Department\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(332, 2, 60, 'dos-as-14', 'Customer Relations Department (CRO, Receptionist, Telemarketer) personnel count must be based on the standard requirements.', 4, '{\"number\":14,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Manpower\",\"subject\":\"Customer Relations Department\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Compute required count and function based on the latest released Standard Bulletin: MMPC SD-2024-010-S - Service CRD Manpower Count Duties  Responsibilities (Dec 2024)\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(333, 2, 60, 'dos-as-57', 'All service personnel should be neatly dressed and Technicians must wear the latest MMPC-prescribed uniform.', 5, '{\"number\":57,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Manpower\",\"subject\":\"Employees\' Uniform\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Visual check\\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check as indicated.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(334, 2, 61, 'dos-as-4', 'Does Telemarketer follow standard appointment balance for the day?', 1, '{\"number\":4,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Pro-active Customer Contact\",\"subject\":\"Offering of date and time\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check Appointment balance if:\\nMorning = 80%\\nAfternoon = 20%\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(335, 2, 61, 'dos-as-5', 'Does Telemarketer record reason of rejection in case customer do not accept PMS appointment.', 2, '{\"number\":5,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Pro-active Customer Contact\",\"subject\":\"Reason of Rejection\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check if there\'s a printed Customer Rejection Countermeasure and observe if utilized during call activities.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(336, 2, 61, 'dos-as-6', 'The CRO and Service Advisor should have a printed QR Code of contact number or hotline number visible to the customers.', 3, '{\"number\":6,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Pro-active Customer Contact\",\"subject\":\"Contact Details\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"CE CENTRAL\",\"how_to_check\":\"Check if there\'s a printed QR Code of contact number or hotline number visible to the customers:\\n1. Telemarketer\'s hotline - for service appointment\\n2. CRO - for complaints\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(337, 2, 62, 'dos-as-7', 'Does Telemarketer perform block time for walk-in customers?', 1, '{\"number\":7,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Appointment\",\"subject\":\"Blocking of SA for Walk-In customer\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check Appointment List if there is alloted block time for walk in.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(338, 2, 62, 'dos-as-8', 'Does Telemarketer assign and inform each SA their assigned customer with their appointment time?', 2, '{\"number\":8,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Customer Appointment\",\"subject\":\"SA assignment\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check Appointment List if there is SA allocated for each customer.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(339, 2, 62, 'dos-as-9', 'Does Telemarketer make appointment reconfirmation call the day before?', 3, '{\"number\":9,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Appointment\",\"subject\":\"Reconfirmation Call\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check Appointment List if with remarks that customers have been contacted for appointment reconfirmation 1 day prior.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(340, 2, 62, 'dos-as-11', 'Is the Appointment Welcome board visible to customer?\n\nWith complete details as follows:\n1) today\'s date\n2) time slot\n3) name or plate number of customer\n4) SA name\n5) purpose of visit: e.g. 10K PMS, GR, etc.\n6) Arrival Status (Green - On time, Yellow - Late, Red - No Show)', 4, '{\"number\":11,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Appointment\",\"subject\":\"Appointment Welcome Board\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check if based on standard template, if installed near service entrance, and visible to incoming customers inside their vehicle.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(341, 2, 62, 'dos-as-12', 'Telemarketer shares the list of customers booked 1 day before the day of appointment to all concerned after-sales personnel (Security Guard, Job Controller, Leadman, Parts Warehouse Staff, Service Advisor, Service Manager, Sales Executive - optional)', 5, '{\"number\":12,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Customer Appointment\",\"subject\":\"Appointment\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check if all mentioned service personnel have a copy of the Appointment List.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(342, 2, 63, 'dos-as-10', 'There should be no pending bookings more than 24hrs after it was created (Otoleap)', 1, '{\"number\":10,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Systems\",\"subject\":\"Otoleap Booking Management\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"CE CENTRAL\",\"how_to_check\":\"Check Otoleap calendar for the same month if there are no pending bookings the days prior the day of audit.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(343, 2, 63, 'dos-as-17', 'Dedicated digital tablet for walk-around inspection is available. (1 Tablet : 1 SA) (Updated to minimum Google Android ver. 9; Apple iOS 10)', 2, '{\"number\":17,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Systems\",\"subject\":\"CRM Requirements\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check if tablet is sufficient (1:1 with SA)\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(344, 2, 63, 'dos-as-29', 'Stable internet connection at the ff. area: \n(Bandwidth> 1Mbps and Latency<150ms) via Ookla speedtest\n1. Service Reception\n2. Receiving Bay', 3, '{\"number\":29,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Systems\",\"subject\":\"CRM Requirements\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check via Ookla speedtest\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47');
INSERT INTO `checklist_items` (`id`, `checklist_template_id`, `checklist_section_id`, `key`, `prompt`, `sort_order`, `metadata`, `is_active`, `created_at`, `updated_at`) VALUES
(345, 2, 63, 'dos-as-56', 'Has updated access account on Service Information Portal', 4, '{\"number\":56,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Systems\",\"subject\":\"Service Documents\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Confirm with ASM and Service Admin if they have updated access in the system (SeIP)\\n - Check when did they last log-in in the system\\n - follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check if can access Service Information Portal (SIP); if none, provide email\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(346, 2, 64, 'dos-as-13', 'Is there dedicated appointment bay and walk in receiving bays?', 1, '{\"number\":13,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Dedicated Appointment and Walk-In Bay\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check if SA\\/ Car Jockey is aware of the allocation of appointment and walk in receiving bays (minimum of 2 bays).\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(347, 2, 64, 'dos-as-42', 'Are there no parts on the floor without bin locator? And/ or does each locator stores only one kind of parts?', 2, '{\"number\":42,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Parts 5S\",\"checker\":\"Parts Supervisor\",\"pic\":\"ASM\",\"bom_task\":\"- Check if all parts inside the warehouse are stored with bin locators\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check parts warehouse as indicated.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(348, 2, 64, 'dos-as-45', 'Workbays are marked with demarcation lines, and identified with numbers; Cleanliness inside the workshop area is maintained (no lingering oil and water spills, and scattered items)', 3, '{\"number\":45,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Workshop Maintenance\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"ASM\",\"bom_task\":\"- Visual check of cleanliness in the workshop.\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check as indicated.\"}', 1, '2026-09-05 08:08:23', '2026-09-09 00:25:19'),
(349, 2, 64, 'dos-as-47', '> Items are properly sorted and stored\n> Cleanliness inside the tool room is maintained\n> Special service tools are wall-mounted\n> There is an updated borrower\'s logbook', 4, '{\"number\":47,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Tools Storage Room\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"ASM\",\"bom_task\":\"- Visual check\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check as indicated.\"}', 1, '2026-09-05 08:08:23', '2026-09-09 00:25:19'),
(350, 2, 64, 'dos-as-48', '> The components repair room is used for its intended purpose\n> The required tools are present and properly managed\n> Has adequate illumination and ventilation', 5, '{\"number\":48,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Components Repair Room\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"ASM\",\"bom_task\":\"- Visual check\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check as indicated.\"}', 1, '2026-09-05 08:08:23', '2026-09-09 00:25:19'),
(351, 2, 64, 'dos-as-49', '> Storage area is enclosed  \n> Drums are placed on top of elevated platforms  \n> No oil spills on the floor and with regular schedule disposal pullout', 6, '{\"number\":49,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Waste Oil Storage\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"ASM\",\"bom_task\":\"- Visual check\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check as indicated.\"}', 1, '2026-09-05 08:08:23', '2026-09-09 00:25:19'),
(352, 2, 64, 'dos-as-50', '> Storage area is enclosed  \n> Contains storage racks and bins; replaced parts must be secured with box \n> Follows the standard 30-60-90 days sorting scheme \n> Should have a proper tagging and inventory list and monitoring', 7, '{\"number\":50,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Warranty Parts Storage\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Visual check and validate if ageing warranty are correct\\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check as indicated.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(353, 2, 64, 'dos-as-51', 'Placed at the back part of the service shop and properly maintained', 8, '{\"number\":51,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Scrapped Parts Storage\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"ASM\",\"bom_task\":\"- Visual check if scrapped parts is  properly stored in its designated area\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check as indicated.\"}', 1, '2026-09-05 08:08:23', '2026-09-09 00:25:19'),
(354, 2, 64, 'dos-as-52', 'Must be in an enclosed area with enough racks and bins for proper sorting', 9, '{\"number\":52,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Dismantled Parts Storage\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"ASM\",\"bom_task\":\"- Visual check if dismantled parts is  properly stored in its designated area\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check as indicated.\"}', 1, '2026-09-05 08:08:23', '2026-09-09 00:25:19'),
(355, 2, 64, 'dos-as-54', 'Compliance with Employee Facilities standards (12 sub-requirements). All items must pass.', 10, '{\"number\":54,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Employee Facilities\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"Check with ASM and see if the form was accomplished properly.\\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"All check items in the subform must be \\\"YES\\\" to count this item compliant.\\n\\nSubform Verification Requirements:\\n1. Employees\' Restroom (Maintained clean and must have the proper amenities for convenience of use i.e. soap, water supply, tissue, etc.)\\n2. Technician Locker Room and Shower are adjacent with each other\\n3. Sufficient no. of technicians\' lockers\\n4. Technician Locker Room has sufficient no. of tables and benches\\n5. Technician Locker Room walls and flooring must have proper paint\\n6. Technician Locker Room has proper lighting and ventilation\\n7. Technician Shower Room has sufficient no. of showers, urinals, and toilet cubicle\\n8. Technician Shower Room has clean toilets bowls with flush, bidet, tissue and soap\\n9. Technician shower and toilets are completely functional\\n10. Technician waiting area (Near the Job Controller room for efficient job order dispatch)\\n11. Technician waiting area (Sufficient benches)\\n12. Technician handwash booth (Adequate supply of water) (separate booth is optional)\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(356, 2, 64, 'dos-as-55', 'Compliance with Meeting Room standards (3 sub-requirements). All items must pass.', 11, '{\"number\":55,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Meeting Room\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"Check with ASM and see if the form was accomplished properly.\\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"All check items in the subform must be \\\"YES\\\" to count this item compliant.\\n\\nSubform Verification Requirements:\\n1. Allocated Meeting\\/ Conference Room especially for online trainings\\n2. Available projector and PC\\/laptop (to be used for online trainings)\\n3. Available Wi-Fi (Internet Connection = 10mbps)\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(357, 2, 64, 'dos-as-74', '5S Checklists are accomplished by PICs.', 12, '{\"number\":74,\"level\":\"Beyond\",\"category\":\"Beyond\",\"coverage\":\"Facilities\",\"subject\":\"5S\",\"checker\":\"CE SERVICE\",\"pic\":\"ASM\",\"bom_task\":\"- Validate with CE if checklist is correctly accomplished\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check if standard 5S Checklists are filled out and updated.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(358, 2, 65, 'dos-as-15', 'Is there a queuing system in the reception area?', 1, '{\"number\":15,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Personalized Customer Reception\",\"subject\":\"Queuing system\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"CE CENTRAL\",\"how_to_check\":\"1. Observe if queuing system is effective and if process is consistently done by concerned service personnel. \\n2. Interview 2 customers if they are aware of their queuing number, and if the prioritization system (On time\\/ early\\/ late appointment, and walk in customer) was explained by Receptionist\\/ SA especially if customer needs to wait for the SA\'s availability\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(359, 2, 65, 'dos-as-16', 'Is there a Receptionist who will accommodate customer during peak hours or if all SA\'s are still accomodating the customers?', 2, '{\"number\":16,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Personalized Customer Reception\",\"subject\":\"Peak hours\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"CE CENTRAL\",\"how_to_check\":\"During peak hours, check if there is an assigned personnel who can receive customers or can explain prioritization process.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(360, 2, 65, 'dos-as-18', 'Does SA always inspect vehicle for any car body damage using standard walk around inspection checklist?', 3, '{\"number\":18,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Personalized Customer Reception\",\"subject\":\"Walk Around Inspection\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check 3 samples if walk around inspection is done and the WAI app is used by the SA; check all SA\'s implementation if possible.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(361, 2, 65, 'dos-as-19', 'Does SA always put the following protective covers before transfering the vehicle to workshop?\n\n1. Steering wheel cover\n2. Seat Cover\n3. Shifting knob cover\n4. Handbrake cover\n5. Floormats', 4, '{\"number\":19,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Personalized Customer Reception\",\"subject\":\"Protective Covers\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check if all service units in the workbay (esp. ongoing repair) have complete protective covers.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(362, 2, 65, 'dos-as-20', 'Do all vehicles in the workshop have a vehicle status tag with promised date/ time?', 5, '{\"number\":20,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Personalized Customer Reception\",\"subject\":\"Vehicle Status Tag\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check if all service units in the workbay have vehicle status tag.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(363, 2, 65, 'dos-as-21', 'Is there Direct Reception Process done inside the workshop?', 6, '{\"number\":21,\"level\":\"Beyond\",\"category\":\"Beyond\",\"coverage\":\"Personalized Customer Reception\",\"subject\":\"Direct Reption\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check if there is allocated:\\n1) Dedicated bay\\n2) Customer safety area in case the bay is inside Workshop. If the bay is within reception area, the safety area is optional\\n3) DR kit is available- (Minimum: Glove, Battery tester, Tire gauge, Torch light)\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(364, 2, 65, 'dos-as-22', 'Workshop entrance/exit is clear of obstructions at all times and not used as parking slots', 7, '{\"number\":22,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Personalized Customer Reception\",\"subject\":\"Workshop Driveway\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Observe service entrance if there is a parked unit for more than 20 minutes\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(365, 2, 65, 'dos-as-23', 'Compliance with Service Reception Area standards (7 sub-requirements). All items must pass.', 8, '{\"number\":23,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Personalized Customer Reception\",\"subject\":\"Service Reception Area\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"All check items in the subform must be \\\"YES\\\" to count this item compliant.\\n\\nSubform Verification Requirements:\\n2. Business hours clearly displayed at the entrance door\\n3. Three (3) monitors (with 42\\\" minimum dimension) are wall-mounted behind the Service Advisor counters, and displays service information and promotional videos\\n4. Service hotlines (appointment, customer, car carrier) and MM360c App QR codes are clearly displayed at the Reception Area\\n5. Must be provided with proper AC temperature (must be minimum of 25°C in thermometer) for customers\' convenience\\n7. Standard PMS menu and cost are displayed in the center monitor\\n8. Receptionist\\/SA on duty must be located near the entrance.\\n9. Must have sufficient illumination (open lights during operations) and no busted lights\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(366, 2, 66, 'dos-as-24', 'Does SA provide the customer a promised time of delivery by checking availability of technician through job controller/ Job Progress Monitoring file?', 1, '{\"number\":24,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Menu Pricing \\/ Commitment of Price and Time Delivery\",\"subject\":\"Promised Time\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Observe if SA gives promised time by using the shared Job Progress Monitoring\\/ Job Plan (updated) as reference, and not just based on flat rate time.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(367, 2, 66, 'dos-as-25', 'On the Repair Order, is cost estimate always attached?', 2, '{\"number\":25,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Menu Pricing \\/ Commitment of Price and Time Delivery\",\"subject\":\"Cost Estimate\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check 3 samples of Repair Order with signed Cost Estimate and observe if explained by the SA to the customer\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(368, 2, 66, 'dos-as-26', 'Does SA have an individual note with promised time of all received customers?', 3, '{\"number\":26,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Menu Pricing \\/ Commitment of Price and Time Delivery\",\"subject\":\"SA Individual Note\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check if SA uses any tool (e.g. notebook, notepad, excel, etc.) to ensure that all their received customers will be given update and that they can monitor nearing promised time per customer.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(369, 2, 67, 'dos-as-27', 'Compliance with Customers\' Lounge standards (11 sub-requirements). All items must pass.', 1, '{\"number\":27,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Customer Care and Communication\",\"subject\":\"Customers\' Lounge\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"All check items in the subform must be \\\"YES\\\" to count this item compliant.\\n\\nSubform Verification Requirements:\\n1. Sofas must be sufficient, comfortable, and maintained in good condition (Refer to MMPC corporate Visual Identity (VI) manual for the color)\\n2. Room temperature must be minimum of 25°C; temperature must be displayed through a thermometer\\n3. Must have sufficient illumination (open lights during operations) and no busted lights\\n4. Must offer at least three kinds of complimentary beverage (water, coffee, and juice) and at least one kind of snack\\n5. Television must have media player or cable channels\\n6. There\'s an available Wi-Fi with a speed of at least 10 Mbps when measured using speed test (Measuring tool: https:\\/\\/www.speedtest.net\\/)\\n7. There are available power outlets for mobile phone, tablet, and laptop\\n8. Service customer lounge must observe 5S at all times\\n9. Customer restroom\'s cleanliness is maintained at all times, and with updated maintenance monitoring sheet (clean, no foul odor, etc.)\\n10. Customer restroom must have complete amenities (Minimum requirements: clean water supply, toilet bowl, sink, urinal, bidet, trash cans, air freshener and no foul odor, tissue, paper towel or hand dryer, hand wash soap, and hand sanitizer)\\n11. Signages must be clearly displayed and follows the latest VI design: “Customer Lounge”, “Complimentary Wi-Fi”, “Complimentary Beverages and Snacks”, “Charging Station”, “Customer Restroom”\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(370, 2, 67, 'dos-as-28', 'Service Personnel/Service Advisor/ CRO/ SA on Duty verbally offers all available lounge amenities to customers (WiFi access/ password, Sofa, TV, CR)\n1) complimentary drink and snack \n2) WIFI, Password\n3) Mobile charging station\n4) How to read YANA vehicle status update\n5) Televison/ reading materials\n6) Comfort Room', 2, '{\"number\":28,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Care and Communication\",\"subject\":\"Offering of amenities\",\"checker\":\"CE SERVICE\",\"pic\":\"ASM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check by observing concerned personnel\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(371, 2, 67, 'dos-as-30', 'Dedicated Vehicle Status Monitor must be visibly displayed and reflects the latest vehicle status update at the Customer Lounge', 3, '{\"number\":30,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Care and Communication\",\"subject\":\"CRM Requirements\",\"checker\":\"CE SERVICE\",\"pic\":\"ASM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check availability of TV\\n2. Check 3 samples of service units and confirm current status if they match with the status displayed in the monitor.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(372, 2, 67, 'dos-as-31', 'Does the SA offer shuttle service transportation or assistance (e.g. grab, taxi etc…)?', 4, '{\"number\":31,\"level\":\"Beyond\",\"category\":\"Beyond\",\"coverage\":\"Customer Care and Communication\",\"subject\":\"Shuttle Service Assistance\",\"checker\":\"CE SERVICE\",\"pic\":\"ASM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check if there is poster and check by observing SA during RO processing and explanation with customer\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(373, 2, 67, 'dos-as-32', 'Did salesperson make contact with customer who was waiting at the lounge?\n150K > offer new vehicle', 5, '{\"number\":32,\"level\":\"Beyond\",\"category\":\"Beyond\",\"coverage\":\"Customer Care and Communication\",\"subject\":\"Assigned Sales Executive\",\"checker\":\"CE SERVICE\",\"pic\":\"GM\",\"bom_task\":\"- Check if the Assigned Agent for Service Reception for the day is present and is talking to the prospective client\\/s.\\n - Accessible table for Sales Agent assigned in the Service reception area.\\n - follow up action plan and monitor compliance.\",\"escalation\":\"Brand Head\",\"how_to_check\":\"Check if SE has copy of appointment list and the required amenities (calling cards, notepads, and quotation notes for customer reference during discussion)\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(374, 2, 67, 'dos-as-33', 'Does SA inform progress of vehicle to the waiting customer 1 hr after issuance of RO?', 6, '{\"number\":33,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Care and Communication\",\"subject\":\"Service Advisor\",\"checker\":\"CE SERVICE\",\"pic\":\"ASM\",\"bom_task\":\"- BOM to seek report from CE to check if there are any non-compliance\\n - Follow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Interview 2 customers to confirm if SA approached them to give vehicle status update.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(375, 2, 67, 'dos-as-34', 'Customer Information Sheet (CIS) and DPA Form is being used by Receptionist to gather customer contact information as needed.', 7, '{\"number\":34,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Care and Communication\",\"subject\":\"Customer Information Sheet\",\"checker\":\"CE SERVICE\",\"pic\":\"ASM\",\"bom_task\":\"- Check completeness of CIS\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"1. Observe received customers if being offered with CIS (if necessary)\\n2. Check if dealer compiles filled out and signed CIS forms.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(376, 2, 68, 'dos-as-35', 'Did the Job Controller conduct pre-planning  based on the appointment sheet for the day and regularly monitors actual progress of units in the shop?', 1, '{\"number\":35,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Workshop Scheduling\",\"subject\":\"Job Progress Monitoring\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Check Job Con Monitoring report\\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check the Job Progress Monitoring toolkit (excel\\/ board):\\n- Check in the morning if all appointment customers are included in the job plan for the day\\n- Check if walk-in customers are also monitored for proper allocation per bay and technician\\n- Check if actual progress per unit is recorded in the toolkit\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(377, 2, 68, 'dos-as-36', 'Is car wash control board available, properly filled out and based on the standard template?', 2, '{\"number\":36,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Workshop Scheduling\",\"subject\":\"Carwash Control Board\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"ASM\",\"bom_task\":\"- Check casrwash control board if updated and correct\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check if uses standard template and if filled out based on the current status of the vehicle inside the car wash bay.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(378, 2, 68, 'dos-as-37', 'Did Job Controller make car wash plan and communicate with carwasher the promised time of received customers?', 3, '{\"number\":37,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Workshop Scheduling\",\"subject\":\"Job Progress Monitoring\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Check casrwash control board if actual released time matched the promised released time\\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"1. Check Job Progress Monitoring\\/ Job Plan if with car wash plan\\n2. Check if uses 2-way radio (Job Controller and Car washer)\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(379, 2, 68, 'dos-as-38', 'Do technicians clock in as soon as RO is handed over and clock out as soon as job is completed (excluding QC)?', 4, '{\"number\":38,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Workshop Scheduling\",\"subject\":\"Technicians Clock-In\",\"checker\":\"JC\",\"pic\":\"ASM\",\"bom_task\":\"- Verify if actual clock-in or clock-out time is recorded\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check if there is a tool that is used to clock in and out Technician\'s repair time (that is being used by Service Manager to monitor productivity, utilization and efficiency)\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(380, 2, 68, 'dos-as-39', 'Carryover units are properly monitored and managed (with monitoring) by Job Controller.', 5, '{\"number\":39,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Workshop Scheduling\",\"subject\":\"Repair\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"ASM\",\"bom_task\":\"- Check job control WIP monitoring if updated and match the actual units in the workshop\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check if there is a carry over units monitoring being utilized to monitor all remaining vehicles inside the shop.\"}', 1, '2026-09-05 08:08:23', '2026-09-09 00:25:19'),
(381, 2, 69, 'dos-as-40', 'Does Parts Staff pre-pick parts for appointment and walk-in customers?', 1, '{\"number\":40,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Advance Info to Parts Store\",\"subject\":\"Pre-Picking\",\"checker\":\"Parts Supervisor\",\"pic\":\"ASM\",\"bom_task\":\"- Physical Checking of pre-picked parts of corrent\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check if there are pre-picked parts in a basket\\/ container with standard pre-picking tag in a storage shelves\\/ rack.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(382, 2, 69, 'dos-as-41', 'Is there any monitoring to ensure that the Leadman/ technician who is waiting for emergency parts is contacted immediately after delivery/receiving of parts?', 2, '{\"number\":41,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Advance Info to Parts Store\",\"subject\":\"Emergency Parts\",\"checker\":\"Parts Supervisor\",\"pic\":\"ASM\",\"bom_task\":\"- Ask workshop supervisor\\/ leadman if they were immediately informed if emergency parts already arrived in the dealership\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check monitoring tool used by the Parts Staff for emergency orders.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(383, 2, 70, 'dos-as-43', 'Does Leadman indicate or instruct target job completion time to the assigned technician?', 1, '{\"number\":43,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Repair Order Processing and Quality of Work\",\"subject\":\"Vehicle Status Tag\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"ASM\",\"bom_task\":\"- Check if technician visualization tag if updated by leadman and if the details on the Tag is correct vs the actual job.\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check if vehicle status tag has promised time of delivery and in the windshield and Technician Visualization Tag is available and updated on a real time basis.\"}', 1, '2026-09-05 08:08:23', '2026-09-09 00:25:19'),
(384, 2, 70, 'dos-as-44', 'In case of unapproved job by the customer, does SA record as \"future work reminder\" in service history of DMS?', 2, '{\"number\":44,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Repair Order Processing and Quality of Work\",\"subject\":\"Unapproved Job\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Gather Estimate Report from ASM to check. \\n(Do we need to allow access for BOM?) \\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check DMS if there are notes on jobs rejected by customers (at least 3 samples)\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(385, 2, 70, 'dos-as-46', 'Service Vehicle:\nAll service vehicle has exterior covers installed (bumper and fender)', 3, '{\"number\":46,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Repair Order Processing and Quality of Work\",\"subject\":\"Repair\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"ASM\",\"bom_task\":\"- Visual check\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check if vehicle being serviced has complete exterior protective covers.\"}', 1, '2026-09-05 08:08:23', '2026-09-09 00:25:19'),
(386, 2, 70, 'dos-as-53', 'Compliance with Mitsubishi Quick Service standards (4 sub-requirements). All items must pass.', 4, '{\"number\":53,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Repair Order Processing and Quality of Work\",\"subject\":\"Mitsubishi Quick Service\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"ASM\",\"bom_task\":\"Check with ASM and see if the form was accomplished properly.\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"All check items in the subform must be \\\"YES\\\" to count this item compliant.\\n\\nSubform Verification Requirements:\\n1. Dedicated MQS bay with complete MQS basic and advanced tools\\n2. Proper execution of MQS sequence\\n3. Check 1 sample of MQS vehicle if within prescribed time\\n4. MQS technician must be provided with complete QS uniforms\"}', 1, '2026-09-05 08:08:23', '2026-09-09 00:25:19'),
(387, 2, 71, 'dos-as-58', 'Does vehicle status tag indicate proper status inside the shop? (e.g. if ongoing repair, or for car wash, etc.)', 1, '{\"number\":58,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Repair Order Completion and Invoicing\",\"subject\":\"Vehicle Status Tag\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Visual check\\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check 3 samples of vehicles inside the shop with vehicle status tag that is updated based on actual status (e.g. if ongoing repair, or for car wash, etc.)\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(388, 2, 71, 'dos-as-59', 'Escorted the customer to his/her vehicle.', 2, '{\"number\":59,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Repair Order Completion and Invoicing\",\"subject\":\"Delivery\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Check with SA and security Guard\\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Observe SA during vehicle handover process (2 samples)\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(389, 2, 71, 'dos-as-60', 'Did SA inform waiting customer and non waiting customer when car is ready for return?', 3, '{\"number\":60,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Repair Order Completion and Invoicing\",\"subject\":\"Car Return\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Check with SA and security Guard\\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Observe 2 customers that is being reminded by Service Advisor that their vehicle is ready for hand over.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(390, 2, 71, 'dos-as-61', 'Documentation:\nProper utilization of all service documents (Rationalized Checksheet, Repair Order, Service Invoice)', 4, '{\"number\":61,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Repair Order Completion and Invoicing\",\"subject\":\"Repair\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Verify if proper documentation was applied depending on the type of transaction (e.g QC Stamp, customer signatures etc)\\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"All check items must be compliant (3 samples)\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(391, 2, 72, 'dos-as-62', 'Does SA refer to the initial agreed RO and quoted price?', 1, '{\"number\":62,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Information and Car Return\",\"subject\":\"Actual Cost\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Check if quotations\\/estimate is signed by the customer\\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check 3 samples if Service Invoice matches with the Cost Estimate (same amount or below as agreed with customer)\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(392, 2, 72, 'dos-as-63', 'Does SA show replaced parts (if applicable) during delivery process?', 2, '{\"number\":63,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Information and Car Return\",\"subject\":\"Replaced Parts\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Check if replaced parts was returned to the customer. If not, verify if there is proper documentation for it.\\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check 2 vehicle handover process if replaced parts are shown to customer\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(393, 2, 72, 'dos-as-64', 'Does Service Advisor remind the customer regarding QVOC?', 3, '{\"number\":64,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Information and Car Return\",\"subject\":\"QVOC Reminder\",\"checker\":\"CE SERVICE\",\"pic\":\"ASM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check if there is a poster stating about the survey and shows the sample content of message\\nSA - Main PIC; Receptionist - Sub PIC\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(394, 2, 72, 'dos-as-65', 'Does SA remove the Protective Cover Sheet in the presence of Customer before vehicle is delivered back to the Customer?', 4, '{\"number\":65,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Information and Car Return\",\"subject\":\"Removal of Protective Cover\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"ASM\",\"bom_task\":\"- check with security if covers are removed in the presence of customers.\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check 2 vehicle handover process\"}', 1, '2026-09-05 08:08:23', '2026-09-09 00:25:19'),
(395, 2, 72, 'dos-as-66', 'Does SA mention about the follow up call and its purpose such as the following?\n > to give notice to the customer that follow up call will be made by CRO within 3 days\n > benefit of the follow up call for customer\n > preferable time to receive a call', 5, '{\"number\":66,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Information and Car Return\",\"subject\":\"Follow-Up Call\",\"checker\":\"CE SERVICE\",\"pic\":\"ASM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"CE CENTRAL\",\"how_to_check\":\"Check by observing concerned personnel\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(396, 2, 73, 'dos-as-67', 'Does CRO conduct 3 days after service follow up calls?', 1, '{\"number\":67,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer After Service Contact\",\"subject\":\"Follow-Up Call\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check monitoring tool used by the CRO if with update.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(397, 2, 73, 'dos-as-68', 'Does CRO categorize concerns based on follow up call result and collected QVOC responses? (i.e. concern on parking, attitude of staff, quality of work, price of RO etc.)', 2, '{\"number\":68,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer After Service Contact\",\"subject\":\"Complaint Monitoring Tracking Report\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check Customer Complaint Monitoring (categorization)\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(398, 2, 73, 'dos-as-69', 'Does the Complaint Monitoring Tracking Report include open concern (concern that has no implemented action within 7 calendar days).', 3, '{\"number\":69,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer After Service Contact\",\"subject\":\"Complaint Monitoring Tracking Report\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check Customer Complaint Monitoring (updated status monitoring)\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(399, 2, 74, 'dos-as-70', 'Is \"Weekly Meeting\" (MAM) organized at least once a week at the same time on the same day of week?', 1, '{\"number\":70,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Concern Prevention and Resolution\",\"subject\":\"MAM\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Check MAM template filled-out form\\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check latest minutes of the meeting (frequency)\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(400, 2, 74, 'dos-as-71', 'Is \"Daily Meeting\" (MOM) organized daily with workshop staff at the same time ?', 2, '{\"number\":71,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Concern Prevention and Resolution\",\"subject\":\"MAM\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Check MAM template filled-out form\\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check by observation and check latest minutes of the meeting\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(401, 2, 74, 'dos-as-72', 'Is there any information board which displays actions or KPI derived from MAM?', 3, '{\"number\":72,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Concern Prevention and Resolution\",\"subject\":\"MAM\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Visual check bulleting board if updated\\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check availability of board in service office (or MAM meeting place) and if KPIs are displayed\\/ updated for discussion\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(402, 2, 74, 'dos-as-73', 'Is there any information board which displays key information, and suggestions from workshop staff derived from MOM?', 4, '{\"number\":73,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Concern Prevention and Resolution\",\"subject\":\"MOM\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Visual check bulleting board if updated\\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check availability of board that is visible to all service personnel (inside shop) and if KPIs are displayed\\/ updated for discussion\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(403, 2, 74, 'dos-as-75', 'Are the following KPI being monitored and ready to be discussed in case its necessary during \"Weekly Meeting\"?: \n\nMAIN KPI:\n1) Actual SIU and target agreed with MMPC\n2) Actual first retention rate\n3) Actual P&A booking and target agreed with MMPC\n4) Stock month of fast moving parts\n5) Appointment ratio\n6) Dead stock ratio \n7) CSI\n\nTechnician Report:\n8) Efficiency (labor sold hr / actual worked hr)\n9) Utilization (actual worked hr / available hr)\n10) Productivity (efficiency x utilization)\n\nCRO/ Telemarketer:\n11) Reminder call coverage ratio (actual reminder call / target reminder call)\n12) Proactive call acceptance ratio (actual accepted appointment booking / called customer)\n13) Follow up call ratio\n14) Customer Complaint Tracking Discussion (Red alert, critical concerns)\n15) Appointment balance for a day (Morning = 80%, Afternoon = 20%)\n\nJob Controller: \n16) On time delivery and on time arrival ratio (from service time monitoring)\n\nOthers:\n17) Fix it right first time or repeat repair ratio (F1)\n18) Direct reception (optional)\n19) Focus item upselling (optional)', 5, '{\"number\":75,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Concern Prevention and Resolution\",\"subject\":\"MAM\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Check if bulletin boards matches the MAM and MOM templates\\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check minutes of the meeting (quality)\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(404, 7, 75, 'subform-sr-1', 'Service Reception signage follows the standard design, and must be clearly displayed at the entrance', 0, '{\"number\":1,\"level\":\"Standard\",\"coverage\":\"Service Reception\",\"subject\":\"Service Reception Area\",\"checker\":\"CE SERVICE\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify signage follows MMPC VI design standards and is clearly visible at entrance.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(405, 7, 75, 'subform-sr-2', 'Business hours clearly displayed at the entrance door', 1, '{\"number\":2,\"level\":\"Standard\",\"coverage\":\"Service Reception\",\"subject\":\"Service Reception Area\",\"checker\":\"CE SERVICE\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check if business hours are clearly posted on entrance door.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(406, 7, 75, 'subform-sr-3', 'Three (3) monitors (with 42\" minimum dimension) are wall-mounted behind the Service Advisor counters, and displays service information and promotional videos', 2, '{\"number\":3,\"level\":\"Standard\",\"coverage\":\"Service Reception\",\"subject\":\"Service Reception Area\",\"checker\":\"CE SERVICE\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Confirm 3 monitors (min 42\\\") behind SA counters playing updated promo videos and service info.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(407, 7, 75, 'subform-sr-4', 'Service hotlines (appointment, customer, car carrier) and MM360c App QR codes are clearly displayed at the Reception Area', 3, '{\"number\":4,\"level\":\"Standard\",\"coverage\":\"Service Reception\",\"subject\":\"Service Reception Area\",\"checker\":\"CE SERVICE\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check hotlines and MM360c app QR codes display at reception.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(408, 7, 75, 'subform-sr-5', 'Must be provided with proper AC temperature (must be minimum of 25°C in thermometer) for customers\' convenience', 4, '{\"number\":5,\"level\":\"Standard\",\"coverage\":\"Service Reception\",\"subject\":\"Service Reception Area\",\"checker\":\"CE SERVICE\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify room thermometer reads at least 25\\u00b0C.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(409, 7, 75, 'subform-sr-6', 'Service reception counter must observe 5S (mainly service advisor\'s table)', 5, '{\"number\":6,\"level\":\"Standard\",\"coverage\":\"Service Reception\",\"subject\":\"Service Reception Area\",\"checker\":\"CE SERVICE\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Perform 5S audit on SA desks and service reception counter.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(410, 7, 75, 'subform-sr-7', 'Standard PMS menu and cost are displayed in the center monitor', 6, '{\"number\":7,\"level\":\"Standard\",\"coverage\":\"Service Reception\",\"subject\":\"Service Reception Area\",\"checker\":\"CE SERVICE\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Confirm center monitor displays current PMS menu pricing.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(411, 7, 75, 'subform-sr-8', 'Receptionist/SA on duty must be located near the entrance.', 7, '{\"number\":8,\"level\":\"Standard\",\"coverage\":\"Service Reception\",\"subject\":\"Service Reception Area\",\"checker\":\"CE SERVICE\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Observe if Receptionist or SA on duty is positioned at entrance.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(412, 7, 75, 'subform-sr-9', 'Must have sufficient illumination (open lights during operations) and no busted lights', 8, '{\"number\":9,\"level\":\"Standard\",\"coverage\":\"Service Reception\",\"subject\":\"Service Reception Area\",\"checker\":\"CE SERVICE\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify all lighting fixtures are operational with no busted bulbs.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(413, 7, 76, 'subform-ef-1', 'Employees\' Restroom (Maintained clean and must have the proper amenities for convenience of use i.e. soap, water supply, tissue, etc.)', 0, '{\"number\":1,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Employee Facilities\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Inspect employee restroom cleanliness, soap, water, and tissue.\"}', 1, '2026-09-06 22:35:02', '2026-09-09 00:25:19'),
(414, 7, 76, 'subform-ef-2', 'Technician Locker Room and Shower are adjacent with each other', 1, '{\"number\":2,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Employee Facilities\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify technician locker room and shower are adjacent.\"}', 1, '2026-09-06 22:35:02', '2026-09-09 00:25:19'),
(415, 7, 76, 'subform-ef-3', 'Sufficient no. of technicians\' lockers', 2, '{\"number\":3,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Employee Facilities\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify sufficient lockers allocated for all technicians.\"}', 1, '2026-09-06 22:35:02', '2026-09-09 00:25:19'),
(416, 7, 76, 'subform-ef-4', 'Technician Locker Room has sufficient no. of tables and benches', 3, '{\"number\":4,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Employee Facilities\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check adequacy of tables and seating in locker room.\"}', 1, '2026-09-06 22:35:02', '2026-09-09 00:25:19'),
(417, 7, 76, 'subform-ef-5', 'Technician Locker Room walls and flooring must have proper paint', 4, '{\"number\":5,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Employee Facilities\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Inspect condition of paint on walls and flooring.\"}', 1, '2026-09-06 22:35:02', '2026-09-09 00:25:19'),
(418, 7, 76, 'subform-ef-6', 'Technician Locker Room has proper lighting and ventilation', 5, '{\"number\":6,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Employee Facilities\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Inspect lighting and ventilation operational status.\"}', 1, '2026-09-06 22:35:02', '2026-09-09 00:25:19'),
(419, 7, 76, 'subform-ef-7', 'Technician Shower Room has sufficient no. of showers, urinals, and toilet cubicle', 6, '{\"number\":7,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Employee Facilities\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Count and check function of showers, urinals, cubicles.\"}', 1, '2026-09-06 22:35:02', '2026-09-09 00:25:19');
INSERT INTO `checklist_items` (`id`, `checklist_template_id`, `checklist_section_id`, `key`, `prompt`, `sort_order`, `metadata`, `is_active`, `created_at`, `updated_at`) VALUES
(420, 7, 76, 'subform-ef-8', 'Technician Shower Room has clean toilets bowls with flush, bidet, tissue and soap', 7, '{\"number\":8,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Employee Facilities\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check amenities in shower room toilets.\"}', 1, '2026-09-06 22:35:02', '2026-09-09 00:25:19'),
(421, 7, 76, 'subform-ef-9', 'Technician shower and toilets are completely functional', 8, '{\"number\":9,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Employee Facilities\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Test all fixtures for water flow, drainage, and flushing.\"}', 1, '2026-09-06 22:35:02', '2026-09-09 00:25:19'),
(422, 7, 76, 'subform-ef-10', 'Technician waiting area (Near the Job Controller room for efficient job order dispatch)', 9, '{\"number\":10,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Employee Facilities\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify location is near JC room for dispatch.\"}', 1, '2026-09-06 22:35:02', '2026-09-09 00:25:19'),
(423, 7, 76, 'subform-ef-11', 'Technician waiting area (Sufficient benches)', 10, '{\"number\":11,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Employee Facilities\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify benches are sufficient for technicians on standby.\"}', 1, '2026-09-06 22:35:02', '2026-09-09 00:25:19'),
(424, 7, 76, 'subform-ef-12', 'Technician handwash booth (Adequate supply of water) (separate booth is optional)', 11, '{\"number\":12,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Employee Facilities\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify water supply and cleanliness at handwash station.\"}', 1, '2026-09-06 22:35:02', '2026-09-09 00:25:19'),
(425, 7, 77, 'subform-mr-1', 'Allocated Meeting/ Conference Room especially for online trainings', 0, '{\"number\":1,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Meeting Room\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify designated meeting\\/conference room exists.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(426, 7, 77, 'subform-mr-2', 'Available projector and PC/laptop (to be used for online trainings)', 1, '{\"number\":2,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Meeting Room\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check presence and functionality of projector\\/laptop.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(427, 7, 77, 'subform-mr-3', 'Available Wi-Fi (Internet Connection = 10mbps)', 2, '{\"number\":3,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Meeting Room\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Run speed test to verify minimum 10mbps connection.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(428, 7, 78, 'subform-mqs-1', 'Dedicated MQS bay with complete MQS basic and advanced tools', 0, '{\"number\":1,\"level\":\"Standard\",\"coverage\":\"Repair Order Processing and Quality of Work\",\"subject\":\"Mitsubishi Quick Service\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Verify dedicated MQS bay has complete basic and advanced tool sets.\"}', 1, '2026-09-06 22:35:02', '2026-09-09 00:25:19'),
(429, 7, 78, 'subform-mqs-2', 'Proper execution of MQS sequence', 1, '{\"number\":2,\"level\":\"Standard\",\"coverage\":\"Repair Order Processing and Quality of Work\",\"subject\":\"Mitsubishi Quick Service\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Observe technicians conducting standard MQS sequence.\"}', 1, '2026-09-06 22:35:02', '2026-09-09 00:25:19'),
(430, 7, 78, 'subform-mqs-3', 'Check 1 sample of MQS vehicle if within prescribed time', 2, '{\"number\":3,\"level\":\"Standard\",\"coverage\":\"Repair Order Processing and Quality of Work\",\"subject\":\"Mitsubishi Quick Service\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Sample 1 MQS job to ensure adherence to promised delivery duration.\"}', 1, '2026-09-06 22:35:02', '2026-09-09 00:25:19'),
(431, 7, 78, 'subform-mqs-4', 'MQS technician must be provided with complete QS uniforms', 3, '{\"number\":4,\"level\":\"Standard\",\"coverage\":\"Repair Order Processing and Quality of Work\",\"subject\":\"Mitsubishi Quick Service\",\"checker\":\"WORKSHOP SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Inspect MQS technician uniforms.\"}', 1, '2026-09-06 22:35:02', '2026-09-09 00:25:19'),
(432, 7, 79, 'subform-cl-1', 'Sofas must be sufficient, comfortable, and maintained in good condition (Refer to MMPC corporate Visual Identity (VI) manual for the color)', 0, '{\"number\":1,\"level\":\"Standard\",\"coverage\":\"Customer Care and Communication\",\"subject\":\"Customers\' Lounge\",\"checker\":\"CE SERVICE\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Inspect lounge sofas for condition, comfort, and MMPC VI color.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(433, 7, 79, 'subform-cl-2', 'Room temperature must be minimum of 25°C; temperature must be displayed through a thermometer', 1, '{\"number\":2,\"level\":\"Standard\",\"coverage\":\"Customer Care and Communication\",\"subject\":\"Customers\' Lounge\",\"checker\":\"CE SERVICE\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify room thermometer reads at least 25\\u00b0C.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(434, 7, 79, 'subform-cl-3', 'Must have sufficient illumination (open lights during operations) and no busted lights', 2, '{\"number\":3,\"level\":\"Standard\",\"coverage\":\"Customer Care and Communication\",\"subject\":\"Customers\' Lounge\",\"checker\":\"CE SERVICE\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify all lighting fixtures are operational with no busted bulbs.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(435, 7, 79, 'subform-cl-4', 'Must offer at least three kinds of complimentary beverage (water, coffee, and juice) and at least one kind of snack', 3, '{\"number\":4,\"level\":\"Standard\",\"coverage\":\"Customer Care and Communication\",\"subject\":\"Customers\' Lounge\",\"checker\":\"CE SERVICE\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Confirm 3 beverage varieties and at least 1 snack available.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(436, 7, 79, 'subform-cl-5', 'Television must have media player or cable channels', 4, '{\"number\":5,\"level\":\"Standard\",\"coverage\":\"Customer Care and Communication\",\"subject\":\"Customers\' Lounge\",\"checker\":\"CE SERVICE\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Confirm television has working media player or cable channels.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(437, 7, 79, 'subform-cl-6', 'There\'s an available Wi-Fi with a speed of at least 10 Mbps when measured using speed test (Measuring tool: https://www.speedtest.net/)', 5, '{\"number\":6,\"level\":\"Standard\",\"coverage\":\"Customer Care and Communication\",\"subject\":\"Customers\' Lounge\",\"checker\":\"CE SERVICE\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Perform speed test and ensure \\u226510 Mbps speed.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(438, 7, 79, 'subform-cl-7', 'There are available power outlets for mobile phone, tablet, and laptop', 6, '{\"number\":7,\"level\":\"Standard\",\"coverage\":\"Customer Care and Communication\",\"subject\":\"Customers\' Lounge\",\"checker\":\"CE SERVICE\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Inspect availability and function of charging outlets.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(439, 7, 79, 'subform-cl-8', 'Service customer lounge must observe 5S at all times', 7, '{\"number\":8,\"level\":\"Standard\",\"coverage\":\"Customer Care and Communication\",\"subject\":\"Customers\' Lounge\",\"checker\":\"CE SERVICE\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify customer lounge complies with 5S cleanliness.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(440, 7, 79, 'subform-cl-9', 'Customer restroom\'s cleanliness is maintained at all times, and with updated maintenance monitoring sheet (clean, no foul odor, etc.)', 8, '{\"number\":9,\"level\":\"Standard\",\"coverage\":\"Customer Care and Communication\",\"subject\":\"Customers\' Lounge\",\"checker\":\"CE SERVICE\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check customer restroom hygiene and log sheet.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(441, 7, 79, 'subform-cl-10', 'Customer restroom must have complete amenities (Minimum requirements: clean water supply, toilet bowl, sink, urinal, bidet, trash cans, air freshener and no foul odor, tissue, paper towel or hand dryer, hand wash soap, and hand sanitizer)', 9, '{\"number\":10,\"level\":\"Standard\",\"coverage\":\"Customer Care and Communication\",\"subject\":\"Customers\' Lounge\",\"checker\":\"CE SERVICE\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify all required restroom amenities are stocked.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(442, 7, 79, 'subform-cl-11', 'Signages must be clearly displayed and follows the latest VI design: “Customer Lounge”, “Complimentary Wi-Fi”, “Complimentary Beverages and Snacks”, “Charging Station”, “Customer Restroom”', 10, '{\"number\":11,\"level\":\"Standard\",\"coverage\":\"Customer Care and Communication\",\"subject\":\"Customers\' Lounge\",\"checker\":\"CE SERVICE\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify all required directional and amenity signages.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(443, 8, 80, 'doc-rc-1', 'Uses latest Rationalized Checksheet (5k or 10k)', 0, '{\"number\":1,\"level\":\"Standard\",\"coverage\":\"Repair Order Completion and Invoicing\",\"subject\":\"Service Documents\",\"checker\":\"CE SERVICE\",\"pic\":\"CE SERVICE\",\"bom_task\":\"Verify rationalized checksheet revision used\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify current version 5k or 10k checksheet is attached.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(444, 8, 80, 'doc-rc-2', 'Complete Name and Plate Number', 1, '{\"number\":2,\"level\":\"Standard\",\"coverage\":\"Repair Order Completion and Invoicing\",\"subject\":\"Service Documents\",\"checker\":\"CE SERVICE\",\"pic\":\"CE SERVICE\",\"bom_task\":\"Check vehicle and customer details completeness\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify customer full name and vehicle plate number are written.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(445, 8, 80, 'doc-rc-3', 'PMS checklist is properly filled-out', 2, '{\"number\":3,\"level\":\"Standard\",\"coverage\":\"Repair Order Completion and Invoicing\",\"subject\":\"Service Documents\",\"checker\":\"CE SERVICE\",\"pic\":\"CE SERVICE\",\"bom_task\":\"Check completeness of PMS line items\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify all PMS checklist items are checked\\/accomplished.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(446, 8, 80, 'doc-rc-4', 'Safety checklist is properly filled-out', 3, '{\"number\":4,\"level\":\"Standard\",\"coverage\":\"Repair Order Completion and Invoicing\",\"subject\":\"Service Documents\",\"checker\":\"CE SERVICE\",\"pic\":\"CE SERVICE\",\"bom_task\":\"Check safety inspection items completeness\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify safety inspection checklist is filled out completely.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(447, 8, 80, 'doc-rc-5', 'Carwash checklist is properly filled-out', 4, '{\"number\":5,\"level\":\"Standard\",\"coverage\":\"Repair Order Completion and Invoicing\",\"subject\":\"Service Documents\",\"checker\":\"CE SERVICE\",\"pic\":\"CE SERVICE\",\"bom_task\":\"Verify carwash inspection sheet\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify carwash completion check is recorded.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(448, 8, 80, 'doc-rc-6', 'Final walk-around inspection checklist is properly filled-out', 5, '{\"number\":6,\"level\":\"Standard\",\"coverage\":\"Repair Order Completion and Invoicing\",\"subject\":\"Service Documents\",\"checker\":\"CE SERVICE\",\"pic\":\"CE SERVICE\",\"bom_task\":\"Check final walk-around checklist\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Confirm final walk-around inspection section is completed.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(449, 8, 80, 'doc-rc-7', '10pts. Service Advisor Checklist is properly filled-out', 6, '{\"number\":7,\"level\":\"Standard\",\"coverage\":\"Repair Order Completion and Invoicing\",\"subject\":\"Service Documents\",\"checker\":\"CE SERVICE\",\"pic\":\"CE SERVICE\",\"bom_task\":\"Check 10-point SA checklist\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify all 10 points in the SA checklist are accomplished.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(450, 8, 80, 'doc-rc-8', 'With SA\' Signature', 7, '{\"number\":8,\"level\":\"Standard\",\"coverage\":\"Repair Order Completion and Invoicing\",\"subject\":\"Service Documents\",\"checker\":\"CE SERVICE\",\"pic\":\"CE SERVICE\",\"bom_task\":\"Verify Service Advisor signature\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Confirm SA signed the checksheet.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(451, 8, 80, 'doc-rc-9', 'With Technician\'s signature', 8, '{\"number\":9,\"level\":\"Standard\",\"coverage\":\"Repair Order Completion and Invoicing\",\"subject\":\"Service Documents\",\"checker\":\"CE SERVICE\",\"pic\":\"CE SERVICE\",\"bom_task\":\"Verify Technician signature\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Confirm attending technician signed the checksheet.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(452, 8, 80, 'doc-rc-10', 'With Leadman\'s signature', 9, '{\"number\":10,\"level\":\"Standard\",\"coverage\":\"Repair Order Completion and Invoicing\",\"subject\":\"Service Documents\",\"checker\":\"CE SERVICE\",\"pic\":\"CE SERVICE\",\"bom_task\":\"Verify Leadman signature\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Confirm Leadman\\/Foreman signature is present.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(453, 8, 80, 'doc-rc-11', 'With customer\'s signature', 10, '{\"number\":11,\"level\":\"Standard\",\"coverage\":\"Repair Order Completion and Invoicing\",\"subject\":\"Service Documents\",\"checker\":\"CE SERVICE\",\"pic\":\"CE SERVICE\",\"bom_task\":\"Verify customer signature on reception\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Confirm customer signature acknowledging the checksheet.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(454, 8, 81, 'doc-ro-1', 'Complete customer and vehicle details', 0, '{\"number\":12,\"level\":\"Standard\",\"coverage\":\"Repair Order Completion and Invoicing\",\"subject\":\"Service Documents\",\"checker\":\"CE SERVICE\",\"pic\":\"CE SERVICE\",\"bom_task\":\"Check RO header details completeness\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Confirm customer name, contact, VIN, plate number, mileage on RO.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(455, 8, 81, 'doc-ro-2', 'Promised time of delivery is indicated', 1, '{\"number\":13,\"level\":\"Standard\",\"coverage\":\"Repair Order Completion and Invoicing\",\"subject\":\"Service Documents\",\"checker\":\"CE SERVICE\",\"pic\":\"CE SERVICE\",\"bom_task\":\"Verify promised delivery time entry\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Confirm promised delivery date and time are clearly written on RO.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(456, 8, 81, 'doc-ro-3', 'With Customer\'s signature', 2, '{\"number\":14,\"level\":\"Standard\",\"coverage\":\"Repair Order Completion and Invoicing\",\"subject\":\"Service Documents\",\"checker\":\"CE SERVICE\",\"pic\":\"CE SERVICE\",\"bom_task\":\"Verify customer authorization signature\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Confirm customer signature authorizing the repair order.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(457, 8, 82, 'doc-si-1', 'Date/time actual repair time is indicated', 0, '{\"number\":15,\"level\":\"Standard\",\"coverage\":\"Repair Order Completion and Invoicing\",\"subject\":\"Service Documents\",\"checker\":\"CE SERVICE\",\"pic\":\"CE SERVICE\",\"bom_task\":\"Check actual repair time notation\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Confirm actual date and time repair concluded is recorded on invoice.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(458, 8, 82, 'doc-si-2', 'Customer\'s and SA\'s signature', 1, '{\"number\":16,\"level\":\"Standard\",\"coverage\":\"Repair Order Completion and Invoicing\",\"subject\":\"Service Documents\",\"checker\":\"CE SERVICE\",\"pic\":\"CE SERVICE\",\"bom_task\":\"Verify release signatures\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Confirm both customer and SA signed upon vehicle release.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(459, 8, 82, 'doc-si-3', 'Next PMS Schedule is indicated with MM360c App booking code', 2, '{\"number\":17,\"level\":\"Standard\",\"coverage\":\"Repair Order Completion and Invoicing\",\"subject\":\"Service Documents\",\"checker\":\"CE SERVICE\",\"pic\":\"CE SERVICE\",\"bom_task\":\"Check next PMS notation and MM360c booking code\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Confirm next PMS schedule and MM360c booking code are noted on invoice.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(460, 6, 83, 'dos-17', 'Training facility/room shall be within standard room size based on Circular NTD-STS-2024-010', 11, '{\"number\":12,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Dealer Training Facilities and Equipment Standards\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"DND\",\"how_to_check\":\"1. Standard training room \\nRoom size must be sufficient based on dealer category:\\nA \\u2013 37 & above m\\u00b2\\nB - 30 to 36 m\\u00b2\\nC \\u2013 25 to 29 m\\u00b2\\nD \\u2013 18 to 24 m\\u00b2\\nE \\u2013 16 to 18 m\\u00b2\\nF \\u2013 15 to 16 m\\u00b2\",\"code\":\"12\",\"label\":\"Dealer Training Facilities and Equipment Standards\",\"description\":\"Training facility\\/room shall be within standard room size based on Circular NTD-STS-2024-010\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(461, 6, 83, 'dos-18', 'Training facility/room shall have complete tools and equipment for training based on Circular NTD-STS-2024-010', 12, '{\"number\":13,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Dealer Training Facilities and Equipment Standards\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check tools and equipment:\\n\\u2022 Table and chairs\\n\\u2022 Projector\\/TV\\n\\u2022 External speaker with 3.5mm jack \\n\\u2022 HDMI and\\/or VGA cable \\n\\u2022 Presentation clicker\\n\\u2022 Office Supplies\\n\\u2022 Whiteboard\",\"code\":\"13\",\"label\":\"Dealer Training Facilities and Equipment Standards\",\"description\":\"Training facility\\/room shall have complete tools and equipment for training based on Circular NTD-STS-2024-010\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(462, 6, 83, 'dos-19', 'Sales Executives/Sales CROs must have a secured and stable internet connection during training', 13, '{\"number\":14,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Dealer Training Facilities and Equipment Standards\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise IT of non compliance.\\n> follow up until compliant.\",\"escalation\":\"IT\",\"how_to_check\":\"1. Check connection being used by SE.\",\"code\":\"14\",\"label\":\"Dealer Training Facilities and Equipment Standards\",\"description\":\"Sales Executives\\/Sales CROs must have a secured and stable internet connection during training\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(463, 6, 83, 'dos-20', 'Dealers must have a dedicated computer/laptop within the required specification for training and other tools/software.', 14, '{\"number\":15,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Dealer Training Facilities and Equipment Standards\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"IT\",\"how_to_check\":\"1. Check if the dealer follows the minimum requirement for desktop\\/laptop\\n\\n\\u2022 CPU: At least Ryzen 5\\/Intel Core i5 or \\nhigher \\n\\u2022 RAM: At least 8GB DDR4 or higher \\n\\u2022 Web camera: At least 720p or higher \\n\\u2022 Microphone: Internal microphone \\n\\u2022 SSD\\/HDD: At least 512GB internal \\nstorage or higher \\n\\u2022 OS: Licensed Windows 10 or higher \\n\\u2022 Productivity: Licensed Microsoft Office \\n(Excel, PowerPoint & Word)\",\"code\":\"15\",\"label\":\"Dealer Training Facilities and Equipment Standards\",\"description\":\"Dealers must have a dedicated computer\\/laptop within the required specification for training and other tools\\/software.\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(464, 6, 84, 'dos-38', 'Low-performing SEs based on Sales and SSI Performance are identified and given corrective measures.', 3, '{\"number\":27,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Product Presentation and Test Drive\",\"subject\":\"Sales Operation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\\nCE CENTRAL\",\"how_to_check\":\"1. Check List of low performing SEs for both Sales and SSI\\n2. Check training schedule\\n3. Check the coaching forms compiled by the SM\\/TL or Sales Trainer.\\n4. Check the latest role play records\",\"code\":\"27\",\"label\":\"Sales Operation\",\"description\":\"Low-performing SEs based on Sales and SSI Performance are identified and given corrective measures.\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(465, 6, 84, 'dos-49', 'Updated KANBAN materials of all units are available', 4, '{\"number\":28,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Product Presentation and Test Drive\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"MMPC CS TEAM\",\"how_to_check\":\"Ask SEs to present the updated hard copy of KANBAN material\",\"code\":\"28\",\"label\":\"SE Process\",\"description\":\"Updated KANBAN materials of all units are available\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(466, 6, 84, 'dos-50', 'Sales Executive knows the MMPC 6pt Walk-around Product Presentation', 5, '{\"number\":29,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Product Presentation and Test Drive\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview 2-3 SEs\\n2. Check if the SEs can correctly enumerate the 6-point walk-around\",\"code\":\"29\",\"label\":\"SE Process\",\"description\":\"Sales Executive knows the MMPC 6pt Walk-around Product Presentation\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(467, 6, 85, 'dos-11', 'MMPC greeting standard is done by all dealer staff.', 0, '{\"number\":30,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Engagement and Showroom Operations\",\"subject\":\"Greetings\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check if all dealer staff follow the standard greeting (Smile, Greet & Bow) and are consistently done.\",\"code\":\"30\",\"label\":\"Greetings\",\"description\":\"MMPC greeting standard is done by all dealer staff.\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(468, 6, 85, 'dos-12', 'Customers were escorted during the entrance and sent off with an umbrella service (if necessary).', 1, '{\"number\":31,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Engagement and Showroom Operations\",\"subject\":\"Greetings\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check through observation if the available umbrella at the dealership is either within MMPC branding or has no branding\\/logos.\",\"code\":\"31\",\"label\":\"Greetings\",\"description\":\"Customers were escorted during the entrance and sent off with an umbrella service (if necessary).\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(469, 6, 85, 'dos-21', 'Hero Car Display (new model) is displayed on a standard black platform.', 2, '{\"number\":32,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Engagement and Showroom Operations\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check if the Hero Car is compliant\",\"code\":\"32\",\"label\":\"Showroom Area\",\"description\":\"Hero Car Display (new model) is displayed on a standard black platform.\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(470, 6, 85, 'dos-22', 'Has a display car with recommended MMPC accessories', 3, '{\"number\":33,\"level\":\"Beyond\",\"category\":\"Beyond\",\"coverage\":\"Customer Engagement and Showroom Operations\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check if there is a display car is equipped with accessories\\n2. Check if the display accessories are MMPC merchandise\",\"code\":\"33\",\"label\":\"Showroom Area\",\"description\":\"Has a display car with recommended MMPC accessories\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(471, 6, 85, 'dos-30', 'Showroom and customer lounge have designated amenity corner with the required signage', 4, '{\"number\":34,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Engagement and Showroom Operations\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"CE CENTRAL\",\"how_to_check\":\"1. Check if the amenity corner signage clearly states that it is intended for customers\\n2. Check if the amenity corner signage is clearly visible.\",\"code\":\"34\",\"label\":\"Showroom Area\",\"description\":\"Showroom and customer lounge have designated amenity corner with the required signage\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(472, 6, 85, 'dos-31', 'Amenity corner has minimum of 3 beverage options available (water, juice, coffee, etc.)', 5, '{\"number\":35,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Engagement and Showroom Operations\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> follow up request for replenishment from GM\\n> BOM to replenish items\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check if the amenity corner is compliant\",\"code\":\"35\",\"label\":\"Showroom Area\",\"description\":\"Amenity corner has minimum of 3 beverage options available (water, juice, coffee, etc.)\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(473, 6, 85, 'dos-32', 'Amenity corner has available snacks (biscuits, cupcakes, candies)', 6, '{\"number\":36,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Engagement and Showroom Operations\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> follow up request for replenishment from GM\\n> BOM to replenish items\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check if the amenity corner is compliant\",\"code\":\"36\",\"label\":\"Showroom Area\",\"description\":\"Amenity corner has available snacks (biscuits, cupcakes, candies)\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(474, 6, 85, 'dos-33', 'Sales Executives proactively offer beverages, snacks, Wi-Fi access, and lounge entertainment (TV)', 7, '{\"number\":37,\"level\":\"Beyond\",\"category\":\"Beyond\",\"coverage\":\"Customer Engagement and Showroom Operations\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check if the TV is working and accessible for viewing\\n2. Check if the Wi-Fi is available and  instruction on how to connect  to the Wi-Fi is available\\n3. Check if SE is doing proactive offering\",\"code\":\"37\",\"label\":\"Showroom Area\",\"description\":\"Sales Executives proactively offer beverages, snacks, Wi-Fi access, and lounge entertainment (TV)\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(475, 6, 86, 'dos-35', 'Availability of Sales Performance Control Board with correct format /pattern and updated with corresponding progress indicator.', 0, '{\"number\":38,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Sales Operation Management\",\"subject\":\"Sales Operation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check the actual SPC board.\\n- 1 General SPC Board for Branch Head\\n- 1 for each Sales Team\\n2. Check the ff:\\n- Complete and correct data\\n- Correct Pattern\\n- With progress indicator\",\"code\":\"38\",\"label\":\"Sales Operation\",\"description\":\"Availability of Sales Performance Control Board with correct format \\/pattern and updated with corresponding progress indicator.\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(476, 6, 86, 'dos-36', 'Availability of sales activity with 2 months rolling plan, including SE duties.', 1, '{\"number\":39,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Sales Operation Management\",\"subject\":\"Sales Operation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check Sales Activity Plan\\n2. Check if it follows a two-month rolling format\\n3. Check if the plan aligns with the actual activity\",\"code\":\"39\",\"label\":\"Sales Operation\",\"description\":\"Availability of sales activity with 2 months rolling plan, including SE duties.\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(477, 6, 86, 'dos-37', 'Conduct Gap analysis', 2, '{\"number\":40,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Sales Operation Management\",\"subject\":\"Sales Operation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Check the Gap analysis of the previous month\\n2. Check the Minutes of the Meeting (MOM) of the latest monthly Team Meeting to confirm if the Gap analysis was discussed\",\"code\":\"40\",\"label\":\"Sales Operation\",\"description\":\"Conduct Gap analysis\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(478, 6, 86, 'dos-43', 'Sales Executives are well informed on the structure of SPC and  targets are cascaded.', 3, '{\"number\":41,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Sales Operation Management\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview 2-3 Ses\\n2. Ask about their understanding of the SPC structure\\n3. Ask the targets they recognize and follow\\n4. Check if their stated targets align with the actual SPC board\",\"code\":\"41\",\"label\":\"SE Process\",\"description\":\"Sales Executives are well informed on the structure of SPC and  targets are cascaded.\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(479, 6, 86, 'dos-61', 'Dealer facilitates monthly General Sales Meetings, supported by Minutes of the Meeting (MOM).', 4, '{\"number\":42,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Sales Operation Management\",\"subject\":\"Documentation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"N\\/A\",\"how_to_check\":\"1. Check the latest Minutes of the Meeting (MOM) for the General Sales Meeting from the BH\",\"code\":\"42\",\"label\":\"Documentation\",\"description\":\"Dealer facilitates monthly General Sales Meetings, supported by Minutes of the Meeting (MOM).\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(480, 6, 86, 'dos-62', 'SMs facilitates daily meetings with the SEs in front of the SPC Board, supported by  Minutes of the Meeting (MOM).', 5, '{\"number\":43,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Sales Operation Management\",\"subject\":\"Documentation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Check the latest Minutes of the Meeting (MOM) for the daily meeting from the SMs\\/TLs\",\"code\":\"43\",\"label\":\"Documentation\",\"description\":\"SMs facilitates daily meetings with the SEs in front of the SPC Board, supported by  Minutes of the Meeting (MOM).\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(481, 6, 86, 'dos-63', 'Monitoring and reporting of SSI Score Evaluation including the Voice of the Customer (VOC)', 6, '{\"number\":44,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Sales Operation Management\",\"subject\":\"Documentation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> Assigned to CE Central\",\"escalation\":\"GENERAL MANAGER\\nCE CENTRAL\",\"how_to_check\":\"1. Check the previous month\'s report:\\n- SSI score trend \\n-SSI by SE \\n-VOC (Voice of Customers)\\n2. Check the Minutes of the Meeting (MOM) from the previous month to confirm if the SSI analysis was reported during GSM.\",\"code\":\"44\",\"label\":\"Documentation\",\"description\":\"Monitoring and reporting of SSI Score Evaluation including the Voice of the Customer (VOC)\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(482, 6, 86, 'dos-76', 'Sales KPI Monitoring Sheet is up to date', 7, '{\"number\":45,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Sales Operation Management\",\"subject\":\"Monitoring\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":null,\"how_to_check\":\"1. Check if the KPI Monitoring Sheet is updated with complete details, including data from the previous month\",\"code\":\"45\",\"label\":\"Monitoring\",\"description\":\"Sales KPI Monitoring Sheet is up to date\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(483, 6, 87, 'dos-39', 'Check plan including area setting, evaluation of the area and  assigned SE', 0, '{\"number\":46,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Lead Generation and Management\",\"subject\":\"Sales Operation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"N\\/A\",\"how_to_check\":\"1. Check the availability of the area setting\\n2. Check market evaluation of the area\\n3. Check the assigned team in the area for saturation activity\\n\\nNote: Check if the activity has been properly executed\",\"code\":\"46\",\"label\":\"Sales Operation\",\"description\":\"Check plan including area setting, evaluation of the area and  assigned SE\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(484, 6, 87, 'dos-40', 'Conduct Prospect Party atleast once a year', 1, '{\"number\":47,\"level\":\"Beyond\",\"category\":\"Beyond\",\"coverage\":\"Lead Generation and Management\",\"subject\":\"Sales Operation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"MARKETING\",\"how_to_check\":\"For 1st half, check if dealer has plan to conduct Prospect Party.\\nFor 2nd half, check if dealer conducted Prospect Party. Check proof such as photo and attendance list.\",\"code\":\"47\",\"label\":\"Sales Operation\",\"description\":\"Conduct Prospect Party atleast once a year\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(485, 6, 87, 'dos-41', 'Conduct Key Opinion Leaders (KOLs) atleast once a year', 2, '{\"number\":48,\"level\":\"Beyond\",\"category\":\"Beyond\",\"coverage\":\"Lead Generation and Management\",\"subject\":\"Sales Operation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"MARKETING\",\"how_to_check\":\"For 1st half, check if dealer has plan to have KOL.\\nFor 2nd half, check if dealer conducted collaborated with KOL. Check proof such as photo and attendance list.\",\"code\":\"48\",\"label\":\"Sales Operation\",\"description\":\"Conduct Key Opinion Leaders (KOLs) atleast once a year\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(486, 6, 87, 'dos-44', 'Sales Executives understand the Source of Sales', 3, '{\"number\":49,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Lead Generation and Management\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview to 2-3 SEs\\n2. Check if SEs can identify the sources of new leads and repeat customers.\",\"code\":\"49\",\"label\":\"SE Process\",\"description\":\"Sales Executives understand the Source of Sales\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(487, 6, 87, 'dos-45', 'Sales Executives can identify the correct definition of Hot, Warm and Cold', 4, '{\"number\":50,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Lead Generation and Management\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview 2-3 SEs\\n2. Check if the definition of (Hot, Warm, Cold) is correct\",\"code\":\"50\",\"label\":\"SE Process\",\"description\":\"Sales Executives can identify the correct definition of Hot, Warm and Cold\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(488, 6, 87, 'dos-54', 'Dealers must have an official FB page following MMPC Branding and is properly maintained', 5, '{\"number\":51,\"level\":\"Beyond\",\"category\":\"Beyond\",\"coverage\":\"Lead Generation and Management\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Look for the actual Facebook page of the Dealer\\n2. Check if it follows MMPC Branding\\n3. Check who is responsible for marketing posts on the page, ideally from the Marketing Department\",\"code\":\"51\",\"label\":\"SE Process\",\"description\":\"Dealers must have an official FB page following MMPC Branding and is properly maintained\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(489, 6, 87, 'dos-55', 'Responses to online inquiries are within the standard response time.', 6, '{\"number\":52,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Lead Generation and Management\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Check the actual Facebook page of SEs\\n2. Check if the response time is within 15 minutes as per the standard\",\"code\":\"52\",\"label\":\"SE Process\",\"description\":\"Responses to online inquiries are within the standard response time.\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(490, 6, 87, 'dos-70', 'Leads Database contains customer data from the past 5 years and is being monitored', 7, '{\"number\":53,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Lead Generation and Management\",\"subject\":\"Monitoring\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"CENTRAL ADMIN\",\"how_to_check\":\"1. Check if the Leads Database is available and includes customer data from the past 5 years\\n2. Check if the database is being utilized, monitored, and updated.\\n\\nSample:\\nCurrent year = 2025 \\u2192 Extract customer database for 2019 and below\",\"code\":\"53\",\"label\":\"Monitoring\",\"description\":\"Leads Database contains customer data from the past 5 years and is being monitored\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(491, 6, 87, 'dos-71', 'Fleet Account Monitoring is available and updated', 8, '{\"number\":54,\"level\":\"Beyond\",\"category\":\"Beyond\",\"coverage\":\"Lead Generation and Management\",\"subject\":\"Monitoring\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":null,\"how_to_check\":\"1. Check if there are fleet accounts\\n2. Check if fleet monitoring exists\\n3. Check if the fleet monitoring contact plan and tracking is updated\",\"code\":\"54\",\"label\":\"Monitoring\",\"description\":\"Fleet Account Monitoring is available and updated\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(492, 6, 88, 'dos-42', 'Sales Executives wear the proper uniform (showroom duty, vehicle release, or field duty attire)', 0, '{\"number\":55,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Manpower\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"Check all SEs are in the prescribed uniform.\",\"code\":\"55\",\"label\":\"SE Process\",\"description\":\"Sales Executives wear the proper uniform (showroom duty, vehicle release, or field duty attire)\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(493, 6, 88, 'dos-87', 'All CROs are accredited following these timelines:\n*Level 1: Introductory Course -  within 1 month upon hiring\n*Level 2: Basic Sales CRO Training - within 3 to 6 months upon hiring', 1, '{\"number\":56,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Manpower\",\"subject\":\"Training\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":null,\"escalation\":\"MMPC TRAINING TEAM\",\"how_to_check\":\"1. Check the training record from Training Department\",\"code\":\"56\",\"label\":\"Training\",\"description\":\"All CROs are accredited following these timelines:\\n*Level 1: Introductory Course -  within 1 month upon hiring\\n*Level 2: Basic Sales CRO Training - within 3 to 6 months upon hiring\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(494, 6, 88, 'dos-88', 'All SEs are accredited following these timelines:\n*Level 1: Introductory Course -  within 30 days upon hiring\n*Level 2: Basic Course - within 6 months upon hiring\n*Level 3: Advanced Course   - within 1 year upon hiring', 2, '{\"number\":57,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Manpower\",\"subject\":\"Training\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"MMPC TRAINING TEAM\",\"how_to_check\":\"1. Check the training record from Training Department\",\"code\":\"57\",\"label\":\"Training\",\"description\":\"All SEs are accredited following these timelines:\\n*Level 1: Introductory Course -  within 30 days upon hiring\\n*Level 2: Basic Course - within 6 months upon hiring\\n*Level 3: Advanced Course   - within 1 year upon hiring\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(495, 6, 88, 'dos-89', 'Dealer has a designated Sales Training PIC', 3, '{\"number\":58,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Manpower\",\"subject\":\"Person-in-Charge\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"MMPC TRAINING TEAM\",\"how_to_check\":\"1. Check the training record from Training Department\",\"code\":\"58\",\"label\":\"Person-in-Charge\",\"description\":\"Dealer has a designated Sales Training PIC\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(496, 6, 88, 'dos-90', 'Sales Training Accreditation monthly report is updated by assigned dealer personnel', 4, '{\"number\":59,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Manpower\",\"subject\":\"Documentation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> submit report to distributor\",\"escalation\":\"MMPC TRAINING TEAM\",\"how_to_check\":\"1. Check if PIC submitted monthly report\",\"code\":\"59\",\"label\":\"Documentation\",\"description\":\"Sales Training Accreditation monthly report is updated by assigned dealer personnel\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(497, 6, 89, 'dos-46', 'Tagging of rating status (Hot, Warm and Cold) in the Otoleap is accurate.', 0, '{\"number\":60,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Needs Analysis\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview 2-3 SEs\\n2. Check the Otoleap of SEs\\n2. Check if the date of lead creation matches the correct tagged rating status\",\"code\":\"60\",\"label\":\"SE Process\",\"description\":\"Tagging of rating status (Hot, Warm and Cold) in the Otoleap is accurate.\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11');
INSERT INTO `checklist_items` (`id`, `checklist_template_id`, `checklist_section_id`, `key`, `prompt`, `sort_order`, `metadata`, `is_active`, `created_at`, `updated_at`) VALUES
(498, 6, 89, 'dos-47', 'Sales Executives are knowledgable on the 10 Basic Needs.', 1, '{\"number\":61,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Needs Analysis\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview 2-3 SEs\\n2. Check if the SEs can identify at least 3 items under Key Needs Item\",\"code\":\"61\",\"label\":\"SE Process\",\"description\":\"Sales Executives are knowledgable on the 10 Basic Needs.\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(499, 6, 89, 'dos-48', 'Sales Executives know the right approach for customers who owns other brands or customers who are likely to buy to other brands.', 2, '{\"number\":62,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Needs Analysis\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview 2-3 SEs\\n2. Check the approach of the SEs\",\"code\":\"62\",\"label\":\"SE Process\",\"description\":\"Sales Executives know the right approach for customers who owns other brands or customers who are likely to buy to other brands.\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(500, 6, 90, 'dos-51', 'Sales Executives are informed on the latest discount policies', 0, '{\"number\":63,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Deal and Closing Management\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview 2-3 SEs\\n2. Ask how they stay informed about the latest discount policies\\n3. Request proof, such as a group chat message or minutes of the meeting (MOM)\",\"code\":\"63\",\"label\":\"SE Process\",\"description\":\"Sales Executives are informed on the latest discount policies\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(501, 6, 90, 'dos-56', 'Sales Executive provides a formal vehicle cost computation and digital copy of an updated specification sheet', 1, '{\"number\":64,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Deal and Closing Management\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview 2-3 SEs\\n2.  Check the most recent Facebook inquiry that includes a price discussion\\n3. Check If SEs provided formal computation and updated specification sheet\",\"code\":\"64\",\"label\":\"SE Process\",\"description\":\"Sales Executive provides a formal vehicle cost computation and digital copy of an updated specification sheet\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(502, 6, 91, 'dos-52', 'Sales Executives are informed on the latest updates on banks/financial institutions', 0, '{\"number\":65,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Application Process Support\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"N\\/A\",\"how_to_check\":\"1. Interview 2-3 SEs\\n2. Ask how they stay informed about the latest updates\\n3. Request proof, such as a group chat message or minutes of the meeting (MOM)\",\"code\":\"65\",\"label\":\"SE Process\",\"description\":\"Sales Executives are informed on the latest updates on banks\\/financial institutions\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(503, 6, 91, 'dos-53', 'Sales Executive provide a list of required documents to the customers.', 1, '{\"number\":66,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Application Process Support\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview 2-3 Ses\\n2. Check the requirement list provided to the customers\",\"code\":\"66\",\"label\":\"SE Process\",\"description\":\"Sales Executive provide a list of required documents to the customers.\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(504, 6, 91, 'dos-57', 'Sales Executive informed customers of the status of their loan approvals.', 2, '{\"number\":67,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Application Process Support\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview 2-3 SEs\\n2. Check if there are on-going loan application\\n3. Check if SEs actively inform customers about their loan status by requesting proof of communication or documentation\",\"code\":\"67\",\"label\":\"SE Process\",\"description\":\"Sales Executive informed customers of the status of their loan approvals.\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(505, 6, 92, 'dos-58', 'Sales Executive informed customers of the release date and time', 0, '{\"number\":68,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Vehicle Release Management\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview 2-3 SEs\\n2. Check if SEs can provide proof of informing customers about the release date and time of their recent vehicle release\",\"code\":\"68\",\"label\":\"SE Process\",\"description\":\"Sales Executive informed customers of the release date and time\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(506, 6, 92, 'dos-59', 'The Release Ceremony was conducted', 1, '{\"number\":69,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Vehicle Release Management\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"BOM\",\"how_to_check\":\"1. Interview 2-3 SEs\\n2. Check the most recent photos of released customers Proof should have the ff:\\n- Thank you board with customer name\\n- Congratualtions Banner\",\"code\":\"69\",\"label\":\"SE Process\",\"description\":\"The Release Ceremony was conducted\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(507, 6, 92, 'dos-60', 'Have special gift/amenities for new vehicle-releasing customers.', 2, '{\"number\":70,\"level\":\"Beyond\",\"category\":\"Beyond\",\"coverage\":\"Vehicle Release Management\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview 2-3 SEs\\n2. Ask if they have special gift \\/ amenities provided for releasing customers\",\"code\":\"70\",\"label\":\"SE Process\",\"description\":\"Have special gift\\/amenities for new vehicle-releasing customers.\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(508, 6, 92, 'dos-64', 'All required documents are complete and duly signed by the customer, including:\n1. Customer Information Sheet (CIS) and DPA Form  \n2. Copy of Customer ID  \n3. MMVSO (Vehicle Sales Order)  \n4. SE Delivery Declaration Form (SDDF)\n5. New Vehicle Releasing Checklist (NVRC)  \n6. Sales Invoice (SI)  \n7. Delivery Receipt (DR)\n8. MMPC and Dealer’s copy of Warranty Certificate', 3, '{\"number\":71,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Vehicle Release Management\",\"subject\":\"Documentation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"BOM\",\"how_to_check\":\"1. Request the actual folder of release for the previous month from the Sales Admin\\/Accounting Staff; choose (3) samples.\\n2.Check if all required documents are complete and properly filled out with customer\'s signature\",\"code\":\"71\",\"label\":\"Documentation\",\"description\":\"All required documents are complete and duly signed by the customer, including:\\n1. Customer Information Sheet (CIS) and DPA Form  \\n2. Copy of Customer ID  \\n3. MMVSO (Vehicle Sales Order)  \\n4. SE Delivery Declaration Form (SDDF)\\n5. New Vehicle Releasing Checklist (NVRC)  \\n6. Sales Invoice (SI)  \\n7. Delivery Receipt (DR)\\n8. MMPC and Dealer\\u2019s copy of Warranty Certificate\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(509, 6, 92, 'dos-65', 'All customer\'s  document has digital backup', 4, '{\"number\":72,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Vehicle Release Management\",\"subject\":\"Documentation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> SM to perform doc scanning and upload in file storage.\\n> BOM to check for compliance.\",\"escalation\":\"CENTRAL ADMIN\",\"how_to_check\":\"1. Request the actual folder of release for the previous month from the Sales Admin\\/Accounting Staff; choose (3) samples.\\n2. Check if all key documents have been scanned and securely stored on a shared network or online drive and password-protected\",\"code\":\"72\",\"label\":\"Documentation\",\"description\":\"All customer\'s  document has digital backup\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(510, 6, 92, 'dos-66', 'Customer documents are stored in a dedicated folder labeled with Customer Name, Plate/CS No., and Purchase Date and all folders are stored in a locked filing cabinet.', 5, '{\"number\":73,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Vehicle Release Management\",\"subject\":\"Documentation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\\n> BOM in charge for storage and safekeep.\",\"escalation\":\"CENTRAL ADMIN\",\"how_to_check\":\"1. Check if all customer folders have proper labels and contain all necessary documents\\n2. Check if hard copies are securely stored in a locked filing cabinet.\",\"code\":\"73\",\"label\":\"Documentation\",\"description\":\"Customer documents are stored in a dedicated folder labeled with Customer Name, Plate\\/CS No., and Purchase Date and all folders are stored in a locked filing cabinet.\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(511, 6, 92, 'dos-67', 'The time duration recorded in the New Vehicle Releasing Checklist is within the standard 2-hour releasing', 6, '{\"number\":74,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Vehicle Release Management\",\"subject\":\"Vehicle Delivery\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> recommend compliance plan\\n> consult with support teams\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Request the actual folder of release for the previous month from the Sales Admin\\/Accounting Staff; choose (3) samples.\\n2. Check NVRC attachment: \\\"Arrival Time\\\" and \\\"Departure Time\\\" should be within 2hrs for Cash \\/ PO Transaction\",\"code\":\"74\",\"label\":\"Vehicle Delivery\",\"description\":\"The time duration recorded in the New Vehicle Releasing Checklist is within the standard 2-hour releasing\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(512, 6, 92, 'dos-68', 'Release area is clean and with good atmosphere', 7, '{\"number\":75,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Vehicle Release Management\",\"subject\":\"Vehicle Delivery\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> Remind utility personnel of daily 5S task.\",\"escalation\":\"BOM\",\"how_to_check\":\"1. Check the actual release area\\n2. Check if there are no vehicles parked in the release area aside from \\\"for release\\\" unit\\/s\",\"code\":\"75\",\"label\":\"Vehicle Delivery\",\"description\":\"Release area is clean and with good atmosphere\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(513, 6, 92, 'dos-69', 'Releasing Area is inside the showroom', 8, '{\"number\":76,\"level\":\"Beyond\",\"category\":\"Beyond\",\"coverage\":\"Vehicle Release Management\",\"subject\":\"Vehicle Delivery\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":null,\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"Check if the vehicle releasing area is located inside the showroom\",\"code\":\"76\",\"label\":\"Vehicle Delivery\",\"description\":\"Releasing Area is inside the showroom\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(514, 6, 92, 'dos-72', 'PDI is done 3 days prior to customer release', 9, '{\"number\":77,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Vehicle Release Management\",\"subject\":\"Monitoring\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> system based release timing\",\"escalation\":\"LOGISTIC\",\"how_to_check\":\"1. Check the Daily Release Monitoring\\n2. Check if the date in the PDI column is 3 days prior to delivery date\",\"code\":\"77\",\"label\":\"Monitoring\",\"description\":\"PDI is done 3 days prior to customer release\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(515, 6, 92, 'dos-73', 'Daily Release Monitoring is being utilized.', 10, '{\"number\":78,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Vehicle Release Management\",\"subject\":\"Monitoring\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> system based release monitoring\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Check if all releases for the day are recorded on the Daily Release Monitoring\\n2. Check the current status of the vehicle vs. the monitoring sheet\\n\\nNote: If no release for the day, check the scheduled release for the next 2 days.\",\"code\":\"78\",\"label\":\"Monitoring\",\"description\":\"Daily Release Monitoring is being utilized.\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(516, 6, 93, 'dos-74', 'Birthday/Anniversary Message Greeting was sent to customers with proper monitoring and tracking', 0, '{\"number\":79,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Post-Release Customer Management\",\"subject\":\"Monitoring\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> Assigned to CE Central\",\"escalation\":\"CE CENTRAL\",\"how_to_check\":\"1. Check photo or message of sending Birthday and Anniversary Greetings\\n2. Check if the monitoring is updated\",\"code\":\"79\",\"label\":\"Monitoring\",\"description\":\"Birthday\\/Anniversary Message Greeting was sent to customers with proper monitoring and tracking\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(517, 6, 93, 'dos-75', 'Sales CROs have their monitoring file for valid complaints and negative feedback', 1, '{\"number\":80,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Post-Release Customer Management\",\"subject\":\"Monitoring\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":null,\"escalation\":\"CE CENTRAL\",\"how_to_check\":\"1. Check if there are valid red alert items\\n2. Check if the valid Red Alert items are recorded in the complaint monitoring file\\n3. Check if the monitoring file is updated\\n4. Check if the monitoring file was submitted to MMPC on time by reviewing the submission date\",\"code\":\"80\",\"label\":\"Monitoring\",\"description\":\"Sales CROs have their monitoring file for valid complaints and negative feedback\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(518, 6, 93, 'dos-81', 'All red alerts are reflected on the Complaint Tracker Monitoring', 2, '{\"number\":81,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Post-Release Customer Management\",\"subject\":\"Quick VOC System\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":null,\"escalation\":\"CE CENTRAL\",\"how_to_check\":\"1. All red alerts received should be reflected on the Complaint Tracker Monitoring\",\"code\":\"81\",\"label\":\"Quick VOC System\",\"description\":\"All red alerts are reflected on the Complaint Tracker Monitoring\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(519, 6, 94, 'dos-77', 'New release vehicle is updated in YANA NVDO within 2 business days', 0, '{\"number\":82,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Systems\",\"subject\":\"YANA\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\",\"escalation\":\"CENTRAL ADMIN\",\"how_to_check\":\"1. Access the YANA and select New Vehicle > Delivery\\n2. Extract all data with a Delivery Date exactly three business days from the actual visit\\n3. Check if the \\\"Created On\\\" date falls within two business days of the Delivery Date\",\"code\":\"82\",\"label\":\"YANA\",\"description\":\"New release vehicle is updated in YANA NVDO within 2 business days\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(520, 6, 94, 'dos-78', 'Sales has an access to Sales Information Portal', 1, '{\"number\":83,\"level\":\"Beyond\",\"category\":\"Beyond\",\"coverage\":\"Systems\",\"subject\":\"Sales Information Portal (SIP)\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":null,\"escalation\":\"MMPC CS TEAM\",\"how_to_check\":\"1. Based on the monitoring list of those with SIP access, request them to open and navigate the system.\\n2. Check if the sales staff are aware of other members who have access to SIP\",\"code\":\"83\",\"label\":\"Sales Information Portal (SIP)\",\"description\":\"Sales has an access to Sales Information Portal\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(521, 6, 94, 'dos-79', 'Manpower report is updated monthly by assigned SEIS officer-in-charge', 2, '{\"number\":84,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Systems\",\"subject\":\"Sales Executive Information System (SEIS)\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> follow up with SMs\\n> Monitor progress until compliant.\\n> BOM submit to Central Admin\",\"escalation\":\"MMPC TRAINING TEAM\",\"how_to_check\":\"1. Check if PIC submitted monthly manpower report\",\"code\":\"84\",\"label\":\"Sales Executive Information System (SEIS)\",\"description\":\"Manpower report is updated monthly by assigned SEIS officer-in-charge\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(522, 6, 94, 'dos-80', 'Manpower report (based on latest submission) is matched on the actual personnel count in the dealership', 3, '{\"number\":85,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Systems\",\"subject\":\"Sales Executive Information System (SEIS)\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> actual count, manpower report versus warm bodies.\",\"escalation\":\"MMPC TRAINING TEAM\",\"how_to_check\":\"1. Check actual manpower list in the dealership\",\"code\":\"85\",\"label\":\"Sales Executive Information System (SEIS)\",\"description\":\"Manpower report (based on latest submission) is matched on the actual personnel count in the dealership\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(523, 6, 95, 'dos-82', 'Report shall be sent on or before 5pm of the set deadline.', 0, '{\"number\":86,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Mandatory Reports\",\"subject\":\"GVD Report\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":null,\"escalation\":\"CENTRAL ADMIN\",\"how_to_check\":\"Check actual through respective FSM for the accomplishment\",\"code\":\"86\",\"label\":\"GVD Report\",\"description\":\"Report shall be sent on or before 5pm of the set deadline.\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(524, 6, 95, 'dos-83', '100% accuracy of the reports; shall be sent 2 working days after closing date.', 1, '{\"number\":87,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Mandatory Reports\",\"subject\":\"Gross Sales and Actual Dealer Inventory Reports\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> submit to Central Admin\",\"escalation\":\"CENTRAL ADMIN\",\"how_to_check\":\"Check actual through respective FSM for the accomplishment\",\"code\":\"87\",\"label\":\"Gross Sales and Actual Dealer Inventory Reports\",\"description\":\"100% accuracy of the reports; shall be sent 2 working days after closing date.\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(525, 6, 95, 'dos-84', 'Report shall be sent 2 working days after closing date.', 2, '{\"number\":88,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Mandatory Reports\",\"subject\":\"Customer Waiting List\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> submit to Central Admin\",\"escalation\":\"CENTRAL ADMIN\",\"how_to_check\":\"Check actual through respective FSM for the accomplishment\",\"code\":\"88\",\"label\":\"Customer Waiting List\",\"description\":\"Report shall be sent 2 working days after closing date.\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(526, 6, 95, 'dos-85', 'Report shall be sent 3 working days after closing Date', 3, '{\"number\":89,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Mandatory Reports\",\"subject\":\"BH Finance Report\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":null,\"escalation\":\"CENTRAL ADMIN\",\"how_to_check\":\"Check actual through respective FSM for the accomplishment\",\"code\":\"89\",\"label\":\"BH Finance Report\",\"description\":\"Report shall be sent 3 working days after closing Date\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(527, 6, 95, 'dos-86', 'Timeliness and accuracy of submitted billing documents and Subsidy Claim Requirements (please refer to monthly email advice and circular for the complete mechanics of the said documents)', 4, '{\"number\":90,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Mandatory Reports\",\"subject\":\"Billing Documents and Subsidy Claims\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> Assigned to Central Admin\",\"escalation\":\"CENTRAL ADMIN\",\"how_to_check\":\"Check actual through Sales Control for the accomplishment\",\"code\":\"90\",\"label\":\"Billing Documents and Subsidy Claims\",\"description\":\"Timeliness and accuracy of submitted billing documents and Subsidy Claim Requirements (please refer to monthly email advice and circular for the complete mechanics of the said documents)\",\"responsible_role\":\"GM\"}', 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(528, 3, 96, 'restroom-item-1', 'All are working', 0, '{\"number\":1,\"response_type\":\"time_slots\",\"subject\":\"Lighting\",\"code\":\"1\",\"label\":\"Lighting\",\"description\":\"All are working\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null,\"active_slots\":[\"09:00\",\"10:00\",\"11:00\",\"13:00\",\"14:00\",\"16:00\",\"17:00\",\"08:00\",\"15:00\"]}', 1, '2026-09-08 01:24:19', '2026-09-10 23:34:10'),
(529, 3, 96, 'restroom-item-2', 'Light switch are working', 1, '{\"number\":2,\"response_type\":\"time_slots\",\"subject\":\"Lighting\",\"code\":\"2\",\"label\":\"Lighting\",\"description\":\"Light switch are working\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:06:01'),
(530, 3, 97, 'restroom-item-3', 'All exhaust fans are working', 0, '{\"number\":3,\"response_type\":\"time_slots\",\"subject\":\"Exhaust\",\"code\":\"3\",\"label\":\"Exhaust\",\"description\":\"All exhaust fans are working\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(531, 3, 97, 'restroom-item-4', 'All exhaust fans are clean', 1, '{\"number\":4,\"response_type\":\"time_slots\",\"subject\":\"Exhaust\",\"code\":\"4\",\"label\":\"Exhaust\",\"description\":\"All exhaust fans are clean\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(532, 3, 97, 'restroom-item-5', 'No foul smell is present', 2, '{\"number\":5,\"response_type\":\"time_slots\",\"subject\":\"Exhaust\",\"code\":\"5\",\"label\":\"Exhaust\",\"description\":\"No foul smell is present\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(533, 3, 98, 'restroom-item-6', 'All are clean', 0, '{\"number\":6,\"response_type\":\"time_slots\",\"subject\":\"Floor, Wall & Ceiling\",\"code\":\"6\",\"label\":\"Floor, Wall & Ceiling\",\"description\":\"All are clean\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(534, 3, 98, 'restroom-item-7', 'Tiles are complete and no cracks', 1, '{\"number\":7,\"response_type\":\"time_slots\",\"subject\":\"Floor, Wall & Ceiling\",\"code\":\"7\",\"label\":\"Floor, Wall & Ceiling\",\"description\":\"Tiles are complete and no cracks\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(535, 3, 98, 'restroom-item-8', 'Floor drain is working', 2, '{\"number\":8,\"response_type\":\"time_slots\",\"subject\":\"Floor, Wall & Ceiling\",\"code\":\"8\",\"label\":\"Floor, Wall & Ceiling\",\"description\":\"Floor drain is working\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(536, 3, 99, 'restroom-item-9', 'All are clean', 0, '{\"number\":9,\"response_type\":\"time_slots\",\"subject\":\"Toilet Bowl\",\"code\":\"9\",\"label\":\"Toilet Bowl\",\"description\":\"All are clean\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(537, 3, 99, 'restroom-item-10', 'Flush is working properly', 1, '{\"number\":10,\"response_type\":\"time_slots\",\"subject\":\"Toilet Bowl\",\"code\":\"10\",\"label\":\"Toilet Bowl\",\"description\":\"Flush is working properly\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(538, 3, 99, 'restroom-item-11', 'Bidet is working properly', 2, '{\"number\":11,\"response_type\":\"time_slots\",\"subject\":\"Toilet Bowl\",\"code\":\"11\",\"label\":\"Toilet Bowl\",\"description\":\"Bidet is working properly\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(539, 3, 99, 'restroom-item-12', 'No water leak', 3, '{\"number\":12,\"response_type\":\"time_slots\",\"subject\":\"Toilet Bowl\",\"code\":\"12\",\"label\":\"Toilet Bowl\",\"description\":\"No water leak\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(540, 3, 100, 'restroom-item-13', 'All are clean', 0, '{\"number\":13,\"response_type\":\"time_slots\",\"subject\":\"Urinal\",\"code\":\"13\",\"label\":\"Urinal\",\"description\":\"All are clean\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(541, 3, 100, 'restroom-item-14', 'Flush is working properly', 1, '{\"number\":14,\"response_type\":\"time_slots\",\"subject\":\"Urinal\",\"code\":\"14\",\"label\":\"Urinal\",\"description\":\"Flush is working properly\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(542, 3, 100, 'restroom-item-15', 'No water leak', 2, '{\"number\":15,\"response_type\":\"time_slots\",\"subject\":\"Urinal\",\"code\":\"15\",\"label\":\"Urinal\",\"description\":\"No water leak\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(543, 3, 101, 'restroom-item-16', 'All are clean', 0, '{\"number\":16,\"response_type\":\"time_slots\",\"subject\":\"Sink and faucet\",\"code\":\"16\",\"label\":\"Sink and faucet\",\"description\":\"All are clean\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(544, 3, 101, 'restroom-item-17', 'Faucet is working properly', 1, '{\"number\":17,\"response_type\":\"time_slots\",\"subject\":\"Sink and faucet\",\"code\":\"17\",\"label\":\"Sink and faucet\",\"description\":\"Faucet is working properly\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(545, 3, 101, 'restroom-item-18', 'Drain is working properly', 2, '{\"number\":18,\"response_type\":\"time_slots\",\"subject\":\"Sink and faucet\",\"code\":\"18\",\"label\":\"Sink and faucet\",\"description\":\"Drain is working properly\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(546, 3, 101, 'restroom-item-19', 'No water leak', 3, '{\"number\":19,\"response_type\":\"time_slots\",\"subject\":\"Sink and faucet\",\"code\":\"19\",\"label\":\"Sink and faucet\",\"description\":\"No water leak\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(547, 3, 102, 'restroom-item-20', 'Toilet tissue is available', 0, '{\"number\":20,\"response_type\":\"time_slots\",\"subject\":\"Toilet Accessories\",\"code\":\"20\",\"label\":\"Toilet Accessories\",\"description\":\"Toilet tissue is available\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(548, 3, 102, 'restroom-item-21', 'Toilet tissue holder is available', 1, '{\"number\":21,\"response_type\":\"time_slots\",\"subject\":\"Toilet Accessories\",\"code\":\"21\",\"label\":\"Toilet Accessories\",\"description\":\"Toilet tissue holder is available\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(549, 3, 102, 'restroom-item-22', 'Liquid Soap is available', 2, '{\"number\":22,\"response_type\":\"time_slots\",\"subject\":\"Toilet Accessories\",\"code\":\"22\",\"label\":\"Toilet Accessories\",\"description\":\"Liquid Soap is available\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(550, 3, 102, 'restroom-item-23', 'Liquid Soap Dispenser is available', 3, '{\"number\":23,\"response_type\":\"time_slots\",\"subject\":\"Toilet Accessories\",\"code\":\"23\",\"label\":\"Toilet Accessories\",\"description\":\"Liquid Soap Dispenser is available\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(551, 3, 102, 'restroom-item-24', 'Hand  Drier is working', 4, '{\"number\":24,\"response_type\":\"time_slots\",\"subject\":\"Toilet Accessories\",\"code\":\"24\",\"label\":\"Toilet Accessories\",\"description\":\"Hand  Drier is working\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(552, 3, 102, 'restroom-item-25', 'Mirror is clean', 5, '{\"number\":25,\"response_type\":\"time_slots\",\"subject\":\"Toilet Accessories\",\"code\":\"25\",\"label\":\"Toilet Accessories\",\"description\":\"Mirror is clean\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(553, 3, 102, 'restroom-item-26', 'Mirror has no damage', 6, '{\"number\":26,\"response_type\":\"time_slots\",\"subject\":\"Toilet Accessories\",\"code\":\"26\",\"label\":\"Toilet Accessories\",\"description\":\"Mirror has no damage\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(554, 3, 103, 'restroom-item-27', 'All are clean', 0, '{\"number\":27,\"response_type\":\"time_slots\",\"subject\":\"Trash Bin\",\"code\":\"27\",\"label\":\"Trash Bin\",\"description\":\"All are clean\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(555, 3, 103, 'restroom-item-28', 'All bin with trash bag', 1, '{\"number\":28,\"response_type\":\"time_slots\",\"subject\":\"Trash Bin\",\"code\":\"28\",\"label\":\"Trash Bin\",\"description\":\"All bin with trash bag\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(556, 3, 104, 'restroom-item-29', 'Water pressure is ok', 0, '{\"number\":29,\"response_type\":\"time_slots\",\"subject\":\"Water Supply\",\"code\":\"29\",\"label\":\"Water Supply\",\"description\":\"Water pressure is ok\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(557, 3, 105, 'restroom-item-30', 'Are stored properly', 0, '{\"number\":30,\"response_type\":\"time_slots\",\"subject\":\"Cleaning Materials\",\"code\":\"30\",\"label\":\"Cleaning Materials\",\"description\":\"Are stored properly\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":null,\"category\":null}', 1, '2026-09-08 01:24:19', '2026-09-10 22:58:39'),
(558, 3, 96, 'item-1789106735237-2', 'Pundido', 2, '{\"code\":\"3\",\"number\":3,\"label\":\"Lighting\",\"subject\":\"Lighting\",\"description\":\"Pundido\",\"level\":null,\"responsible_role\":\"5S_UTILITIES\",\"pic\":\"5S_UTILITIES\",\"how_to_check\":\"yyeye\",\"category\":null,\"deleted\":true}', 0, '2026-09-10 22:06:01', '2026-09-10 22:58:39'),
(559, 4, 32, 'item-42', 'Are they wearing the prescribed uniform and ID badge?', 0, '{\"number\":42}', 1, '2026-09-10 23:50:03', '2026-09-10 23:50:03'),
(560, 4, 32, 'item-43', 'Are they well-groomed and dressed in the proper uniform?', 1, '{\"number\":43}', 1, '2026-09-10 23:50:03', '2026-09-10 23:50:03'),
(561, 4, 32, 'item-44', 'Do they have the Sales Kit, including the pricelist, business cards, and bank application form?', 2, '{\"number\":44}', 1, '2026-09-10 23:50:03', '2026-09-10 23:50:03');

-- --------------------------------------------------------

--
-- Table structure for table `checklist_responses`
--

CREATE TABLE `checklist_responses` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `checklist_submission_id` bigint(20) UNSIGNED NOT NULL,
  `checklist_item_id` bigint(20) UNSIGNED DEFAULT NULL,
  `item_key` varchar(100) NOT NULL,
  `status` varchar(20) DEFAULT NULL,
  `remark` text DEFAULT NULL,
  `finding` text DEFAULT NULL,
  `action_plan` text DEFAULT NULL,
  `escalation_target` varchar(50) DEFAULT NULL,
  `commitment_date` datetime DEFAULT NULL,
  `details` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`details`)),
  `attachment_path` varchar(500) DEFAULT NULL,
  `item_snapshot` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`item_snapshot`)),
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `checklist_sections`
--

CREATE TABLE `checklist_sections` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `checklist_template_id` bigint(20) UNSIGNED NOT NULL,
  `key` varchar(100) NOT NULL,
  `title` varchar(255) NOT NULL,
  `sort_order` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `checklist_sections`
--

INSERT INTO `checklist_sections` (`id`, `checklist_template_id`, `key`, `title`, `sort_order`, `metadata`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 1, 'parking-area', 'Parking Area', 0, NULL, 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(2, 1, 'showroom-sales-negotiation-area', 'Showroom / Sales Negotiation Area', 1, NULL, 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(3, 1, 'sales-reception-area', 'Sales Reception Area', 2, NULL, 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(4, 1, 'vehicles-display', 'Vehicles Display', 3, NULL, 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(5, 1, 'service-reception', 'Service Reception', 4, NULL, 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(6, 1, 'service-working-bay', 'Service Working Bay', 5, NULL, 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(7, 1, 'restrooms', 'Restrooms', 6, NULL, 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(8, 1, 'customer-lounge', 'Customer Lounge', 7, NULL, 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(9, 1, 'sales-executives-on-showroom-duty', 'Sales Executives on Showroom Duty', 8, NULL, 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(26, 4, 'parking-area', 'Parking Area', 0, NULL, 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(27, 4, 'showroom-sales-negotiation-area', 'Showroom / Sales Negotiation Area', 1, NULL, 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(28, 4, 'sales-reception-area', 'Sales Reception Area', 2, NULL, 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(29, 4, 'vehicles-display', 'Vehicles Display', 4, NULL, 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(30, 4, 'restrooms', 'Restrooms', 5, NULL, 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(31, 4, 'customer-lounge', 'Customer Lounge', 6, NULL, 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(32, 4, 'sales-executives-on-showroom-duty', 'Sales Executives on Showroom Duty', 7, NULL, 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(33, 5, 'parking-area', 'Parking Area', 0, NULL, 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(34, 5, 'service-reception', 'Service Reception', 1, NULL, 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(35, 5, 'service-working-bay', 'Service Working Bay', 2, NULL, 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(36, 5, 'restrooms', 'Restrooms', 3, NULL, 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(37, 5, 'customer-lounge', 'Customer Lounge', 4, NULL, 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(38, 5, 'frontliners', 'Frontliners', 5, NULL, 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(60, 2, 'dos-as-manpower', 'Manpower', 1, '{\"code\":\"dos-as-manpower\"}', 1, '2026-09-05 08:08:23', '2026-09-05 08:08:23'),
(61, 2, 'dos-as-pro-active-customer-contact', 'Pro-active Customer Contact', 2, '{\"code\":\"dos-as-pro-active-customer-contact\"}', 1, '2026-09-05 08:08:23', '2026-09-05 08:08:23'),
(62, 2, 'dos-as-customer-appointment', 'Customer Appointment', 3, '{\"code\":\"dos-as-customer-appointment\"}', 1, '2026-09-05 08:08:23', '2026-09-05 08:08:23'),
(63, 2, 'dos-as-systems', 'Systems', 4, '{\"code\":\"dos-as-systems\"}', 1, '2026-09-05 08:08:23', '2026-09-05 08:08:23'),
(64, 2, 'dos-as-facilities', 'Facilities', 5, '{\"code\":\"dos-as-facilities\"}', 1, '2026-09-05 08:08:23', '2026-09-05 08:08:23'),
(65, 2, 'dos-as-personalized-customer-reception', 'Personalized Customer Reception', 6, '{\"code\":\"dos-as-personalized-customer-reception\"}', 1, '2026-09-05 08:08:23', '2026-09-05 08:08:23'),
(66, 2, 'dos-as-menu-pricing-commitment-of-price-and-time-delivery', 'Menu Pricing / Commitment of Price and Time Delivery', 7, '{\"code\":\"dos-as-menu-pricing-commitment-of-price-and-time-delivery\"}', 1, '2026-09-05 08:08:23', '2026-09-05 08:08:23'),
(67, 2, 'dos-as-customer-care-and-communication', 'Customer Care and Communication', 8, '{\"code\":\"dos-as-customer-care-and-communication\"}', 1, '2026-09-05 08:08:23', '2026-09-05 08:08:23'),
(68, 2, 'dos-as-workshop-scheduling', 'Workshop Scheduling', 9, '{\"code\":\"dos-as-workshop-scheduling\"}', 1, '2026-09-05 08:08:23', '2026-09-05 08:08:23'),
(69, 2, 'dos-as-advance-info-to-parts-store', 'Advance Info to Parts Store', 10, '{\"code\":\"dos-as-advance-info-to-parts-store\"}', 1, '2026-09-05 08:08:23', '2026-09-05 08:08:23'),
(70, 2, 'dos-as-repair-order-processing-and-quality-of-work', 'Repair Order Processing and Quality of Work', 11, '{\"code\":\"dos-as-repair-order-processing-and-quality-of-work\"}', 1, '2026-09-05 08:08:23', '2026-09-05 08:08:23'),
(71, 2, 'dos-as-repair-order-completion-and-invoicing', 'Repair Order Completion and Invoicing', 12, '{\"code\":\"dos-as-repair-order-completion-and-invoicing\"}', 1, '2026-09-05 08:08:23', '2026-09-05 08:08:23'),
(72, 2, 'dos-as-customer-information-and-car-return', 'Customer Information and Car Return', 13, '{\"code\":\"dos-as-customer-information-and-car-return\"}', 1, '2026-09-05 08:08:23', '2026-09-05 08:08:23'),
(73, 2, 'dos-as-customer-after-service-contact', 'Customer After Service Contact', 14, '{\"code\":\"dos-as-customer-after-service-contact\"}', 1, '2026-09-05 08:08:23', '2026-09-05 08:08:23'),
(74, 2, 'dos-as-concern-prevention-and-resolution', 'Concern Prevention and Resolution', 15, '{\"code\":\"dos-as-concern-prevention-and-resolution\"}', 1, '2026-09-05 08:08:23', '2026-09-05 08:08:23'),
(75, 7, 'subform-service-reception', 'Service Reception c/o CE', 0, '{\"code\":\"subform-service-reception\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(76, 7, 'subform-employee-facilities', 'Employee Facilities c/o WS/Foreman/Leadman', 1, '{\"code\":\"subform-employee-facilities\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(77, 7, 'subform-meeting-room', 'Meeting Room c/o ASM', 2, '{\"code\":\"subform-meeting-room\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(78, 7, 'subform-mitsubishi-quick-service', 'Mitsubishi Quick Service (MQS) c/o WS', 3, '{\"code\":\"subform-mitsubishi-quick-service\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(79, 7, 'subform-customers-lounge', 'Customer\'s Lounge c/o CE', 4, '{\"code\":\"subform-customers-lounge\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(80, 8, 'doc-rationalized-checksheet', 'Rationalized Checksheet', 0, '{\"code\":\"doc-rationalized-checksheet\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(81, 8, 'doc-repair-order', 'Repair Order', 1, '{\"code\":\"doc-repair-order\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(82, 8, 'doc-service-invoice', 'Service Invoice', 2, '{\"code\":\"doc-service-invoice\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(83, 6, 'sales-coverage-1', 'Facilities', 0, NULL, 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(84, 6, 'sales-coverage-2', 'Product Presentation and Test Drive', 1, NULL, 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(85, 6, 'sales-coverage-3', 'Customer Engagement and Showroom Operations', 2, NULL, 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(86, 6, 'sales-coverage-4', 'Sales Operation Management', 3, NULL, 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(87, 6, 'sales-coverage-5', 'Lead Generation and Management', 4, NULL, 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(88, 6, 'sales-coverage-6', 'Manpower', 5, NULL, 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(89, 6, 'sales-coverage-7', 'Needs Analysis', 6, NULL, 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(90, 6, 'sales-coverage-8', 'Deal and Closing Management', 7, NULL, 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(91, 6, 'sales-coverage-9', 'Application Process Support', 8, NULL, 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(92, 6, 'sales-coverage-10', 'Vehicle Release Management', 9, NULL, 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(93, 6, 'sales-coverage-11', 'Post-Release Customer Management', 10, NULL, 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(94, 6, 'sales-coverage-12', 'Systems', 11, NULL, 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(95, 6, 'sales-coverage-13', 'Mandatory Reports', 12, NULL, 1, '2026-09-07 02:38:51', '2026-09-12 01:07:11'),
(96, 3, 'restroom-lighting', 'Lighting', 0, NULL, 1, '2026-09-08 01:24:19', '2026-09-08 01:24:19'),
(97, 3, 'restroom-exhaust', 'Exhaust', 1, NULL, 1, '2026-09-08 01:24:19', '2026-09-08 01:24:19'),
(98, 3, 'restroom-floor-wall-ceiling', 'Floor, Wall & Ceiling', 2, NULL, 1, '2026-09-08 01:24:19', '2026-09-08 01:24:19'),
(99, 3, 'restroom-toilet-bowl', 'Toilet Bowl', 3, NULL, 1, '2026-09-08 01:24:19', '2026-09-08 01:24:19'),
(100, 3, 'restroom-urinal', 'Urinal', 4, NULL, 1, '2026-09-08 01:24:19', '2026-09-08 01:24:19'),
(101, 3, 'restroom-sink-and-faucet', 'Sink and faucet', 5, NULL, 1, '2026-09-08 01:24:19', '2026-09-08 01:24:19'),
(102, 3, 'restroom-toilet-accessories', 'Toilet Accessories', 6, NULL, 1, '2026-09-08 01:24:19', '2026-09-08 01:24:19'),
(103, 3, 'restroom-trash-bin', 'Trash Bin', 7, NULL, 1, '2026-09-08 01:24:19', '2026-09-08 01:24:19'),
(104, 3, 'restroom-water-supply', 'Water Supply', 8, NULL, 1, '2026-09-08 01:24:19', '2026-09-08 01:24:19'),
(105, 3, 'restroom-cleaning-materials', 'Cleaning Materials', 9, NULL, 1, '2026-09-08 01:24:19', '2026-09-08 01:24:19'),
(106, 4, 'test-drive-vehicle', 'Test Drive Vehicle', 3, NULL, 1, '2026-09-10 23:50:03', '2026-09-10 23:50:03');

-- --------------------------------------------------------

--
-- Table structure for table `checklist_submissions`
--

CREATE TABLE `checklist_submissions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `checklist_template_id` bigint(20) UNSIGNED DEFAULT NULL,
  `branch_restroom_id` bigint(20) UNSIGNED DEFAULT NULL,
  `restroom_area` varchar(255) DEFAULT NULL,
  `restroom_gender` varchar(255) DEFAULT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `submitted_by_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `submitted_by_name` varchar(255) DEFAULT NULL,
  `submitted_by_email` varchar(255) DEFAULT NULL,
  `submitted_by_user_type` varchar(100) DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'draft',
  `branch` varchar(255) DEFAULT NULL,
  `scope_key` varchar(64) NOT NULL,
  `audit_date` date NOT NULL,
  `template_version` int(10) UNSIGNED NOT NULL,
  `context` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`context`)),
  `template_snapshot` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`template_snapshot`)),
  `scores` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`scores`)),
  `submitted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `checklist_templates`
--

CREATE TABLE `checklist_templates` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `slug` varchar(100) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `version` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `settings` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`settings`)),
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `checklist_templates`
--

INSERT INTO `checklist_templates` (`id`, `slug`, `name`, `description`, `version`, `settings`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'gateway-5s', 'Gateway Sales and Service 5S Checklist', 'Legacy combined Sales and Service 5S audit retained for existing records and mobile clients.', 1, '{\"validation_mode\":\"yes_no_na\",\"response_options\":[\"yes\",\"no\",\"na\"],\"instructions\":\"Complete every item before business hours. A remark is required for NO and N/A.\",\"schedule\":{\"start\":\"08:00\",\"end\":\"08:30\"},\"source\":\"Gateway 5S Checklist.xlsx / Combined Sales and Service\",\"workspace_hidden\":true}', 1, '2026-08-21 23:21:21', '2026-08-28 22:40:08'),
(2, 'dealer-operations-standards', 'Dealer Operations Standards - Aftersales', 'FY2025 Aftersales Standards Compliance Audit Sheet (75 Standards)', 2, '{\"validation_mode\":\"dos\",\"response_options\":[\"yes\",\"no\",\"na\"],\"instructions\":\"Judge every standard. NO requires a finding; N\\/A requires a reason.\",\"scoring\":{\"basic_required_percentage\":100,\"standard_required_percentage\":80,\"overall_required_percentage\":80},\"source\":\"FY25 Aftersales Standards Compliance Audit Sheet_updated as 08262026.xlsx\",\"short_name\":\"DOS Aftersales\",\"time_slots\":[]}', 1, '2026-08-21 23:21:21', '2026-09-07 21:30:17'),
(3, 'restroom', 'Restroom Checklist', 'Restroom condition and orderliness inspection at 8 AM, 11 AM, 1 PM, and 4 PM.', 5, '{\"validation_mode\":\"time_slots\",\"instructions\":\"Mark each hourly inspection as Yes or No, and add a row remark when needed.\",\"time_slots\":[{\"key\":\"08:00\",\"label\":\"8 AM\"},{\"key\":\"11:00\",\"label\":\"11 AM\"},{\"key\":\"13:00\",\"label\":\"1 PM\"},{\"key\":\"16:00\",\"label\":\"4 PM\"}],\"legend\":{\"good\":\"\\/\",\"not_good\":\"X\"},\"remark_per_item\":true,\"source\":\"Gateway 5S Checklist_2.xlsx \\/ Restroom - Utility\",\"short_name\":null}', 1, '2026-08-21 23:21:21', '2026-09-24 02:46:56'),
(4, 'sales', 'Sales Checklist', 'Daily Sales showroom, reception, vehicle-display, and customer-readiness audit.', 1, '{\"validation_mode\":\"yes_no_na\",\"response_options\":[\"yes\",\"no\",\"na\"],\"instructions\":\"Pre-Business Hours Checklist Instructions:\\nThe Sales Officer-in-Charge of the day (GRM) is required to complete this checklist before the start of business hours.\\nThe Branch Operations Officer is responsible for overseeing the showroom and ensuring the checklist is accurately and regularly completed each day.\",\"schedule\":{\"start\":\"08:00\",\"end\":\"08:30\"},\"source\":\"Gateway 5S Checklist_2.xlsx \\/ Sales\",\"workspace_order\":20,\"performed_by\":\"Sales Officer of the Day\"}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(5, 'service', 'Service Checklist', 'Daily Service reception, working-bay, and customer-readiness audit.', 1, '{\"validation_mode\":\"yes_no_na\",\"response_options\":[\"yes\",\"no\",\"na\"],\"instructions\":\"Pre-Business Hours Checklist Instructions:\\nThe Service Officer-in-Charge of the day(CE & Workshop Sup\\/Leadman\\/Foreman) is required to complete this checklist before the start of business hours.\\nThe Branch Operations Manager is responsible for overseeing the service facility and ensuring the checklist is accurately and regularly completed each day.\",\"schedule\":{\"start\":\"08:00\",\"end\":\"08:30\"},\"source\":\"Gateway 5S Checklist_2.xlsx \\/ Service\",\"workspace_order\":30,\"performed_by\":\"Service Officer of the Day\"}', 1, '2026-08-28 22:40:08', '2026-09-10 23:50:03'),
(6, 'dealer-operations-standards-sales', 'Dealer Operations Standards - Sales', 'FY2025 Sales Standards Compliance Audit Main Form (90 Standards)', 3, '{\"validation_mode\":\"dos\",\"response_options\":[\"yes\",\"no\",\"na\"],\"instructions\":\"Judge every standard. NO requires a finding; N\\/A requires a reason.\",\"scoring\":{\"basic_required_percentage\":100,\"standard_required_percentage\":80,\"overall_required_percentage\":80},\"source\":\"FY25 Sales Standards Compliance Audit Sheet (REV02)_1.xlsx\",\"short_name\":\"DOS Sales\",\"time_slots\":[]}', 1, '2026-09-05 08:07:55', '2026-09-12 01:12:23'),
(7, 'dealer-operations-standards-subform', 'Dealer Operations Standards - Subform', 'FY2025 Aftersales Standards Compliance Audit Subform (39 Standards).', 1, '{\"validation_mode\":\"dos_subform\",\"response_options\":[\"yes\",\"no\",\"na\"],\"instructions\":\"Check each standard according to your assigned role. Note: Choosing \\\"No\\\" triggers a prerequisite cascade setting related items in the section to No.\",\"prerequisite_cascade\":true,\"short_name\":\"DOS Subform\",\"time_slots\":[]}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(8, 'dealer-operations-standards-documentation', 'Dealer Operations Standards - Documentation', 'FY2025 Aftersales Standards Compliance Audit Documentation Sheet (17 Standards).', 1, '{\"validation_mode\":\"dos_documentation\",\"response_options\":[\"yes\",\"no\",\"na\"],\"instructions\":\"Audit service documents (Rationalized Checksheet, Repair Order, Service Invoice) across multiple customers.\",\"prerequisite_cascade\":true,\"multi_customer\":true,\"default_customer_count\":3,\"short_name\":\"DOS Documentation\",\"time_slots\":[]}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02');

-- --------------------------------------------------------

--
-- Table structure for table `dealer_checklist_settings`
--

CREATE TABLE `dealer_checklist_settings` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `dealer` varchar(255) NOT NULL,
  `category` varchar(40) NOT NULL,
  `is_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `updated_by_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `dealer_checklist_settings`
--

INSERT INTO `dealer_checklist_settings` (`id`, `dealer`, `category`, `is_enabled`, `updated_by_user_id`, `created_at`, `updated_at`) VALUES
(1, 'MITSUBISHI SUCAT', 'dos_sales', 1, 310, '2026-09-24 17:42:41', '2026-09-24 18:37:08'),
(2, 'MITSUBISHI SUCAT', 'dos_aftersales', 1, 310, '2026-09-24 17:42:41', '2026-09-24 18:37:08'),
(3, 'MITSUBISHI SUCAT', 'five_s_sales', 1, 310, '2026-09-24 17:42:41', '2026-09-24 17:42:41'),
(4, 'MITSUBISHI SUCAT', 'five_s_service', 1, 310, '2026-09-24 17:42:41', '2026-09-24 17:42:41'),
(5, 'MITSUBISHI SUCAT', 'five_s_utility', 1, 310, '2026-09-24 17:42:41', '2026-09-24 17:42:41');

-- --------------------------------------------------------

--
-- Table structure for table `failed_jobs`
--

CREATE TABLE `failed_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `uuid` varchar(255) NOT NULL,
  `connection` text NOT NULL,
  `queue` text NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobs`
--

CREATE TABLE `jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `attempts` tinyint(3) UNSIGNED NOT NULL,
  `reserved_at` int(10) UNSIGNED DEFAULT NULL,
  `available_at` int(10) UNSIGNED NOT NULL,
  `created_at` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `job_batches`
--

CREATE TABLE `job_batches` (
  `id` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `total_jobs` int(11) NOT NULL,
  `pending_jobs` int(11) NOT NULL,
  `failed_jobs` int(11) NOT NULL,
  `failed_job_ids` longtext NOT NULL,
  `options` mediumtext DEFAULT NULL,
  `cancelled_at` int(11) DEFAULT NULL,
  `created_at` int(11) NOT NULL,
  `finished_at` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `migrations`
--

CREATE TABLE `migrations` (
  `id` int(10) UNSIGNED NOT NULL,
  `migration` varchar(255) NOT NULL,
  `batch` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(1, '0001_01_01_000000_create_users_table', 1),
(2, '0001_01_01_000001_create_cache_table', 1),
(3, '0001_01_01_000002_create_jobs_table', 1),
(5, '2026_08_07_002812_add_branch_and_user_type_to_users_table', 2),
(6, '2026_08_12_070249_create_personal_access_tokens_table', 3),
(7, '2026_08_12_000001_add_account_status_to_users_table', 4),
(8, '2026_08_22_000100_create_checklist_templates_table', 5),
(9, '2026_08_22_000110_create_checklist_sections_table', 5),
(10, '2026_08_22_000120_create_checklist_items_table', 5),
(11, '2026_08_22_000130_create_checklist_submissions_table', 5),
(12, '2026_08_22_000140_create_checklist_responses_table', 5),
(13, '2026_08_22_000150_create_reports_table', 5),
(14, '2026_08_28_000200_normalize_compliance_administrator_role', 6),
(15, '2026_08_29_000300_create_sales_and_service_checklist_templates', 7),
(16, '2026_08_29_000300_add_submitter_snapshot_to_checklist_submissions_table', 8),
(17, '2026_08_29_000400_create_notifications_table', 9),
(18, '2026_09_02_000500_add_pic_assignment_type_to_users_table', 10),
(19, '2026_09_02_000600_add_avatar_path_to_users_table', 11),
(20, '2026_09_03_000700_add_attachment_path_to_checklist_responses_table', 12),
(21, '2026_09_07_000800_backfill_dos_checker_metadata', 13),
(22, '2026_09_07_000900_expand_checklist_response_follow_up_fields', 14),
(23, '2026_09_07_001000_backfill_dos_workbook_metadata', 14),
(24, '2026_09_07_001100_create_dos_subform_and_documentation_templates', 15),
(26, '2026_09_07_001200_rename_pm_to_property_management', 16),
(27, '2026_09_07_001300_finish_property_management_terminology_backfill', 17),
(28, '2026_09_09_000000_consolidate_workshop_supervisor_role', 18),
(29, '2026_09_11_000100_update_sales_and_service_checklist_presets', 19),
(30, '2026_09_14_000000_create_web_push_subscriptions_table', 20),
(31, '2026_09_17_000100_add_must_change_password_to_users_table', 21),
(32, '2026_09_19_000100_update_utilities_checklist_schedule', 22),
(33, '2026_09_24_000100_separate_system_administrator_and_general_manager_roles', 23),
(34, '2026_09_24_000200_create_dealer_checklist_settings_table', 23),
(35, '2026_09_24_000300_create_user_usage_events_table', 23),
(36, '2026_09_24_000400_create_branch_restrooms_table', 24),
(37, '2026_09_25_000100_backfill_restroom_submission_scope', 25);

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` char(36) NOT NULL,
  `type` varchar(255) NOT NULL,
  `notifiable_type` varchar(255) NOT NULL,
  `notifiable_id` bigint(20) UNSIGNED NOT NULL,
  `data` text NOT NULL,
  `read_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `password_reset_tokens`
--

CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `personal_access_tokens`
--

CREATE TABLE `personal_access_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `tokenable_type` varchar(255) NOT NULL,
  `tokenable_id` bigint(20) UNSIGNED NOT NULL,
  `name` text NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `personal_access_tokens`
--

INSERT INTO `personal_access_tokens` (`id`, `tokenable_type`, `tokenable_id`, `name`, `token`, `abilities`, `last_used_at`, `expires_at`, `created_at`, `updated_at`) VALUES
(141, 'App\\Models\\User', 120, 'gateway-expo-app', '1d6610168426ca5a0d63479c76a17fd5460cc55709bd7e1486696438369623cf', '[\"*\"]', '2026-09-07 01:19:56', NULL, '2026-09-07 01:19:51', '2026-09-07 01:19:56'),
(167, 'App\\Models\\User', 116, 'gateway-expo-app', '9b1c02a3fa407698442d3b8233e02c5f2c4bc712e373f1450497d0f2002dff28', '[\"*\"]', '2026-09-08 01:28:58', NULL, '2026-09-08 01:28:53', '2026-09-08 01:28:58'),
(187, 'App\\Models\\User', 116, 'gateway-expo-app', '3402b8b6c7652bf5cade45ed8a2c665ecc060c68e067b2534f87590277a9e72c', '[\"*\"]', '2026-09-09 01:03:26', NULL, '2026-09-09 00:39:45', '2026-09-09 01:03:26'),
(200, 'App\\Models\\User', 116, 'gateway-expo-app', '838ed734ad4ebf3a2599bce6ae85fd2abe054148e2a47e919974d4f976b6dde8', '[\"*\"]', '2026-09-09 17:30:10', NULL, '2026-09-09 17:30:01', '2026-09-09 17:30:10'),
(229, 'App\\Models\\User', 116, 'gateway-expo-app', '870eaa2aead0b445f05038c38bbf22dc636a3124e6351bfb01436ec250b54871', '[\"*\"]', '2026-09-10 17:05:09', NULL, '2026-09-10 16:59:54', '2026-09-10 17:05:09'),
(230, 'App\\Models\\User', 116, 'gateway-expo-app', 'f999ee96c9acc60945eacb559a3075724938a114c58823faa92066fd8b011ca4', '[\"*\"]', '2026-09-10 17:49:58', NULL, '2026-09-10 17:05:48', '2026-09-10 17:49:58'),
(231, 'App\\Models\\User', 116, 'gateway-expo-app', '633dadc77d9a074ae53a7c55579099bdd74d41ff139d1d71dba06ff7b0c65221', '[\"*\"]', '2026-09-10 18:12:54', NULL, '2026-09-10 18:06:09', '2026-09-10 18:12:54'),
(233, 'App\\Models\\User', 116, 'gateway-expo-app', 'f1d939505ab494be4daf6ae85b726c249080447f0966c5ed4868c9848c262020', '[\"*\"]', '2026-09-10 19:50:18', NULL, '2026-09-10 19:33:19', '2026-09-10 19:50:18'),
(234, 'App\\Models\\User', 116, 'gateway-expo-app', 'af4d3e80756c7500c439500e767512bc74d462c60d51d68c58f5673fa007087e', '[\"*\"]', '2026-09-10 21:13:31', NULL, '2026-09-10 19:53:18', '2026-09-10 21:13:31'),
(235, 'App\\Models\\User', 116, 'gateway-expo-app', '68f55ded4f75a7e5d464c905c3b0ea0d2b88b61e55bec3d0758acdfd611d9206', '[\"*\"]', '2026-09-10 21:53:16', NULL, '2026-09-10 21:14:23', '2026-09-10 21:53:16'),
(236, 'App\\Models\\User', 116, 'gateway-expo-app', '32b1a5d72e930a152475bf34f9680f4e66872168f9124967cab19be4e21d6e02', '[\"*\"]', '2026-09-10 22:04:49', NULL, '2026-09-10 21:53:59', '2026-09-10 22:04:49'),
(237, 'App\\Models\\User', 116, 'gateway-expo-app', '7962efb1dc8cf022d207b9dc67fd50b42c3e357a3f5e6dca0fc7f6cd269d2801', '[\"*\"]', '2026-09-10 22:20:01', NULL, '2026-09-10 22:06:12', '2026-09-10 22:20:01'),
(238, 'App\\Models\\User', 116, 'gateway-expo-app', '1db19c61f3f364923a23f2c8847884127f146fcc38e6a27ce3416c95f4931626', '[\"*\"]', '2026-09-10 22:41:34', NULL, '2026-09-10 22:20:14', '2026-09-10 22:41:34'),
(239, 'App\\Models\\User', 116, 'gateway-expo-app', 'a6e2585b6a5d31943c7bf6d0e7a7255082e60f0d7f77bab887c3e8de27493391', '[\"*\"]', '2026-09-10 22:51:03', NULL, '2026-09-10 22:42:42', '2026-09-10 22:51:03'),
(240, 'App\\Models\\User', 116, 'gateway-expo-app', '704e2ec09f8335090f8de6a2dce6229c966a7bd3441a8d7793e97484bd134e59', '[\"*\"]', '2026-09-10 22:58:26', NULL, '2026-09-10 22:52:05', '2026-09-10 22:58:26'),
(241, 'App\\Models\\User', 116, 'gateway-expo-app', '2f463173bd894a25edcd44eecc16b502d2fb0b360b2120c2b555dc2641e139db', '[\"*\"]', '2026-09-10 23:21:09', NULL, '2026-09-10 22:58:59', '2026-09-10 23:21:09'),
(242, 'App\\Models\\User', 116, 'gateway-expo-app', '7429c694c17d93ab5c026bd2a8ed3f84ce6330111a24a748c6084d3c075d2679', '[\"*\"]', '2026-09-10 23:26:31', NULL, '2026-09-10 23:23:35', '2026-09-10 23:26:31'),
(244, 'App\\Models\\User', 116, 'gateway-expo-app', 'e1616fd8ef074a0eedfdfa4de54ac1e172786ed14e7abd81daa6696f62f464e8', '[\"*\"]', '2026-09-11 00:06:26', NULL, '2026-09-10 23:35:59', '2026-09-11 00:06:26'),
(245, 'App\\Models\\User', 116, 'gateway-expo-app', '2c21394f4e9c4bfaac9b0b8ba0444331c867a0015a3b6505495be49296cf2545', '[\"*\"]', '2026-09-11 18:16:42', NULL, '2026-09-11 18:12:05', '2026-09-11 18:16:42'),
(246, 'App\\Models\\User', 116, 'gateway-expo-app', '27ec16662188004dcb203e9850ee9c30ccd1fb7de1d52b2cab7210fddc48f7e5', '[\"*\"]', '2026-09-11 18:33:02', NULL, '2026-09-11 18:16:59', '2026-09-11 18:33:02'),
(308, 'App\\Models\\User', 116, 'gateway-expo-app', '309cef820d7e083d09f9d388b7cee3079f185be1e097dcf3b770106c25c9730a', '[\"*\"]', '2026-09-14 16:29:08', NULL, '2026-09-14 16:27:47', '2026-09-14 16:29:08'),
(322, 'App\\Models\\User', 118, 'gateway-expo-app', 'b5c22f17852b189b5eba8b012dce59c24579ca4d0fe5ecf09c45f4617cbdc60b', '[\"*\"]', '2026-09-16 18:50:05', NULL, '2026-09-16 18:47:40', '2026-09-16 18:50:05'),
(324, 'App\\Models\\User', 118, 'gateway-expo-app', 'e53486524b065bfbe5f544314223c7c02005d8b686a26a69349b496c52a32b78', '[\"*\"]', '2026-09-16 20:40:39', NULL, '2026-09-16 20:36:57', '2026-09-16 20:40:39'),
(326, 'App\\Models\\User', 118, 'gateway-expo-app', 'cd643e060610b38e08e3ea7db6095af46e20c30d94677100d00f9783174e0c16', '[\"*\"]', '2026-09-16 21:14:48', NULL, '2026-09-16 21:11:35', '2026-09-16 21:14:48'),
(332, 'App\\Models\\User', 116, 'gateway-expo-app', 'edb3aa763c0c3c88578e2659eca2d8beb765ef10da84a75a3d5291469c9761a5', '[\"*\"]', '2026-09-16 22:25:41', NULL, '2026-09-16 22:07:02', '2026-09-16 22:25:41'),
(352, 'App\\Models\\User', 118, 'gateway-expo-app', '48f5907a4792375d79a6aa87a8bd41c306fce040ca34e140aa6f0830d27637a1', '[\"*\"]', '2026-09-17 00:20:56', NULL, '2026-09-17 00:20:20', '2026-09-17 00:20:56'),
(354, 'App\\Models\\User', 116, 'gateway-expo-app', 'd13d86749f1d256e540db9400e0ced5f754114b8b1065e7b95559b1b02e22a42', '[\"*\"]', '2026-09-17 00:58:48', NULL, '2026-09-17 00:56:26', '2026-09-17 00:58:48'),
(355, 'App\\Models\\User', 116, 'notifications:a436fdc8-329d-478a-8415-f07eaf27bb8b', 'ba40a440d4a3726c972555db97dd7e4a3b48c3231ee0d3a4620c78d671eb4145', '[\"notifications:read\"]', NULL, NULL, '2026-09-17 00:56:26', '2026-09-17 00:56:26'),
(358, 'App\\Models\\User', 116, 'gateway-expo-app', 'bab6d7ef98591c773c96f8aa822e2300ae2adc0c3f7499bfb6149eb54ba5b816', '[\"*\"]', '2026-09-17 17:24:28', NULL, '2026-09-17 17:24:04', '2026-09-17 17:24:28'),
(360, 'App\\Models\\User', 116, 'gateway-expo-app', 'fb1a45a6f4472dfb24bbfeee559c45caab7c23868c4ceab19c720c4ce1eb9658', '[\"*\"]', '2026-09-17 17:26:45', NULL, '2026-09-17 17:26:05', '2026-09-17 17:26:45'),
(364, 'App\\Models\\User', 118, 'gateway-expo-app', 'a1a8e7804c2d1b1b712467da4449258f27b062bdb63dcc784a02005fd81442cd', '[\"*\"]', '2026-09-17 21:54:16', NULL, '2026-09-17 21:41:17', '2026-09-17 21:54:16'),
(370, 'App\\Models\\User', 116, 'gateway-expo-app', 'e2202e050cbba2d645d3a1c066b1821ae22834a151e678436cc1032bf08e1127', '[\"*\"]', '2026-09-18 01:55:16', NULL, '2026-09-18 01:51:09', '2026-09-18 01:55:16'),
(374, 'App\\Models\\User', 116, 'gateway-expo-app', 'e2d1823786dd9b05492a13d02eb256cc039f381ac176f11b8580295f468dc853', '[\"*\"]', '2026-09-18 19:50:02', NULL, '2026-09-18 19:49:10', '2026-09-18 19:50:02'),
(376, 'App\\Models\\User', 116, 'gateway-expo-app', '3fba01de795151880a5d920b6dd2d06adaba317867acb47380ca47f858559a47', '[\"*\"]', '2026-09-18 21:07:33', NULL, '2026-09-18 21:05:08', '2026-09-18 21:07:33'),
(378, 'App\\Models\\User', 116, 'gateway-expo-app', 'bcf9e691e348bc04c4423847a17bf7bd29d76e8262c3e5df6ba8ca2654e53de3', '[\"*\"]', '2026-09-18 21:23:36', NULL, '2026-09-18 21:23:30', '2026-09-18 21:23:36'),
(380, 'App\\Models\\User', 116, 'gateway-expo-app', '86fb2671f5c41ce354d9127c6d32a0d909428fc56fa7e288abf1d1c92a9a4b8f', '[\"*\"]', '2026-09-18 22:01:01', NULL, '2026-09-18 22:00:21', '2026-09-18 22:01:01'),
(382, 'App\\Models\\User', 116, 'gateway-expo-app', 'e3efb8e4f3118ccf5d601b89e0d78c36dd43d40b1d6afab99802978003d238bc', '[\"*\"]', '2026-09-18 22:15:16', NULL, '2026-09-18 22:01:15', '2026-09-18 22:15:16'),
(388, 'App\\Models\\User', 118, 'gateway-expo-app', 'c28328fc5ef8c2be193410faa8406b9f5e70a100e8f867ce25f38b848229554f', '[\"*\"]', '2026-09-18 22:53:38', NULL, '2026-09-18 22:53:20', '2026-09-18 22:53:38'),
(406, 'App\\Models\\User', 116, 'gateway-expo-app', '7d551342d9b84ec01e8990497ee90003bde496e382f6c5b430e24812ac6f4d46', '[\"*\"]', '2026-09-20 16:57:51', NULL, '2026-09-20 16:56:36', '2026-09-20 16:57:51'),
(408, 'App\\Models\\User', 116, 'gateway-expo-app', '6228392d231e8ff0a28b9aef7dddb0cf46adf9ee62fb5e8d0f2c758b6e7efb03', '[\"*\"]', '2026-09-20 18:20:08', NULL, '2026-09-20 16:58:08', '2026-09-20 18:20:08'),
(412, 'App\\Models\\User', 118, 'gateway-expo-app', 'aaf402f406e3096f1303f702a8a80768eafdb18c1f3362e4e9e03111845e0696', '[\"*\"]', '2026-09-20 21:22:06', NULL, '2026-09-20 21:21:37', '2026-09-20 21:22:06'),
(416, 'App\\Models\\User', 116, 'gateway-expo-app', '307c30e28452b96b196507606fd7f3a9d89600732f7b87c0834145810439bd9b', '[\"*\"]', '2026-09-21 01:03:39', NULL, '2026-09-20 21:23:36', '2026-09-21 01:03:39'),
(422, 'App\\Models\\User', 116, 'gateway-expo-app', '38aeaf47fb5356be783b4937670fee81f14bab79612e3ead624309bebc27fdf6', '[\"*\"]', '2026-09-23 18:21:46', NULL, '2026-09-23 18:17:45', '2026-09-23 18:21:46'),
(432, 'App\\Models\\User', 116, 'gateway-expo-app', '798e3a670c940194e3f734bdcda92d40446897bb06e99c928b61800fbcb72246', '[\"*\"]', '2026-09-23 22:58:09', NULL, '2026-09-23 22:57:52', '2026-09-23 22:58:09'),
(434, 'App\\Models\\User', 116, 'gateway-expo-app', 'f71ccaa5f95d25028ef857ba748ba5598f9118e1760ec63f4f12abe618f4305e', '[\"*\"]', '2026-09-23 23:01:50', NULL, '2026-09-23 23:00:10', '2026-09-23 23:01:50'),
(436, 'App\\Models\\User', 116, 'gateway-expo-app', 'b5a175235bcce0d47df659ed8303299238617745ae3228bf96d7a24c2da33b4e', '[\"*\"]', '2026-09-23 23:04:21', NULL, '2026-09-23 23:02:04', '2026-09-23 23:04:21'),
(438, 'App\\Models\\User', 152, 'gateway-expo-app', '346a3ac790c68763c92dee03169b55368da489c204b3cda4e5ab9613511fd523', '[\"*\"]', '2026-09-24 16:30:31', NULL, '2026-09-24 16:30:01', '2026-09-24 16:30:31'),
(446, 'App\\Models\\User', 152, 'gateway-expo-app', '3a825fa5977f5764961fc8bab857ba2f7db65209df668200df5806f378101238', '[\"*\"]', '2026-09-24 19:05:15', NULL, '2026-09-24 18:54:24', '2026-09-24 19:05:15'),
(448, 'App\\Models\\User', 107, 'gateway-expo-app', '9bb7d6f411ef35d2b97b20ea24b4c63f1cbd5b3f13c0eea1f8c9c6f68bf55730', '[\"*\"]', '2026-09-24 22:39:20', NULL, '2026-09-24 22:17:33', '2026-09-24 22:39:20'),
(450, 'App\\Models\\User', 107, 'gateway-expo-app', 'e22b9629437d7624c80f657863de74b7aeefaacf0a1c50e4212ff6b2e79e6a09', '[\"*\"]', '2026-09-27 19:37:59', NULL, '2026-09-24 23:56:09', '2026-09-27 19:37:59'),
(451, 'App\\Models\\User', 107, 'notifications:7bc9a647-b609-4453-ac6e-a046947ab178', 'd90e001538c2d2ee1ab0209fe6a13bde8bb2cdeeae71a6651e2883004d2eb5e9', '[\"notifications:read\"]', NULL, NULL, '2026-09-24 23:56:09', '2026-09-24 23:56:09');

-- --------------------------------------------------------

--
-- Table structure for table `reports`
--

CREATE TABLE `reports` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `checklist_submission_id` bigint(20) UNSIGNED DEFAULT NULL,
  `checklist_template_id` bigint(20) UNSIGNED DEFAULT NULL,
  `generated_by_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `type` varchar(50) NOT NULL DEFAULT 'checklist_submission',
  `title` varchar(255) NOT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'ready',
  `filters` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`filters`)),
  `data_snapshot` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`data_snapshot`)),
  `generated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sessions`
--

CREATE TABLE `sessions` (
  `id` varchar(255) NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `payload` longtext NOT NULL,
  `last_activity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `sessions`
--

INSERT INTO `sessions` (`id`, `user_id`, `ip_address`, `user_agent`, `payload`, `last_activity`) VALUES
('0q037qOCTVCnGr0dExxGVd5WeHEoyJvNd297aG1f', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiMUQzU1M5Y0RkNENzRUJURERnYTRKUmRKQWFZRlVaSFVjNGdTTGo4aCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDI6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9tYW5pZmVzdC53ZWJtYW5pZmVzdCI7czo1OiJyb3V0ZSI7czoyNzoibm90aWZpY2F0aW9ucy5wdXNoLm1hbmlmZXN0Ijt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1790566449),
('32f8cBv7IZo1I2Z2uzSgHKJibs5fc0QfMQk4HOCG', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiYmxVck9EVE1mZ1pHVlg1MldQQURSVm4wQ1dDYVNOaWFSbnExOThuZCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDI6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9tYW5pZmVzdC53ZWJtYW5pZmVzdCI7czo1OiJyb3V0ZSI7czoyNzoibm90aWZpY2F0aW9ucy5wdXNoLm1hbmlmZXN0Ijt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1790566501),
('524dNPIiyr0JP0nBftv9xApIh6dwJKlcldZwQabu', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoieEV4YVhWSjkwb0tGMjlxa29wN3BlYk1Qck5PSENqVWpXZTFVSktJbCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDI6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9tYW5pZmVzdC53ZWJtYW5pZmVzdCI7czo1OiJyb3V0ZSI7czoyNzoibm90aWZpY2F0aW9ucy5wdXNoLm1hbmlmZXN0Ijt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1790566503),
('8r0MmYP4pmsChZWFPruMNrJElU8O1RNjB9i6Rmhd', 5, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', 'YTo1OntzOjY6Il90b2tlbiI7czo0MDoiRVpsZ25pc0c3QnBVTHI2MUNjaHduWkE4RnM0Qk1SM3dXbnR4WWRPQSI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDI6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9ub3RpZmljYXRpb25zL3N0YXR1cyI7czo1OiJyb3V0ZSI7czoyMDoibm90aWZpY2F0aW9ucy5zdGF0dXMiO31zOjM6InVybCI7YTowOnt9czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6NTt9', 1790572169),
('c6zaRHUHPHJlgcmYZxq8kFHy0RX0Lczmy75CsxC7', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoicE1YQlFWcUpUTlR0OGtZbFpXa0pleXBBY21RVkw3UUdCRTNyQ21HeiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDI6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9tYW5pZmVzdC53ZWJtYW5pZmVzdCI7czo1OiJyb3V0ZSI7czoyNzoibm90aWZpY2F0aW9ucy5wdXNoLm1hbmlmZXN0Ijt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1790566427),
('cJckBRkt1z1qHhcbnFb3TBoCP29XNmsnj6AanKCK', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoienlabEd1SnpmNlg1TWVpZTJ1QlhPUHRNdjBnQ3JSQ0U5T2gxU09BUSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDI6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9tYW5pZmVzdC53ZWJtYW5pZmVzdCI7czo1OiJyb3V0ZSI7czoyNzoibm90aWZpY2F0aW9ucy5wdXNoLm1hbmlmZXN0Ijt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1790566494),
('D6Wu9z7Dc4VLcpZex60CicPXLO9P9xZvUjlpjBTu', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoibk9YdndzR3NjNVFyT1d0WTVKSzhpT0JRaUVYSk9YaU9FMHBlaWxJeSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDI6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9tYW5pZmVzdC53ZWJtYW5pZmVzdCI7czo1OiJyb3V0ZSI7czoyNzoibm90aWZpY2F0aW9ucy5wdXNoLm1hbmlmZXN0Ijt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1790566499),
('fkYbuxeEMYEVSGSiuGNuyyjCH8waKmaLbtacsFwZ', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiZFFyWlZwMTg4SHQzaldpb1pXN0RCT3ZKQTAzTnpKM0VnRW5vd3FpQyI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDI6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9tYW5pZmVzdC53ZWJtYW5pZmVzdCI7czo1OiJyb3V0ZSI7czoyNzoibm90aWZpY2F0aW9ucy5wdXNoLm1hbmlmZXN0Ijt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1790566466),
('gwgPbDiID0NR3Jr6CR56nDhWKjoHTiOaF8C8q9Xj', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoiZnNuWUFSbnYwR2x5dTVIeWVDODJ6SDN3aFB0eHdtcndXaDI1Q3N3VyI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6Mjc6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9sb2dpbiI7czo1OiJyb3V0ZSI7czo1OiJsb2dpbiI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fXM6MzoidXJsIjthOjE6e3M6ODoiaW50ZW5kZWQiO3M6MzE6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9kYXNoYm9hcmQiO319', 1790920051),
('h4C3CFLc5ygGiT1AcqXpaFHLuFox3oPUIeeTYZ99', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiNVZyQWJ5T0VmRjRFbmZOblJwMk5CMmNRY3VmMWtLckVnUTlpMXZjbCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDI6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9tYW5pZmVzdC53ZWJtYW5pZmVzdCI7czo1OiJyb3V0ZSI7czoyNzoibm90aWZpY2F0aW9ucy5wdXNoLm1hbmlmZXN0Ijt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1790920051),
('L8Ui2Ry8Gca9sLpgMezLTbpE6Xvam5UVwpQaT9hX', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiU1VqZzB4emk0cXZ3d1JCaXlIMTNjd1E5YkwxV043Q1ZRMExHbTNkbCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDI6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9tYW5pZmVzdC53ZWJtYW5pZmVzdCI7czo1OiJyb3V0ZSI7czoyNzoibm90aWZpY2F0aW9ucy5wdXNoLm1hbmlmZXN0Ijt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1790566411),
('nlO0sOnCoUHbMJxOKZRsckytpSAgzNpWmngECg8x', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiY2x0dzlxaVl4Y3VuTFFrSHdKTW45WUlLZERTOVNKNDRFMHZTWUJJUSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDI6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9tYW5pZmVzdC53ZWJtYW5pZmVzdCI7czo1OiJyb3V0ZSI7czoyNzoibm90aWZpY2F0aW9ucy5wdXNoLm1hbmlmZXN0Ijt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1790566438),
('PT9Elz0zmOxv8B04Hi4PKuXsEBtklqwFplrYysTL', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiQ1JUdUtqWFhBOGZJc3J2eFRVRFFaMldYSjhVN0dPMDRaelI4a3Z1bCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDI6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9tYW5pZmVzdC53ZWJtYW5pZmVzdCI7czo1OiJyb3V0ZSI7czoyNzoibm90aWZpY2F0aW9ucy5wdXNoLm1hbmlmZXN0Ijt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1790566507),
('TSo13XquyqP3WcA7tEJSlYZJeHVXrHjoC0VrZQQt', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiNnJQUDhnaDZLUUh4UnhCdk80WXlyelRZNzlsOVlsOUlQaXVQSmtRUyI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDI6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9tYW5pZmVzdC53ZWJtYW5pZmVzdCI7czo1OiJyb3V0ZSI7czoyNzoibm90aWZpY2F0aW9ucy5wdXNoLm1hbmlmZXN0Ijt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1790566470),
('Wfh4xZy22jBKqXF6NE9Veh4teWuYNbcl6w1bTWxE', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoibmhSUGdmWWd1M3J6MXZUMXlUeEdWUUtCRHB0bEJLTUFPZW96SlJEYiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDI6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9tYW5pZmVzdC53ZWJtYW5pZmVzdCI7czo1OiJyb3V0ZSI7czoyNzoibm90aWZpY2F0aW9ucy5wdXNoLm1hbmlmZXN0Ijt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1790566505),
('yEzh8ncn1VLjMBA0QUmDo4ouxmaeVqz8OF3DIagZ', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoibWpUUVBxNFptSTRKM3o4ZXl2R1hCbGRpZVhRdG5xamx1SGp4ZTNTWiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDI6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9tYW5pZmVzdC53ZWJtYW5pZmVzdCI7czo1OiJyb3V0ZSI7czoyNzoibm90aWZpY2F0aW9ucy5wdXNoLm1hbmlmZXN0Ijt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1790566497);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `branch` varchar(255) DEFAULT NULL,
  `user_type` varchar(255) NOT NULL DEFAULT 'Employee',
  `pic_assignment_type` varchar(30) DEFAULT NULL,
  `account_status` varchar(20) NOT NULL DEFAULT 'active',
  `must_change_password` tinyint(1) NOT NULL DEFAULT 0,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `avatar_path` varchar(255) DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `remember_token` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `branch`, `user_type`, `pic_assignment_type`, `account_status`, `must_change_password`, `email_verified_at`, `avatar_path`, `password`, `remember_token`, `created_at`, `updated_at`) VALUES
(5, 'General Manager', 'GM.MitsubishiSucat', 'MITSUBISHI SUCAT', 'GM', NULL, 'active', 0, '2026-09-05 01:43:56', NULL, '$2y$12$lmotuZ3JX9IKsfD.XmD7JOS9BPPFNfvVhlB1ohBDWtfj.ZwbZE0Va', 'AkZTebYa0pOhJ8pH0YDEYvP58LlagdkHiZ1mhKu208HWfljiv4xgUl9fnlAt', '2026-08-06 17:48:51', '2026-09-24 00:25:12'),
(107, 'Marcus Sales (Sales Manager)', 'SalesManager.MitsubishiSucat', 'MITSUBISHI SUCAT', 'SALES_MANAGER', NULL, 'active', 0, '2026-09-05 01:43:56', NULL, '$2y$12$oxIPZj.y3w4mQH8123vZ8eGafrV9rsxvF4cWvdex/FquXaP8BA1RK', 'Sr8hBnPu7pnezAee2OndgKaVXepvSNsTf3OAytJWxkt0SdjfXiKe1RWf8I8g', '2026-09-05 01:43:56', '2026-09-24 00:25:13'),
(108, 'Carlo Mendoza (Aftersales Manager)', 'ASM.MitsubishiSucat', 'MITSUBISHI SUCAT', 'ASM', NULL, 'active', 0, '2026-09-05 01:43:56', NULL, '$2y$12$a8Ky1oCNdnEzUsz3ersAUOF9euTxLg3JmLVp6lzp0GuUVaTwFEJwm', 'bqOn6MeF5vt1pvLu1Z07AJrVPl9eo7Ycv1UMbr893pU0HszJt37N0E0tREL7', '2026-09-05 01:43:56', '2026-09-24 00:25:13'),
(109, 'Maria Santos (CE Service)', 'CEService.MitsubishiSucat', 'MITSUBISHI SUCAT', 'CE SERVICE', NULL, 'active', 0, '2026-09-05 01:43:56', NULL, '$2y$12$Vj1FjJm1zXwCRqPicRlNu.xZy98iTf0KYCUbjNelQi7ADXVZlEePS', 'YmXlXElpTf3OcRZvMEzwqkVv0BXoCP3oQBTte0DSgZaZ9by8jT0A6khKLP0c', '2026-09-05 01:43:56', '2026-09-24 00:25:14'),
(110, 'David Cruz (Job Controller)', 'JobController.MitsubishiSucat', 'MITSUBISHI SUCAT', 'JOB CONTROLLER', NULL, 'active', 0, '2026-09-05 01:43:56', NULL, '$2y$12$L5ajFhnrDVn.oRuejur9Eu0RMSqKhAfoMFqJed.t4O1o38KNOaRvm', 'INPkbN91qtsDMwiW2DEooQuNQqY7DyVMUSG4hwo60OJ7x7MBbTAcbosJTCEt', '2026-09-05 01:43:56', '2026-09-24 00:25:14'),
(111, 'Peter Reyes (Parts Supervisor)', 'PartsSupervisor.MitsubishiSucat', 'MITSUBISHI SUCAT', 'PARTS SUPERVISOR', NULL, 'active', 0, '2026-09-05 01:43:56', NULL, '$2y$12$o3v6mS.aag7fB2QSFT1tleD96DQFizkIdi/k6PWG/hpaqwnqfgjpe', 'qP6uwv3xAxGridTVj72FrnATfVdWzUxmhXa2076BxSLrj2dPwEh2r5kjFX13', '2026-09-05 01:43:56', '2026-09-24 00:25:14'),
(112, 'William Bautista (Workshop Supervisor)', 'WorkshopSup.MitsubishiSucat', 'MITSUBISHI SUCAT', 'WORKSHOP SUP', NULL, 'active', 0, '2026-09-05 01:43:56', NULL, '$2y$12$qRdJFR/JZJwVkLohNE39yeFr21DN85TsNKqraKqhsaTYIohbpqVwK', 'rrvIkB3m6BDr75YV35rLld42BVx2XV79qPZHiqxhbCGhVaaOsyYCDVOAwde8', '2026-09-05 01:43:56', '2026-09-24 00:25:14'),
(114, 'Roberto Garcia (Branch Operations Manager)', 'BOM.MitsubishiSucat', 'MITSUBISHI SUCAT', 'BOM', NULL, 'active', 0, '2026-09-05 01:43:56', NULL, '$2y$12$DDCAdisVRsVFQ6Y/rMqrLOnOEUbzdahq0mQt6SI8PYbCcuTWgjcLm', 'oBawNHjJFPbDErfyeNFRz7AU2Pczw7dBfOFp55xCiz9US9UQBbyqvvSfeygh', '2026-09-05 01:43:56', '2026-09-24 00:25:12'),
(116, '5S Utilities', '5SUtilities.SuzukiPasongTamo', 'SUZUKI PASONG TAMO', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$uXE2ugWETe9QGDYdVyerAeYPuWSRR6QSFsLFwG5QkXHUAG645xNBe', '5R0R0xvaTLAa5eD6pbH3X4IpmW3ejyR4VahSww2Jh4F6ILe7oMoAaLfwbPET', '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(117, '5S Service', '5SService.SuzukiPasongTamo', 'SUZUKI PASONG TAMO', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$TssFYYVcrKK1fFMSFpXcle4MsrKHjiLfbTXRBX0gIC5LO6n7nLFYK', 'SKWDkNb6NVXNKG7hA14X7Bu30tGNe7xYIyJwEoY5nZZuSxPqejccUjFxk8iR', '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(118, '5S Sales', '5SSales.SuzukiPasongTamo', 'SUZUKI PASONG TAMO', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$mYaEIUp5uQQ6vWMaYM8Hg.iIfQYuZqrmBaLC.hzUGAmBMrGl9nQne', 'p5mrJ3yGStvKa4EBgev7kMryzgMdPU3dBpIHCZdyz0Z35nK6e80sFFVxxfG6', '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(119, 'HONDA MAKATI 5S Utilities', '5SUtilities.HondaMakati', 'HONDA MAKATI', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(120, 'HONDA MAKATI 5S Service', '5SService.HondaMakati', 'HONDA MAKATI', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(121, 'HONDA MAKATI 5S Sales', '5SSales.HondaMakati', 'HONDA MAKATI', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(122, 'HYUNDAI MAKATI 5S Utilities', '5SUtilities.HyundaiMakati', 'HYUNDAI MAKATI', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(123, 'HYUNDAI MAKATI 5S Service', '5SService.HyundaiMakati', 'HYUNDAI MAKATI', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(124, 'HYUNDAI MAKATI 5S Sales', '5SSales.HyundaiMakati', 'HYUNDAI MAKATI', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(128, 'KIA OTIS 5S Utilities', '5SUtilities.KIAOtis', 'KIA OTIS', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(129, 'KIA OTIS 5S Service', '5SService.KIAOtis', 'KIA OTIS', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(130, 'KIA OTIS 5S Sales', '5SSales.KIAOtis', 'KIA OTIS', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(131, 'HONDA FAIRVIEW 5S Utilities', '5SUtilities.HondaFairview', 'HONDA FAIRVIEW', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$km.u2RbDsdrQga3zwb28cOkiQxUjRw0iYdn8Jz9OEP6h1UPZOPwuS', 'XSEjN4LkGHiwRiPAn6d63c9A2puwExwJ2DyahJfdTkcX2wnimZTCo8Tnf6lk', '2026-09-06 22:57:35', '2026-09-24 00:25:43'),
(132, 'HONDA FAIRVIEW 5S Service', '5SService.HondaFairview', 'HONDA FAIRVIEW', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$rg8AFM1bY5shK0ivYkrw8eBpj/bC8zl6aQ4/ONUdevKUIiieSGYHK', 'Kuwb1M5aDC4tXjiRwOa3Qv3LqOXm0UsVc0ONrZmPFk8iKsuuJ1N02QGeiCF5', '2026-09-06 22:57:35', '2026-09-24 00:25:43'),
(133, 'HONDA FAIRVIEW 5S Sales', '5SSales.HondaFairview', 'HONDA FAIRVIEW', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$9aEJK4kr9N5oRd6CIUGOvut2KD.JF88ogmGwmSsM15B7WkRHPefnu', 'CuF9TqkAOwwzjbCEg5HdMkdolX4i6szoHqor8pf9aevptKN7RoVteLYkLQWz', '2026-09-06 22:57:35', '2026-09-24 00:25:43'),
(137, 'MITSUBISHI QUEZON AVENUE 5S Utilities', '5SUtilities.MitsubishiQuezonAvenue', 'MITSUBISHI QUEZON AVENUE', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(138, 'MITSUBISHI QUEZON AVENUE 5S Service', '5SService.MitsubishiQuezonAvenue', 'MITSUBISHI QUEZON AVENUE', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(139, 'MITSUBISHI QUEZON AVENUE 5S Sales', '5SSales.MitsubishiQuezonAvenue', 'MITSUBISHI QUEZON AVENUE', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(140, 'HONDA MARCOS HIGHWAY 5S Utilities', '5SUtilities.HondaMarcosHighway', 'HONDA MARCOS HIGHWAY', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(141, 'HONDA MARCOS HIGHWAY 5S Service', '5SService.HondaMarcosHighway', 'HONDA MARCOS HIGHWAY', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(142, 'HONDA MARCOS HIGHWAY 5S Sales', '5SSales.HondaMarcosHighway', 'HONDA MARCOS HIGHWAY', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(143, 'HONDA CAINTA 5S Utilities', '5SUtilities.HondaCainta', 'HONDA CAINTA', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(144, 'HONDA CAINTA 5S Service', '5SService.HondaCainta', 'HONDA CAINTA', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(145, 'HONDA CAINTA 5S Sales', '5SSales.HondaCainta', 'HONDA CAINTA', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(146, 'GEELY CAINTA 5S Utilities', '5SUtilities.GeelyCainta', 'GEELY CAINTA', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(147, 'GEELY CAINTA 5S Service', '5SService.GeelyCainta', 'GEELY CAINTA', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(148, 'GEELY CAINTA 5S Sales', '5SSales.GeelyCainta', 'GEELY CAINTA', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(149, 'MITSUBISHI PASIG 5S Utilities', '5SUtilities.MitsubishiPasig', 'MITSUBISHI PASIG', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(150, 'MITSUBISHI PASIG 5S Service', '5SService.MitsubishiPasig', 'MITSUBISHI PASIG', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(151, 'MITSUBISHI PASIG 5S Sales', '5SSales.MitsubishiPasig', 'MITSUBISHI PASIG', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(152, 'MITSUBISHI SUCAT 5S Utilities', '5SUtilities.MitsubishiSucat', 'MITSUBISHI SUCAT', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$60gRyfWFbR00OqiJwk7QO.SctoTxBc4vLyD3EEk0ZmZ0CRzBFAc3K', 'MqHkdU9HeAOQuY8Ml0ada5WdpIK4DhZkKTEr9qnxxp1TxQ0kQadEY4QWqLMd', '2026-09-06 22:57:35', '2026-09-24 00:25:12'),
(153, 'MITSUBISHI SUCAT 5S Service', '5SService.MitsubishiSucat', 'MITSUBISHI SUCAT', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$CcTbQImiYwjsRTCtWZgKIeyCGZvf4WOpk82cq96FvlSoEtQJLg3KS', 'Mz7bueSliA0NHajvy6wsCRTMR80XaqBMK5A9gxEhSrAenIp1MB921vCdwDRo', '2026-09-06 22:57:35', '2026-09-24 00:25:13'),
(154, 'MITSUBISHI SUCAT 5S Sales', '5SSales.MitsubishiSucat', 'MITSUBISHI SUCAT', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$Tb.xZ6FCsQ9S190juC13tuHHX9n3jPXGfZaO4VNf2ZbE/dA22BhnW', 'bZG1fDo1VfS0Jw0WX8XoF7XS20Tzkw96QELzqxlrGp3Xzr4RB05Ja0AMJqaa', '2026-09-06 22:57:35', '2026-09-24 00:25:13'),
(155, 'HONDA ALABANG 5S Utilities', '5SUtilities.HondaAlabang', 'HONDA ALABANG', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(156, 'HONDA ALABANG 5S Service', '5SService.HondaAlabang', 'HONDA ALABANG', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(157, 'HONDA ALABANG 5S Sales', '5SSales.HondaAlabang', 'HONDA ALABANG', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(158, 'MG LAS PINAS 5S Utilities', '5SUtilities.MGLasPinas', 'MG LAS PINAS', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(159, 'MG LAS PINAS 5S Service', '5SService.MGLasPinas', 'MG LAS PINAS', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(160, 'MG LAS PINAS 5S Sales', '5SSales.MGLasPinas', 'MG LAS PINAS', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(161, 'CHANGAN BACOOR (old Nissan) 5S Utilities', '5SUtilities.ChanganBacoorOldNissan', 'CHANGAN BACOOR (old Nissan)', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(162, 'CHANGAN BACOOR (old Nissan) 5S Service', '5SService.ChanganBacoorOldNissan', 'CHANGAN BACOOR (old Nissan)', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(163, 'CHANGAN BACOOR (old Nissan) 5S Sales', '5SSales.ChanganBacoorOldNissan', 'CHANGAN BACOOR (old Nissan)', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(164, 'KIA DASMARINAS 5S Utilities', '5SUtilities.KIADasmarinas', 'KIA DASMARINAS', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(165, 'KIA DASMARINAS 5S Service', '5SService.KIADasmarinas', 'KIA DASMARINAS', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(166, 'KIA DASMARINAS 5S Sales', '5SSales.KIADasmarinas', 'KIA DASMARINAS', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(167, 'MG MARILAO 5S Utilities', '5SUtilities.MGMarilao', 'MG MARILAO', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(168, 'MG MARILAO 5S Service', '5SService.MGMarilao', 'MG MARILAO', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(169, 'MG MARILAO 5S Sales', '5SSales.MGMarilao', 'MG MARILAO', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(170, 'MG/GEELY ANGELES 5S Utilities', '5SUtilities.MGGeelyAngeles', 'MG/GEELY ANGELES', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(171, 'MG/GEELY ANGELES 5S Service', '5SService.MGGeelyAngeles', 'MG/GEELY ANGELES', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(172, 'MG/GEELY ANGELES 5S Sales', '5SSales.MGGeelyAngeles', 'MG/GEELY ANGELES', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(173, 'GEELY TARLAC 5S Utilities', '5SUtilities.GeelyTarlac', 'GEELY TARLAC', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(174, 'GEELY TARLAC 5S Service', '5SService.GeelyTarlac', 'GEELY TARLAC', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(175, 'GEELY TARLAC 5S Sales', '5SSales.GeelyTarlac', 'GEELY TARLAC', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(176, 'HONDA ISABELA 5S Utilities', '5SUtilities.HondaIsabela', 'HONDA ISABELA', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(177, 'HONDA ISABELA 5S Service', '5SService.HondaIsabela', 'HONDA ISABELA', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(178, 'HONDA ISABELA 5S Sales', '5SSales.HondaIsabela', 'HONDA ISABELA', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(179, 'SUZUKI SANTA ROSA 5S Utilities', '5SUtilities.SuzukiSantaRosa', 'SUZUKI SANTA ROSA', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(180, 'SUZUKI SANTA ROSA 5S Service', '5SService.SuzukiSantaRosa', 'SUZUKI SANTA ROSA', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(181, 'SUZUKI SANTA ROSA 5S Sales', '5SSales.SuzukiSantaRosa', 'SUZUKI SANTA ROSA', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(182, 'MITSUBISHI CALAMBA 5S Utilities', '5SUtilities.MitsubishiCalamba', 'MITSUBISHI CALAMBA', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(183, 'MITSUBISHI CALAMBA 5S Service', '5SService.MitsubishiCalamba', 'MITSUBISHI CALAMBA', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(184, 'MITSUBISHI CALAMBA 5S Sales', '5SSales.MitsubishiCalamba', 'MITSUBISHI CALAMBA', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(185, 'GEELY LIPA 5S Utilities', '5SUtilities.GeelyLipa', 'GEELY LIPA', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(186, 'GEELY LIPA 5S Service', '5SService.GeelyLipa', 'GEELY LIPA', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(187, 'GEELY LIPA 5S Sales', '5SSales.GeelyLipa', 'GEELY LIPA', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(188, 'SUZUKI ALAMINOS 5S Utilities', '5SUtilities.SuzukiAlaminos', 'SUZUKI ALAMINOS', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(189, 'SUZUKI ALAMINOS 5S Service', '5SService.SuzukiAlaminos', 'SUZUKI ALAMINOS', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(190, 'SUZUKI ALAMINOS 5S Sales', '5SSales.SuzukiAlaminos', 'SUZUKI ALAMINOS', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(191, 'KIA SAN PABLO 5S Utilities', '5SUtilities.KIASanPablo', 'KIA SAN PABLO', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(192, 'KIA SAN PABLO 5S Service', '5SService.KIASanPablo', 'KIA SAN PABLO', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(193, 'KIA SAN PABLO 5S Sales', '5SSales.KIASanPablo', 'KIA SAN PABLO', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(194, 'MG SAN PABLO 5S Utilities', '5SUtilities.MGSanPablo', 'MG SAN PABLO', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(195, 'MG SAN PABLO 5S Service', '5SService.MGSanPablo', 'MG SAN PABLO', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(196, 'MG SAN PABLO 5S Sales', '5SSales.MGSanPablo', 'MG SAN PABLO', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(197, 'MITSUBISHI PILI 5S Utilities', '5SUtilities.MitsubishiPili', 'MITSUBISHI PILI', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(198, 'MITSUBISHI PILI 5S Service', '5SService.MitsubishiPili', 'MITSUBISHI PILI', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(199, 'MITSUBISHI PILI 5S Sales', '5SSales.MitsubishiPili', 'MITSUBISHI PILI', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(200, 'MITSUBISHI LEGAZPI 5S Utilities', '5SUtilities.MitsubishiLegazpi', 'MITSUBISHI LEGAZPI', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(201, 'MITSUBISHI LEGAZPI 5S Service', '5SService.MitsubishiLegazpi', 'MITSUBISHI LEGAZPI', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(202, 'MITSUBISHI LEGAZPI 5S Sales', '5SSales.MitsubishiLegazpi', 'MITSUBISHI LEGAZPI', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(203, 'MITSUBISHI GREENHILLS 5S Utilities', '5SUtilities.MitsubishiGreenhills', 'MITSUBISHI GREENHILLS', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(204, 'MITSUBISHI GREENHILLS 5S Service', '5SService.MitsubishiGreenhills', 'MITSUBISHI GREENHILLS', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(205, 'MITSUBISHI GREENHILLS 5S Sales', '5SSales.MitsubishiGreenhills', 'MITSUBISHI GREENHILLS', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(206, 'HONDA MANILA BAY 5S Utilities', '5SUtilities.HondaManilaBay', 'HONDA MANILA BAY', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(207, 'HONDA MANILA BAY 5S Service', '5SService.HondaManilaBay', 'HONDA MANILA BAY', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(208, 'HONDA MANILA BAY 5S Sales', '5SSales.HondaManilaBay', 'HONDA MANILA BAY', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(209, 'HYUNDAI MANDAUE 5S Utilities', '5SUtilities.HyundaiMandaue', 'HYUNDAI MANDAUE', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(210, 'HYUNDAI MANDAUE 5S Service', '5SService.HyundaiMandaue', 'HYUNDAI MANDAUE', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(211, 'HYUNDAI MANDAUE 5S Sales', '5SSales.HyundaiMandaue', 'HYUNDAI MANDAUE', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(212, 'KIA / GEELY MANDAUE 5S Utilities', '5SUtilities.KIAGeelyMandaue', 'KIA / GEELY MANDAUE', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(213, 'KIA / GEELY MANDAUE 5S Service', '5SService.KIAGeelyMandaue', 'KIA / GEELY MANDAUE', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(214, 'KIA / GEELY MANDAUE 5S Sales', '5SSales.KIAGeelyMandaue', 'KIA / GEELY MANDAUE', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(215, 'MERCEDES-BENZ MANDAUE 5S Utilities', '5SUtilities.MercedesBenzMandaue', 'MERCEDES-BENZ MANDAUE', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(216, 'MERCEDES-BENZ MANDAUE 5S Service', '5SService.MercedesBenzMandaue', 'MERCEDES-BENZ MANDAUE', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(217, 'MERCEDES-BENZ MANDAUE 5S Sales', '5SSales.MercedesBenzMandaue', 'MERCEDES-BENZ MANDAUE', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(218, 'OMODA & JAECOO CEBU CITY 5S Utilities', '5SUtilities.OmodaJaecooCebuCity', 'OMODA & JAECOO CEBU CITY', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(219, 'OMODA & JAECOO CEBU CITY 5S Service', '5SService.OmodaJaecooCebuCity', 'OMODA & JAECOO CEBU CITY', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(220, 'OMODA & JAECOO CEBU CITY 5S Sales', '5SSales.OmodaJaecooCebuCity', 'OMODA & JAECOO CEBU CITY', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(221, 'MITSUBISHI TALISAY 5S Utilities', '5SUtilities.MitsubishiTalisay', 'MITSUBISHI TALISAY', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(222, 'MITSUBISHI TALISAY 5S Service', '5SService.MitsubishiTalisay', 'MITSUBISHI TALISAY', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(223, 'MITSUBISHI TALISAY 5S Sales', '5SSales.MitsubishiTalisay', 'MITSUBISHI TALISAY', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(224, 'HONDA TALISAY 5S Utilities', '5SUtilities.HondaTalisay', 'HONDA TALISAY', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(225, 'HONDA TALISAY 5S Service', '5SService.HondaTalisay', 'HONDA TALISAY', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(226, 'HONDA TALISAY 5S Sales', '5SSales.HondaTalisay', 'HONDA TALISAY', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(227, 'GEELY TALISAY 5S Utilities', '5SUtilities.GeelyTalisay', 'GEELY TALISAY', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(228, 'GEELY TALISAY 5S Service', '5SService.GeelyTalisay', 'GEELY TALISAY', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(229, 'GEELY TALISAY 5S Sales', '5SSales.GeelyTalisay', 'GEELY TALISAY', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(230, 'MITSUBISHI GORORDO 5S Utilities', '5SUtilities.MitsubishiGorordo', 'MITSUBISHI GORORDO', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(231, 'MITSUBISHI GORORDO 5S Service', '5SService.MitsubishiGorordo', 'MITSUBISHI GORORDO', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(232, 'MITSUBISHI GORORDO 5S Sales', '5SSales.MitsubishiGorordo', 'MITSUBISHI GORORDO', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(233, 'MG NRA 5S Utilities', '5SUtilities.MGNra', 'MG NRA', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(234, 'MG NRA 5S Service', '5SService.MGNra', 'MG NRA', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(235, 'MG NRA 5S Sales', '5SSales.MGNra', 'MG NRA', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(236, 'KIA NRA 5S Utilities', '5SUtilities.KIANra', 'KIA NRA', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(237, 'KIA NRA 5S Service', '5SService.KIANra', 'KIA NRA', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(238, 'KIA NRA 5S Sales', '5SSales.KIANra', 'KIA NRA', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(239, 'GEELY CEBU 5S Utilities', '5SUtilities.GeelyCebu', 'GEELY CEBU', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(240, 'GEELY CEBU 5S Service', '5SService.GeelyCebu', 'GEELY CEBU', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(241, 'GEELY CEBU 5S Sales', '5SSales.GeelyCebu', 'GEELY CEBU', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(242, 'JETOUR TALISAY 5S Utilities', '5SUtilities.JetourTalisay', 'JETOUR TALISAY', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(243, 'JETOUR TALISAY 5S Service', '5SService.JetourTalisay', 'JETOUR TALISAY', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(244, 'JETOUR TALISAY 5S Sales', '5SSales.JetourTalisay', 'JETOUR TALISAY', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(245, 'MERCEDES-BENZ BOHOL 5S Utilities', '5SUtilities.MercedesBenzBohol', 'MERCEDES-BENZ BOHOL', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(246, 'MERCEDES-BENZ BOHOL 5S Service', '5SService.MercedesBenzBohol', 'MERCEDES-BENZ BOHOL', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(247, 'MERCEDES-BENZ BOHOL 5S Sales', '5SSales.MercedesBenzBohol', 'MERCEDES-BENZ BOHOL', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(248, 'GEELY BACOLOD 5S Utilities', '5SUtilities.GeelyBacolod', 'GEELY BACOLOD', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(249, 'GEELY BACOLOD 5S Service', '5SService.GeelyBacolod', 'GEELY BACOLOD', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(250, 'GEELY BACOLOD 5S Sales', '5SSales.GeelyBacolod', 'GEELY BACOLOD', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(251, 'HONDA MANDAUE 5S Utilities', '5SUtilities.HondaMandaue', 'HONDA MANDAUE', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(252, 'HONDA MANDAUE 5S Service', '5SService.HondaMandaue', 'HONDA MANDAUE', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(253, 'HONDA MANDAUE 5S Sales', '5SSales.HondaMandaue', 'HONDA MANDAUE', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(254, 'MITSUBISHI MATINA 5S Utilities', '5SUtilities.MitsubishiMatina', 'MITSUBISHI MATINA', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(255, 'MITSUBISHI MATINA 5S Service', '5SService.MitsubishiMatina', 'MITSUBISHI MATINA', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(256, 'MITSUBISHI MATINA 5S Sales', '5SSales.MitsubishiMatina', 'MITSUBISHI MATINA', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(257, 'HYUNDAI BUHANGIN 5S Utilities', '5SUtilities.HyundaiBuhangin', 'HYUNDAI BUHANGIN', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(258, 'HYUNDAI BUHANGIN 5S Service', '5SService.HyundaiBuhangin', 'HYUNDAI BUHANGIN', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(259, 'HYUNDAI BUHANGIN 5S Sales', '5SSales.HyundaiBuhangin', 'HYUNDAI BUHANGIN', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(260, 'JAECO & OMODA LANANG 5S Utilities', '5SUtilities.JaecoOmodaLanang', 'JAECO & OMODA LANANG', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(261, 'JAECO & OMODA LANANG 5S Service', '5SService.JaecoOmodaLanang', 'JAECO & OMODA LANANG', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(262, 'JAECO & OMODA LANANG 5S Sales', '5SSales.JaecoOmodaLanang', 'JAECO & OMODA LANANG', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(263, 'MITSUBISHI DIGOS 5S Utilities', '5SUtilities.MitsubishiDigos', 'MITSUBISHI DIGOS', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(264, 'MITSUBISHI DIGOS 5S Service', '5SService.MitsubishiDigos', 'MITSUBISHI DIGOS', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(265, 'MITSUBISHI DIGOS 5S Sales', '5SSales.MitsubishiDigos', 'MITSUBISHI DIGOS', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(266, 'BRP KIDAPAWAN 5S Utilities', '5SUtilities.BRPKidapawan', 'BRP KIDAPAWAN', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(267, 'BRP KIDAPAWAN 5S Service', '5SService.BRPKidapawan', 'BRP KIDAPAWAN', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(268, 'BRP KIDAPAWAN 5S Sales', '5SSales.BRPKidapawan', 'BRP KIDAPAWAN', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(269, 'MITSUBISHI COTABATO CITY 5S Utilities', '5SUtilities.MitsubishiCotabatoCity', 'MITSUBISHI COTABATO CITY', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(270, 'MITSUBISHI COTABATO CITY 5S Service', '5SService.MitsubishiCotabatoCity', 'MITSUBISHI COTABATO CITY', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(271, 'MITSUBISHI COTABATO CITY 5S Sales', '5SSales.MitsubishiCotabatoCity', 'MITSUBISHI COTABATO CITY', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(272, 'MITSUBISHI TAGUM 5S Utilities', '5SUtilities.MitsubishiTagum', 'MITSUBISHI TAGUM', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(273, 'MITSUBISHI TAGUM 5S Service', '5SService.MitsubishiTagum', 'MITSUBISHI TAGUM', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(274, 'MITSUBISHI TAGUM 5S Sales', '5SSales.MitsubishiTagum', 'MITSUBISHI TAGUM', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(275, 'MITSUBISHI PANABO 5S Utilities', '5SUtilities.MitsubishiPanabo', 'MITSUBISHI PANABO', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(276, 'MITSUBISHI PANABO 5S Service', '5SService.MitsubishiPanabo', 'MITSUBISHI PANABO', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(277, 'MITSUBISHI PANABO 5S Sales', '5SSales.MitsubishiPanabo', 'MITSUBISHI PANABO', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(278, 'GEELY SAN FRANCISCO 5S Utilities', '5SUtilities.GeelySanFrancisco', 'GEELY SAN FRANCISCO', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(279, 'GEELY SAN FRANCISCO 5S Service', '5SService.GeelySanFrancisco', 'GEELY SAN FRANCISCO', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(280, 'GEELY SAN FRANCISCO 5S Sales', '5SSales.GeelySanFrancisco', 'GEELY SAN FRANCISCO', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(281, 'MITSUBISHI NEGROS 5S Utilities', '5SUtilities.MitsubishiNegros', 'MITSUBISHI NEGROS', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(282, 'MITSUBISHI NEGROS 5S Service', '5SService.MitsubishiNegros', 'MITSUBISHI NEGROS', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(283, 'MITSUBISHI NEGROS 5S Sales', '5SSales.MitsubishiNegros', 'MITSUBISHI NEGROS', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(284, 'MITSUBISHI BACOLOD 5S Utilities', '5SUtilities.MitsubishiBacolod', 'MITSUBISHI BACOLOD', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(285, 'MITSUBISHI BACOLOD 5S Service', '5SService.MitsubishiBacolod', 'MITSUBISHI BACOLOD', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(286, 'MITSUBISHI BACOLOD 5S Sales', '5SSales.MitsubishiBacolod', 'MITSUBISHI BACOLOD', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(287, 'MITSUBISHI CAGAYAN DE ORO 5S Utilities', '5SUtilities.MitsubishiCagayanDeOro', 'MITSUBISHI CAGAYAN DE ORO', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(288, 'MITSUBISHI CAGAYAN DE ORO 5S Service', '5SService.MitsubishiCagayanDeOro', 'MITSUBISHI CAGAYAN DE ORO', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(289, 'MITSUBISHI CAGAYAN DE ORO 5S Sales', '5SSales.MitsubishiCagayanDeOro', 'MITSUBISHI CAGAYAN DE ORO', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(290, 'HONDA BUTUAN 5S Utilities', '5SUtilities.HondaButuan', 'HONDA BUTUAN', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(291, 'HONDA BUTUAN 5S Service', '5SService.HondaButuan', 'HONDA BUTUAN', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(292, 'HONDA BUTUAN 5S Sales', '5SSales.HondaButuan', 'HONDA BUTUAN', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(293, 'KIA VALENCIA 5S Utilities', '5SUtilities.KIAValencia', 'KIA VALENCIA', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(294, 'KIA VALENCIA 5S Service', '5SService.KIAValencia', 'KIA VALENCIA', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(295, 'KIA VALENCIA 5S Sales', '5SSales.KIAValencia', 'KIA VALENCIA', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(296, 'JAECO & OMODA ILIGIAN 5S Utilities', '5SUtilities.JaecoOmodaIligian', 'JAECO & OMODA ILIGIAN', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(297, 'JAECO & OMODA ILIGIAN 5S Service', '5SService.JaecoOmodaIligian', 'JAECO & OMODA ILIGIAN', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(298, 'JAECO & OMODA ILIGIAN 5S Sales', '5SSales.JaecoOmodaIligian', 'JAECO & OMODA ILIGIAN', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(299, 'HONDA DIPOLOG 5S Utilities', '5SUtilities.HondaDipolog', 'HONDA DIPOLOG', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11');
INSERT INTO `users` (`id`, `name`, `email`, `branch`, `user_type`, `pic_assignment_type`, `account_status`, `must_change_password`, `email_verified_at`, `avatar_path`, `password`, `remember_token`, `created_at`, `updated_at`) VALUES
(300, 'HONDA DIPOLOG 5S Service', '5SService.HondaDipolog', 'HONDA DIPOLOG', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(301, 'HONDA DIPOLOG 5S Sales', '5SSales.HondaDipolog', 'HONDA DIPOLOG', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-23 22:31:11'),
(302, 'HONDA FAIRVIEW General Manager', 'GM.HondaFairview', 'HONDA FAIRVIEW', 'GM', NULL, 'active', 0, '2026-09-24 00:25:42', NULL, '$2y$12$UIZXjXAkwVfGSvECl2nTY.DNBqbYKhA7hRNCsetbf3IlzaK/OogSm', 'xOBPZDSiKzzSc638reXKE40n1g2SNtj4CCzfa5GCPDUiUmmPL7AG6iGSCVrj', '2026-09-24 00:25:42', '2026-09-24 00:25:42'),
(303, 'HONDA FAIRVIEW Branch Operations Manager', 'BOM.HondaFairview', 'HONDA FAIRVIEW', 'BOM', NULL, 'active', 0, '2026-09-24 00:25:42', NULL, '$2y$12$TSkUgru6Ady4kme.Qy46MucFs8TIWHfiNouWljMfFziDidIkbSgSG', 'av8afZhd2RZdopfX2ZllhrRcNy7noH7jXRgavdtZ6HUJoZ4bpLVtojmkR5Zu', '2026-09-24 00:25:42', '2026-09-24 00:25:42'),
(304, 'HONDA FAIRVIEW Sales Manager', 'SalesManager.HondaFairview', 'HONDA FAIRVIEW', 'SALES_MANAGER', NULL, 'active', 0, '2026-09-24 00:25:43', NULL, '$2y$12$P31/Y2D5eWGQqLZNZ8DKFORNqy5i7hWSwkzgxMEuoMxftPHLzNA2y', 'xeiSzBi8u6cGwvFHfXAcZLhHfplI9kI9CAGWU2D9dyBxeiqkoGE9qTAD61hj', '2026-09-24 00:25:43', '2026-09-24 00:25:43'),
(305, 'HONDA FAIRVIEW Aftersales Manager', 'ASM.HondaFairview', 'HONDA FAIRVIEW', 'ASM', NULL, 'active', 0, '2026-09-24 00:25:43', NULL, '$2y$12$RPISnDIoNHnQGaNgwo6b2.M5aDvbQRrIa4fx46HkTukkITcX8T.sG', 'IMAtDwYdBVFjmRTfnPiux3iwbEXakMIAUZ0Usy460sa0mgFCgyDXn1OTdFH0', '2026-09-24 00:25:44', '2026-09-24 00:25:44'),
(306, 'HONDA FAIRVIEW Customer Experience Service', 'CEService.HondaFairview', 'HONDA FAIRVIEW', 'CE SERVICE', NULL, 'active', 0, '2026-09-24 00:25:44', NULL, '$2y$12$/ndib1LxLpdhhozYZlt2SusFQDJBur2TrDR2.gt8vmU7ebJYiks0S', 'ZJBUHo2qxri33y0nWIJ2TDsUhusUaIUbQM6zduGzMFmFOokFINuRKtLxwMII', '2026-09-24 00:25:44', '2026-09-24 00:25:44'),
(307, 'HONDA FAIRVIEW Job Controller', 'JobController.HondaFairview', 'HONDA FAIRVIEW', 'JOB CONTROLLER', NULL, 'active', 0, '2026-09-24 00:25:44', NULL, '$2y$12$5P6rlG.lJxCGF6secIse0unsboZb7Sd9ypVYluO10kEcqAU/hyisC', '26IcJmF46AesUhybhMaKOKhDt1cSfyLity1FX6mVkunJUE6DF8hC02dqmR77', '2026-09-24 00:25:44', '2026-09-24 00:25:44'),
(308, 'HONDA FAIRVIEW Parts Supervisor', 'PartsSupervisor.HondaFairview', 'HONDA FAIRVIEW', 'PARTS SUPERVISOR', NULL, 'active', 0, '2026-09-24 00:25:44', NULL, '$2y$12$ZLEwQMfT9vgDPBeMcLUfz.qAvLem9QxQhG6iZGJ.cyJ/cr0Zgy9BO', 'Xa2jbsFTibuZ2Xqh9PWfCDzofD4KuJFrbmwccV3SRdfy5wuNOVOvDOwcCVLL', '2026-09-24 00:25:44', '2026-09-24 00:25:44'),
(309, 'HONDA FAIRVIEW Workshop Supervisor', 'WorkshopSup.HondaFairview', 'HONDA FAIRVIEW', 'WORKSHOP SUP', NULL, 'active', 0, '2026-09-24 00:25:44', NULL, '$2y$12$kcVZZsRxexhbNa93COmkguhCs0rVldvIQgC5hNc6x27I2HjT6NVv6', 'OxYXiERIh2LgIyB8TPBRUQAXRIyNNgBG0DCYyyBYklbSXBNE7Va5No2Ud1T4', '2026-09-24 00:25:45', '2026-09-24 00:25:45'),
(310, 'Gateway System Administrator', 'Admin.Gateway', NULL, 'SYSTEM_ADMIN', NULL, 'active', 1, '2026-09-24 01:24:18', NULL, '$2y$12$h2FE2MU4NRDh9QTdwUiNkuUWj2IHsbbgzUkFpp5aL/fFo92sjmm7K', NULL, '2026-09-24 01:24:18', '2026-09-24 01:24:18');

-- --------------------------------------------------------

--
-- Table structure for table `users_before_username_20260924`
--

CREATE TABLE `users_before_username_20260924` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `branch` varchar(255) DEFAULT NULL,
  `user_type` varchar(255) NOT NULL DEFAULT 'Employee',
  `pic_assignment_type` varchar(30) DEFAULT NULL,
  `account_status` varchar(20) NOT NULL DEFAULT 'active',
  `must_change_password` tinyint(1) NOT NULL DEFAULT 0,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `avatar_path` varchar(255) DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `remember_token` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users_before_username_20260924`
--

INSERT INTO `users_before_username_20260924` (`id`, `name`, `email`, `branch`, `user_type`, `pic_assignment_type`, `account_status`, `must_change_password`, `email_verified_at`, `avatar_path`, `password`, `remember_token`, `created_at`, `updated_at`) VALUES
(5, 'General Manager', 'gm@gateway.com', 'SUZUKI PASONG TAMO', 'ADMIN', NULL, 'active', 0, '2026-09-05 01:43:56', NULL, '$2y$12$VlZTNVXmlM2Z44Z.NrtwoeKiP6zOBjkCZBj0MpPREwDNyH26od7N.', 'LfUdkoTkPLuQIlKyegcTWH5R2J4MUbr5SgPVhxPKOHZiXM9Djf14v9pupHHz', '2026-08-06 17:48:51', '2026-09-06 16:19:42'),
(107, 'Marcus Sales (Sales Manager)', 'sm@gateway.com', 'SUZUKI PASONG TAMO', 'SALES_MANAGER', NULL, 'active', 0, '2026-09-05 01:43:56', NULL, '$2y$10$24HFdoMQkcr1WdIyiF0LZucDl3jlYgEPh/.HISQN5p208WG7D8qcq', NULL, '2026-09-05 01:43:56', '2026-09-05 01:43:56'),
(108, 'Carlo Mendoza (Aftersales Manager)', 'asm@gateway.com', 'SUZUKI PASONG TAMO', 'ASM', NULL, 'active', 0, '2026-09-05 01:43:56', NULL, '$2y$10$24HFdoMQkcr1WdIyiF0LZucDl3jlYgEPh/.HISQN5p208WG7D8qcq', NULL, '2026-09-05 01:43:56', '2026-09-05 01:43:56'),
(109, 'Maria Santos (CE Service)', 'ce@gateway.com', 'SUZUKI PASONG TAMO', 'CE SERVICE', NULL, 'active', 0, '2026-09-05 01:43:56', NULL, '$2y$10$24HFdoMQkcr1WdIyiF0LZucDl3jlYgEPh/.HISQN5p208WG7D8qcq', NULL, '2026-09-05 01:43:56', '2026-09-05 01:43:56'),
(110, 'David Cruz (Job Controller)', 'jc@gateway.com', 'SUZUKI PASONG TAMO', 'JOB CONTROLLER', NULL, 'active', 0, '2026-09-05 01:43:56', NULL, '$2y$10$24HFdoMQkcr1WdIyiF0LZucDl3jlYgEPh/.HISQN5p208WG7D8qcq', NULL, '2026-09-05 01:43:56', '2026-09-05 01:43:56'),
(111, 'Peter Reyes (Parts Supervisor)', 'parts@gateway.com', 'SUZUKI PASONG TAMO', 'PARTS SUPERVISOR', NULL, 'active', 0, '2026-09-05 01:43:56', NULL, '$2y$10$24HFdoMQkcr1WdIyiF0LZucDl3jlYgEPh/.HISQN5p208WG7D8qcq', NULL, '2026-09-05 01:43:56', '2026-09-05 01:43:56'),
(112, 'William Bautista (Workshop Supervisor)', 'ws.sup@gateway.com', 'SUZUKI PASONG TAMO', 'WORKSHOP SUP', NULL, 'active', 0, '2026-09-05 01:43:56', NULL, '$2y$10$24HFdoMQkcr1WdIyiF0LZucDl3jlYgEPh/.HISQN5p208WG7D8qcq', NULL, '2026-09-05 01:43:56', '2026-09-05 01:43:56'),
(114, 'Roberto Garcia (Branch Operations Manager)', 'bom@gateway.com', 'SUZUKI PASONG TAMO', 'BOM', NULL, 'active', 0, '2026-09-05 01:43:56', NULL, '$2y$12$ntW5yyZmjCepLfG5jkwXnuLuMUHyYnSsLbis/iSD6LXrQFyeroqv2', NULL, '2026-09-05 01:43:56', '2026-09-07 16:08:58'),
(116, '5S Utilities', 'utilities@gateway.com', 'SUZUKI PASONG TAMO', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$uXE2ugWETe9QGDYdVyerAeYPuWSRR6QSFsLFwG5QkXHUAG645xNBe', '5R0R0xvaTLAa5eD6pbH3X4IpmW3ejyR4VahSww2Jh4F6ILe7oMoAaLfwbPET', '2026-09-06 22:57:35', '2026-09-08 00:51:36'),
(117, '5S Service', 'service@gateway.com', 'SUZUKI PASONG TAMO', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$TssFYYVcrKK1fFMSFpXcle4MsrKHjiLfbTXRBX0gIC5LO6n7nLFYK', 'SKWDkNb6NVXNKG7hA14X7Bu30tGNe7xYIyJwEoY5nZZuSxPqejccUjFxk8iR', '2026-09-06 22:57:35', '2026-09-08 01:28:26'),
(118, '5S Sales', 'sales@gateway.com', 'SUZUKI PASONG TAMO', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$mYaEIUp5uQQ6vWMaYM8Hg.iIfQYuZqrmBaLC.hzUGAmBMrGl9nQne', 'p5mrJ3yGStvKa4EBgev7kMryzgMdPU3dBpIHCZdyz0Z35nK6e80sFFVxxfG6', '2026-09-06 22:57:35', '2026-09-16 18:47:56'),
(119, 'HONDA MAKATI 5S Utilities', 'honda-makati.utilities@5s.gateway.local', 'HONDA MAKATI', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(120, 'HONDA MAKATI 5S Service', 'honda-makati.service@5s.gateway.local', 'HONDA MAKATI', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(121, 'HONDA MAKATI 5S Sales', 'honda-makati.sales@5s.gateway.local', 'HONDA MAKATI', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(122, 'HYUNDAI MAKATI 5S Utilities', 'hyundai-makati.utilities@5s.gateway.local', 'HYUNDAI MAKATI', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(123, 'HYUNDAI MAKATI 5S Service', 'hyundai-makati.service@5s.gateway.local', 'HYUNDAI MAKATI', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(124, 'HYUNDAI MAKATI 5S Sales', 'hyundai-makati.sales@5s.gateway.local', 'HYUNDAI MAKATI', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(125, 'SUZUKI PASONG TAMO 5S Utilities', 'suzuki-pasong-tamo.utilities@5s.gateway.local', 'SUZUKI PASONG TAMO', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(126, 'SUZUKI PASONG TAMO 5S Service', 'suzuki-pasong-tamo.service@5s.gateway.local', 'SUZUKI PASONG TAMO', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(127, 'SUZUKI PASONG TAMO 5S Sales', 'suzuki-pasong-tamo.sales@5s.gateway.local', 'SUZUKI PASONG TAMO', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(128, 'KIA OTIS 5S Utilities', 'kia-otis.utilities@5s.gateway.local', 'KIA OTIS', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(129, 'KIA OTIS 5S Service', 'kia-otis.service@5s.gateway.local', 'KIA OTIS', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(130, 'KIA OTIS 5S Sales', 'kia-otis.sales@5s.gateway.local', 'KIA OTIS', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(131, 'HONDA FAIRVIEW 5S Utilities', 'honda-fairview.utilities@5s.gateway.local', 'HONDA FAIRVIEW', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(132, 'HONDA FAIRVIEW 5S Service', 'honda-fairview.service@5s.gateway.local', 'HONDA FAIRVIEW', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(133, 'HONDA FAIRVIEW 5S Sales', 'honda-fairview.sales@5s.gateway.local', 'HONDA FAIRVIEW', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(134, 'MITSUBISHI FAIRVIEW 5S Utilities', 'mitsubishi-fairview.utilities@5s.gateway.local', 'MITSUBISHI FAIRVIEW', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(135, 'MITSUBISHI FAIRVIEW 5S Service', 'mitsubishi-fairview.service@5s.gateway.local', 'MITSUBISHI FAIRVIEW', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(136, 'MITSUBISHI FAIRVIEW 5S Sales', 'mitsubishi-fairview.sales@5s.gateway.local', 'MITSUBISHI FAIRVIEW', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(137, 'MITSUBISHI QUEZON AVENUE 5S Utilities', 'mitsubishi-quezon-avenue.utilities@5s.gateway.local', 'MITSUBISHI QUEZON AVENUE', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(138, 'MITSUBISHI QUEZON AVENUE 5S Service', 'mitsubishi-quezon-avenue.service@5s.gateway.local', 'MITSUBISHI QUEZON AVENUE', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(139, 'MITSUBISHI QUEZON AVENUE 5S Sales', 'mitsubishi-quezon-avenue.sales@5s.gateway.local', 'MITSUBISHI QUEZON AVENUE', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(140, 'HONDA MARCOS HIGHWAY 5S Utilities', 'honda-marcos-highway.utilities@5s.gateway.local', 'HONDA MARCOS HIGHWAY', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(141, 'HONDA MARCOS HIGHWAY 5S Service', 'honda-marcos-highway.service@5s.gateway.local', 'HONDA MARCOS HIGHWAY', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(142, 'HONDA MARCOS HIGHWAY 5S Sales', 'honda-marcos-highway.sales@5s.gateway.local', 'HONDA MARCOS HIGHWAY', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(143, 'HONDA CAINTA 5S Utilities', 'honda-cainta.utilities@5s.gateway.local', 'HONDA CAINTA', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(144, 'HONDA CAINTA 5S Service', 'honda-cainta.service@5s.gateway.local', 'HONDA CAINTA', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(145, 'HONDA CAINTA 5S Sales', 'honda-cainta.sales@5s.gateway.local', 'HONDA CAINTA', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(146, 'GEELY CAINTA 5S Utilities', 'geely-cainta.utilities@5s.gateway.local', 'GEELY CAINTA', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(147, 'GEELY CAINTA 5S Service', 'geely-cainta.service@5s.gateway.local', 'GEELY CAINTA', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(148, 'GEELY CAINTA 5S Sales', 'geely-cainta.sales@5s.gateway.local', 'GEELY CAINTA', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(149, 'MITSUBISHI PASIG 5S Utilities', 'mitsubishi-pasig.utilities@5s.gateway.local', 'MITSUBISHI PASIG', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(150, 'MITSUBISHI PASIG 5S Service', 'mitsubishi-pasig.service@5s.gateway.local', 'MITSUBISHI PASIG', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(151, 'MITSUBISHI PASIG 5S Sales', 'mitsubishi-pasig.sales@5s.gateway.local', 'MITSUBISHI PASIG', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(152, 'MITSUBISHI SUCAT 5S Utilities', 'mitsubishi-sucat.utilities@5s.gateway.local', 'MITSUBISHI SUCAT', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(153, 'MITSUBISHI SUCAT 5S Service', 'mitsubishi-sucat.service@5s.gateway.local', 'MITSUBISHI SUCAT', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(154, 'MITSUBISHI SUCAT 5S Sales', 'mitsubishi-sucat.sales@5s.gateway.local', 'MITSUBISHI SUCAT', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(155, 'HONDA ALABANG 5S Utilities', 'honda-alabang.utilities@5s.gateway.local', 'HONDA ALABANG', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(156, 'HONDA ALABANG 5S Service', 'honda-alabang.service@5s.gateway.local', 'HONDA ALABANG', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(157, 'HONDA ALABANG 5S Sales', 'honda-alabang.sales@5s.gateway.local', 'HONDA ALABANG', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(158, 'MG LAS PINAS 5S Utilities', 'mg-las-pinas.utilities@5s.gateway.local', 'MG LAS PINAS', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(159, 'MG LAS PINAS 5S Service', 'mg-las-pinas.service@5s.gateway.local', 'MG LAS PINAS', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(160, 'MG LAS PINAS 5S Sales', 'mg-las-pinas.sales@5s.gateway.local', 'MG LAS PINAS', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(161, 'CHANGAN BACOOR (old Nissan) 5S Utilities', 'changan-bacoor-old-nissan.utilities@5s.gateway.local', 'CHANGAN BACOOR (old Nissan)', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(162, 'CHANGAN BACOOR (old Nissan) 5S Service', 'changan-bacoor-old-nissan.service@5s.gateway.local', 'CHANGAN BACOOR (old Nissan)', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(163, 'CHANGAN BACOOR (old Nissan) 5S Sales', 'changan-bacoor-old-nissan.sales@5s.gateway.local', 'CHANGAN BACOOR (old Nissan)', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(164, 'KIA DASMARINAS 5S Utilities', 'kia-dasmarinas.utilities@5s.gateway.local', 'KIA DASMARINAS', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(165, 'KIA DASMARINAS 5S Service', 'kia-dasmarinas.service@5s.gateway.local', 'KIA DASMARINAS', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(166, 'KIA DASMARINAS 5S Sales', 'kia-dasmarinas.sales@5s.gateway.local', 'KIA DASMARINAS', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(167, 'MG MARILAO 5S Utilities', 'mg-marilao.utilities@5s.gateway.local', 'MG MARILAO', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(168, 'MG MARILAO 5S Service', 'mg-marilao.service@5s.gateway.local', 'MG MARILAO', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(169, 'MG MARILAO 5S Sales', 'mg-marilao.sales@5s.gateway.local', 'MG MARILAO', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(170, 'MG/GEELY ANGELES 5S Utilities', 'mg-geely-angeles.utilities@5s.gateway.local', 'MG/GEELY ANGELES', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(171, 'MG/GEELY ANGELES 5S Service', 'mg-geely-angeles.service@5s.gateway.local', 'MG/GEELY ANGELES', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(172, 'MG/GEELY ANGELES 5S Sales', 'mg-geely-angeles.sales@5s.gateway.local', 'MG/GEELY ANGELES', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(173, 'GEELY TARLAC 5S Utilities', 'geely-tarlac.utilities@5s.gateway.local', 'GEELY TARLAC', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(174, 'GEELY TARLAC 5S Service', 'geely-tarlac.service@5s.gateway.local', 'GEELY TARLAC', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(175, 'GEELY TARLAC 5S Sales', 'geely-tarlac.sales@5s.gateway.local', 'GEELY TARLAC', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(176, 'HONDA ISABELA 5S Utilities', 'honda-isabela.utilities@5s.gateway.local', 'HONDA ISABELA', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(177, 'HONDA ISABELA 5S Service', 'honda-isabela.service@5s.gateway.local', 'HONDA ISABELA', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(178, 'HONDA ISABELA 5S Sales', 'honda-isabela.sales@5s.gateway.local', 'HONDA ISABELA', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(179, 'SUZUKI SANTA ROSA 5S Utilities', 'suzuki-santa-rosa.utilities@5s.gateway.local', 'SUZUKI SANTA ROSA', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(180, 'SUZUKI SANTA ROSA 5S Service', 'suzuki-santa-rosa.service@5s.gateway.local', 'SUZUKI SANTA ROSA', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(181, 'SUZUKI SANTA ROSA 5S Sales', 'suzuki-santa-rosa.sales@5s.gateway.local', 'SUZUKI SANTA ROSA', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(182, 'MITSUBISHI CALAMBA 5S Utilities', 'mitsubishi-calamba.utilities@5s.gateway.local', 'MITSUBISHI CALAMBA', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(183, 'MITSUBISHI CALAMBA 5S Service', 'mitsubishi-calamba.service@5s.gateway.local', 'MITSUBISHI CALAMBA', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(184, 'MITSUBISHI CALAMBA 5S Sales', 'mitsubishi-calamba.sales@5s.gateway.local', 'MITSUBISHI CALAMBA', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(185, 'GEELY LIPA 5S Utilities', 'geely-lipa.utilities@5s.gateway.local', 'GEELY LIPA', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(186, 'GEELY LIPA 5S Service', 'geely-lipa.service@5s.gateway.local', 'GEELY LIPA', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(187, 'GEELY LIPA 5S Sales', 'geely-lipa.sales@5s.gateway.local', 'GEELY LIPA', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(188, 'SUZUKI ALAMINOS 5S Utilities', 'suzuki-alaminos.utilities@5s.gateway.local', 'SUZUKI ALAMINOS', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(189, 'SUZUKI ALAMINOS 5S Service', 'suzuki-alaminos.service@5s.gateway.local', 'SUZUKI ALAMINOS', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(190, 'SUZUKI ALAMINOS 5S Sales', 'suzuki-alaminos.sales@5s.gateway.local', 'SUZUKI ALAMINOS', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(191, 'KIA SAN PABLO 5S Utilities', 'kia-san-pablo.utilities@5s.gateway.local', 'KIA SAN PABLO', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(192, 'KIA SAN PABLO 5S Service', 'kia-san-pablo.service@5s.gateway.local', 'KIA SAN PABLO', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(193, 'KIA SAN PABLO 5S Sales', 'kia-san-pablo.sales@5s.gateway.local', 'KIA SAN PABLO', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(194, 'MG SAN PABLO 5S Utilities', 'mg-san-pablo.utilities@5s.gateway.local', 'MG SAN PABLO', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(195, 'MG SAN PABLO 5S Service', 'mg-san-pablo.service@5s.gateway.local', 'MG SAN PABLO', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(196, 'MG SAN PABLO 5S Sales', 'mg-san-pablo.sales@5s.gateway.local', 'MG SAN PABLO', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(197, 'MITSUBISHI PILI 5S Utilities', 'mitsubishi-pili.utilities@5s.gateway.local', 'MITSUBISHI PILI', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(198, 'MITSUBISHI PILI 5S Service', 'mitsubishi-pili.service@5s.gateway.local', 'MITSUBISHI PILI', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(199, 'MITSUBISHI PILI 5S Sales', 'mitsubishi-pili.sales@5s.gateway.local', 'MITSUBISHI PILI', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(200, 'MITSUBISHI LEGAZPI 5S Utilities', 'mitsubishi-legazpi.utilities@5s.gateway.local', 'MITSUBISHI LEGAZPI', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(201, 'MITSUBISHI LEGAZPI 5S Service', 'mitsubishi-legazpi.service@5s.gateway.local', 'MITSUBISHI LEGAZPI', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(202, 'MITSUBISHI LEGAZPI 5S Sales', 'mitsubishi-legazpi.sales@5s.gateway.local', 'MITSUBISHI LEGAZPI', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(203, 'MITSUBISHI GREENHILLS 5S Utilities', 'mitsubishi-greenhills.utilities@5s.gateway.local', 'MITSUBISHI GREENHILLS', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(204, 'MITSUBISHI GREENHILLS 5S Service', 'mitsubishi-greenhills.service@5s.gateway.local', 'MITSUBISHI GREENHILLS', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(205, 'MITSUBISHI GREENHILLS 5S Sales', 'mitsubishi-greenhills.sales@5s.gateway.local', 'MITSUBISHI GREENHILLS', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(206, 'HONDA MANILA BAY 5S Utilities', 'honda-manila-bay.utilities@5s.gateway.local', 'HONDA MANILA BAY', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(207, 'HONDA MANILA BAY 5S Service', 'honda-manila-bay.service@5s.gateway.local', 'HONDA MANILA BAY', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(208, 'HONDA MANILA BAY 5S Sales', 'honda-manila-bay.sales@5s.gateway.local', 'HONDA MANILA BAY', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(209, 'HYUNDAI MANDAUE 5S Utilities', 'hyundai-mandaue.utilities@5s.gateway.local', 'HYUNDAI MANDAUE', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(210, 'HYUNDAI MANDAUE 5S Service', 'hyundai-mandaue.service@5s.gateway.local', 'HYUNDAI MANDAUE', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(211, 'HYUNDAI MANDAUE 5S Sales', 'hyundai-mandaue.sales@5s.gateway.local', 'HYUNDAI MANDAUE', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(212, 'KIA / GEELY MANDAUE 5S Utilities', 'kia-geely-mandaue.utilities@5s.gateway.local', 'KIA / GEELY MANDAUE', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(213, 'KIA / GEELY MANDAUE 5S Service', 'kia-geely-mandaue.service@5s.gateway.local', 'KIA / GEELY MANDAUE', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(214, 'KIA / GEELY MANDAUE 5S Sales', 'kia-geely-mandaue.sales@5s.gateway.local', 'KIA / GEELY MANDAUE', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(215, 'MERCEDES-BENZ MANDAUE 5S Utilities', 'mercedes-benz-mandaue.utilities@5s.gateway.local', 'MERCEDES-BENZ MANDAUE', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(216, 'MERCEDES-BENZ MANDAUE 5S Service', 'mercedes-benz-mandaue.service@5s.gateway.local', 'MERCEDES-BENZ MANDAUE', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(217, 'MERCEDES-BENZ MANDAUE 5S Sales', 'mercedes-benz-mandaue.sales@5s.gateway.local', 'MERCEDES-BENZ MANDAUE', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(218, 'OMODA & JAECOO CEBU CITY 5S Utilities', 'omoda-jaecoo-cebu-city.utilities@5s.gateway.local', 'OMODA & JAECOO CEBU CITY', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(219, 'OMODA & JAECOO CEBU CITY 5S Service', 'omoda-jaecoo-cebu-city.service@5s.gateway.local', 'OMODA & JAECOO CEBU CITY', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(220, 'OMODA & JAECOO CEBU CITY 5S Sales', 'omoda-jaecoo-cebu-city.sales@5s.gateway.local', 'OMODA & JAECOO CEBU CITY', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(221, 'MITSUBISHI TALISAY 5S Utilities', 'mitsubishi-talisay.utilities@5s.gateway.local', 'MITSUBISHI TALISAY', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(222, 'MITSUBISHI TALISAY 5S Service', 'mitsubishi-talisay.service@5s.gateway.local', 'MITSUBISHI TALISAY', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(223, 'MITSUBISHI TALISAY 5S Sales', 'mitsubishi-talisay.sales@5s.gateway.local', 'MITSUBISHI TALISAY', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(224, 'HONDA TALISAY 5S Utilities', 'honda-talisay.utilities@5s.gateway.local', 'HONDA TALISAY', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(225, 'HONDA TALISAY 5S Service', 'honda-talisay.service@5s.gateway.local', 'HONDA TALISAY', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(226, 'HONDA TALISAY 5S Sales', 'honda-talisay.sales@5s.gateway.local', 'HONDA TALISAY', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(227, 'GEELY TALISAY 5S Utilities', 'geely-talisay.utilities@5s.gateway.local', 'GEELY TALISAY', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(228, 'GEELY TALISAY 5S Service', 'geely-talisay.service@5s.gateway.local', 'GEELY TALISAY', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(229, 'GEELY TALISAY 5S Sales', 'geely-talisay.sales@5s.gateway.local', 'GEELY TALISAY', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(230, 'MITSUBISHI GORORDO 5S Utilities', 'mitsubishi-gorordo.utilities@5s.gateway.local', 'MITSUBISHI GORORDO', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(231, 'MITSUBISHI GORORDO 5S Service', 'mitsubishi-gorordo.service@5s.gateway.local', 'MITSUBISHI GORORDO', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(232, 'MITSUBISHI GORORDO 5S Sales', 'mitsubishi-gorordo.sales@5s.gateway.local', 'MITSUBISHI GORORDO', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(233, 'MG NRA 5S Utilities', 'mg-nra.utilities@5s.gateway.local', 'MG NRA', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(234, 'MG NRA 5S Service', 'mg-nra.service@5s.gateway.local', 'MG NRA', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(235, 'MG NRA 5S Sales', 'mg-nra.sales@5s.gateway.local', 'MG NRA', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(236, 'KIA NRA 5S Utilities', 'kia-nra.utilities@5s.gateway.local', 'KIA NRA', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(237, 'KIA NRA 5S Service', 'kia-nra.service@5s.gateway.local', 'KIA NRA', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(238, 'KIA NRA 5S Sales', 'kia-nra.sales@5s.gateway.local', 'KIA NRA', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(239, 'GEELY CEBU 5S Utilities', 'geely-cebu.utilities@5s.gateway.local', 'GEELY CEBU', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(240, 'GEELY CEBU 5S Service', 'geely-cebu.service@5s.gateway.local', 'GEELY CEBU', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(241, 'GEELY CEBU 5S Sales', 'geely-cebu.sales@5s.gateway.local', 'GEELY CEBU', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(242, 'JETOUR TALISAY 5S Utilities', 'jetour-talisay.utilities@5s.gateway.local', 'JETOUR TALISAY', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(243, 'JETOUR TALISAY 5S Service', 'jetour-talisay.service@5s.gateway.local', 'JETOUR TALISAY', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(244, 'JETOUR TALISAY 5S Sales', 'jetour-talisay.sales@5s.gateway.local', 'JETOUR TALISAY', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(245, 'MERCEDES-BENZ BOHOL 5S Utilities', 'mercedes-benz-bohol.utilities@5s.gateway.local', 'MERCEDES-BENZ BOHOL', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(246, 'MERCEDES-BENZ BOHOL 5S Service', 'mercedes-benz-bohol.service@5s.gateway.local', 'MERCEDES-BENZ BOHOL', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(247, 'MERCEDES-BENZ BOHOL 5S Sales', 'mercedes-benz-bohol.sales@5s.gateway.local', 'MERCEDES-BENZ BOHOL', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(248, 'GEELY BACOLOD 5S Utilities', 'geely-bacolod.utilities@5s.gateway.local', 'GEELY BACOLOD', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(249, 'GEELY BACOLOD 5S Service', 'geely-bacolod.service@5s.gateway.local', 'GEELY BACOLOD', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(250, 'GEELY BACOLOD 5S Sales', 'geely-bacolod.sales@5s.gateway.local', 'GEELY BACOLOD', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(251, 'HONDA MANDAUE 5S Utilities', 'honda-mandaue.utilities@5s.gateway.local', 'HONDA MANDAUE', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(252, 'HONDA MANDAUE 5S Service', 'honda-mandaue.service@5s.gateway.local', 'HONDA MANDAUE', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(253, 'HONDA MANDAUE 5S Sales', 'honda-mandaue.sales@5s.gateway.local', 'HONDA MANDAUE', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(254, 'MITSUBISHI MATINA 5S Utilities', 'mitsubishi-matina.utilities@5s.gateway.local', 'MITSUBISHI MATINA', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(255, 'MITSUBISHI MATINA 5S Service', 'mitsubishi-matina.service@5s.gateway.local', 'MITSUBISHI MATINA', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(256, 'MITSUBISHI MATINA 5S Sales', 'mitsubishi-matina.sales@5s.gateway.local', 'MITSUBISHI MATINA', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(257, 'HYUNDAI BUHANGIN 5S Utilities', 'hyundai-buhangin.utilities@5s.gateway.local', 'HYUNDAI BUHANGIN', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(258, 'HYUNDAI BUHANGIN 5S Service', 'hyundai-buhangin.service@5s.gateway.local', 'HYUNDAI BUHANGIN', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(259, 'HYUNDAI BUHANGIN 5S Sales', 'hyundai-buhangin.sales@5s.gateway.local', 'HYUNDAI BUHANGIN', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(260, 'JAECO & OMODA LANANG 5S Utilities', 'jaeco-omoda-lanang.utilities@5s.gateway.local', 'JAECO & OMODA LANANG', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(261, 'JAECO & OMODA LANANG 5S Service', 'jaeco-omoda-lanang.service@5s.gateway.local', 'JAECO & OMODA LANANG', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(262, 'JAECO & OMODA LANANG 5S Sales', 'jaeco-omoda-lanang.sales@5s.gateway.local', 'JAECO & OMODA LANANG', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(263, 'MITSUBISHI DIGOS 5S Utilities', 'mitsubishi-digos.utilities@5s.gateway.local', 'MITSUBISHI DIGOS', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(264, 'MITSUBISHI DIGOS 5S Service', 'mitsubishi-digos.service@5s.gateway.local', 'MITSUBISHI DIGOS', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(265, 'MITSUBISHI DIGOS 5S Sales', 'mitsubishi-digos.sales@5s.gateway.local', 'MITSUBISHI DIGOS', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(266, 'BRP KIDAPAWAN 5S Utilities', 'brp-kidapawan.utilities@5s.gateway.local', 'BRP KIDAPAWAN', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(267, 'BRP KIDAPAWAN 5S Service', 'brp-kidapawan.service@5s.gateway.local', 'BRP KIDAPAWAN', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(268, 'BRP KIDAPAWAN 5S Sales', 'brp-kidapawan.sales@5s.gateway.local', 'BRP KIDAPAWAN', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(269, 'MITSUBISHI COTABATO CITY 5S Utilities', 'mitsubishi-cotabato-city.utilities@5s.gateway.local', 'MITSUBISHI COTABATO CITY', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(270, 'MITSUBISHI COTABATO CITY 5S Service', 'mitsubishi-cotabato-city.service@5s.gateway.local', 'MITSUBISHI COTABATO CITY', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(271, 'MITSUBISHI COTABATO CITY 5S Sales', 'mitsubishi-cotabato-city.sales@5s.gateway.local', 'MITSUBISHI COTABATO CITY', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(272, 'MITSUBISHI TAGUM 5S Utilities', 'mitsubishi-tagum.utilities@5s.gateway.local', 'MITSUBISHI TAGUM', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(273, 'MITSUBISHI TAGUM 5S Service', 'mitsubishi-tagum.service@5s.gateway.local', 'MITSUBISHI TAGUM', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(274, 'MITSUBISHI TAGUM 5S Sales', 'mitsubishi-tagum.sales@5s.gateway.local', 'MITSUBISHI TAGUM', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(275, 'MITSUBISHI PANABO 5S Utilities', 'mitsubishi-panabo.utilities@5s.gateway.local', 'MITSUBISHI PANABO', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(276, 'MITSUBISHI PANABO 5S Service', 'mitsubishi-panabo.service@5s.gateway.local', 'MITSUBISHI PANABO', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(277, 'MITSUBISHI PANABO 5S Sales', 'mitsubishi-panabo.sales@5s.gateway.local', 'MITSUBISHI PANABO', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(278, 'GEELY SAN FRANCISCO 5S Utilities', 'geely-san-francisco.utilities@5s.gateway.local', 'GEELY SAN FRANCISCO', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(279, 'GEELY SAN FRANCISCO 5S Service', 'geely-san-francisco.service@5s.gateway.local', 'GEELY SAN FRANCISCO', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(280, 'GEELY SAN FRANCISCO 5S Sales', 'geely-san-francisco.sales@5s.gateway.local', 'GEELY SAN FRANCISCO', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(281, 'MITSUBISHI NEGROS 5S Utilities', 'mitsubishi-negros.utilities@5s.gateway.local', 'MITSUBISHI NEGROS', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(282, 'MITSUBISHI NEGROS 5S Service', 'mitsubishi-negros.service@5s.gateway.local', 'MITSUBISHI NEGROS', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(283, 'MITSUBISHI NEGROS 5S Sales', 'mitsubishi-negros.sales@5s.gateway.local', 'MITSUBISHI NEGROS', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(284, 'MITSUBISHI BACOLOD 5S Utilities', 'mitsubishi-bacolod.utilities@5s.gateway.local', 'MITSUBISHI BACOLOD', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(285, 'MITSUBISHI BACOLOD 5S Service', 'mitsubishi-bacolod.service@5s.gateway.local', 'MITSUBISHI BACOLOD', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(286, 'MITSUBISHI BACOLOD 5S Sales', 'mitsubishi-bacolod.sales@5s.gateway.local', 'MITSUBISHI BACOLOD', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35');
INSERT INTO `users_before_username_20260924` (`id`, `name`, `email`, `branch`, `user_type`, `pic_assignment_type`, `account_status`, `must_change_password`, `email_verified_at`, `avatar_path`, `password`, `remember_token`, `created_at`, `updated_at`) VALUES
(287, 'MITSUBISHI CAGAYAN DE ORO 5S Utilities', 'mitsubishi-cagayan-de-oro.utilities@5s.gateway.local', 'MITSUBISHI CAGAYAN DE ORO', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(288, 'MITSUBISHI CAGAYAN DE ORO 5S Service', 'mitsubishi-cagayan-de-oro.service@5s.gateway.local', 'MITSUBISHI CAGAYAN DE ORO', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(289, 'MITSUBISHI CAGAYAN DE ORO 5S Sales', 'mitsubishi-cagayan-de-oro.sales@5s.gateway.local', 'MITSUBISHI CAGAYAN DE ORO', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(290, 'HONDA BUTUAN 5S Utilities', 'honda-butuan.utilities@5s.gateway.local', 'HONDA BUTUAN', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(291, 'HONDA BUTUAN 5S Service', 'honda-butuan.service@5s.gateway.local', 'HONDA BUTUAN', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(292, 'HONDA BUTUAN 5S Sales', 'honda-butuan.sales@5s.gateway.local', 'HONDA BUTUAN', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(293, 'KIA VALENCIA 5S Utilities', 'kia-valencia.utilities@5s.gateway.local', 'KIA VALENCIA', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(294, 'KIA VALENCIA 5S Service', 'kia-valencia.service@5s.gateway.local', 'KIA VALENCIA', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(295, 'KIA VALENCIA 5S Sales', 'kia-valencia.sales@5s.gateway.local', 'KIA VALENCIA', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(296, 'JAECO & OMODA ILIGIAN 5S Utilities', 'jaeco-omoda-iligian.utilities@5s.gateway.local', 'JAECO & OMODA ILIGIAN', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(297, 'JAECO & OMODA ILIGIAN 5S Service', 'jaeco-omoda-iligian.service@5s.gateway.local', 'JAECO & OMODA ILIGIAN', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(298, 'JAECO & OMODA ILIGIAN 5S Sales', 'jaeco-omoda-iligian.sales@5s.gateway.local', 'JAECO & OMODA ILIGIAN', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(299, 'HONDA DIPOLOG 5S Utilities', 'honda-dipolog.utilities@5s.gateway.local', 'HONDA DIPOLOG', '5S_UTILITIES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(300, 'HONDA DIPOLOG 5S Service', 'honda-dipolog.service@5s.gateway.local', 'HONDA DIPOLOG', '5S_SERVICE', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(301, 'HONDA DIPOLOG 5S Sales', 'honda-dipolog.sales@5s.gateway.local', 'HONDA DIPOLOG', '5S_SALES', NULL, 'active', 0, '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35');

-- --------------------------------------------------------

--
-- Table structure for table `user_usage_events`
--

CREATE TABLE `user_usage_events` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `channel` varchar(12) NOT NULL,
  `event` varchar(40) NOT NULL DEFAULT 'login',
  `occurred_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_usage_events`
--

INSERT INTO `user_usage_events` (`id`, `user_id`, `channel`, `event`, `occurred_at`) VALUES
(49, 5, 'web', 'login', '2026-09-27 19:34:51');

-- --------------------------------------------------------

--
-- Table structure for table `web_push_subscriptions`
--

CREATE TABLE `web_push_subscriptions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `endpoint_hash` char(64) NOT NULL,
  `endpoint` text NOT NULL,
  `public_key` varchar(100) NOT NULL,
  `auth_token` varchar(32) NOT NULL,
  `device_token_hash` char(64) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `web_push_subscriptions`
--

INSERT INTO `web_push_subscriptions` (`id`, `user_id`, `endpoint_hash`, `endpoint`, `public_key`, `auth_token`, `device_token_hash`, `created_at`, `updated_at`) VALUES
(9, 5, 'f8c6522e7e9024edd3094e22c4a4c06f7eaed76e9d6448c60b060609e50166d8', 'https://fcm.googleapis.com/fcm/send/cBDCeBjGwXQ:APA91bH4V5_exANwfVevqXQHC911KMB42k2vX0Gr5XwylyXR8375BG_J9-DKzvWV6SSEvN1xitRLr7JCISwP3CMzNevefJWq3ltiG0ZqXgQWoTZ1ZAPoEA8D0li2ug08p7tQs9vZLZD1', 'BGXuvyQEUXqbTZS1WiyR-KqzwtJZ1boRfxGAJ9kxjPfeZ3oEYvz2SO-n8dO5ERuNt6x7B-KeBpKiBbvNYpPnCIk', 'R5dv3Nq3beR3MprqTYjyUQ', '8ef273af428a8345de612a47697d93e7b7f364784984e7c6986adc32796e86fa', '2026-09-16 17:32:50', '2026-09-16 17:32:50');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `branch_restrooms`
--
ALTER TABLE `branch_restrooms`
  ADD PRIMARY KEY (`id`),
  ADD KEY `branch_restrooms_branch_index` (`branch`);

--
-- Indexes for table `cache`
--
ALTER TABLE `cache`
  ADD PRIMARY KEY (`key`),
  ADD KEY `cache_expiration_index` (`expiration`);

--
-- Indexes for table `cache_locks`
--
ALTER TABLE `cache_locks`
  ADD PRIMARY KEY (`key`),
  ADD KEY `cache_locks_expiration_index` (`expiration`);

--
-- Indexes for table `checklist_items`
--
ALTER TABLE `checklist_items`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `checklist_items_checklist_template_id_key_unique` (`checklist_template_id`,`key`),
  ADD KEY `checklist_items_checklist_section_id_sort_order_index` (`checklist_section_id`,`sort_order`),
  ADD KEY `checklist_items_is_active_index` (`is_active`);

--
-- Indexes for table `checklist_responses`
--
ALTER TABLE `checklist_responses`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `checklist_response_item_unique` (`checklist_submission_id`,`item_key`),
  ADD KEY `checklist_responses_checklist_item_id_status_index` (`checklist_item_id`,`status`);

--
-- Indexes for table `checklist_sections`
--
ALTER TABLE `checklist_sections`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `checklist_sections_checklist_template_id_key_unique` (`checklist_template_id`,`key`),
  ADD KEY `checklist_sections_checklist_template_id_sort_order_index` (`checklist_template_id`,`sort_order`),
  ADD KEY `checklist_sections_is_active_index` (`is_active`);

--
-- Indexes for table `checklist_submissions`
--
ALTER TABLE `checklist_submissions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `checklist_submissions_submitted_by_user_id_foreign` (`submitted_by_user_id`),
  ADD KEY `checklist_submission_lookup` (`checklist_template_id`,`audit_date`,`scope_key`,`status`),
  ADD KEY `checklist_submissions_status_submitted_at_index` (`status`,`submitted_at`),
  ADD KEY `checklist_submission_submitter_type_time` (`submitted_by_user_type`,`submitted_at`),
  ADD KEY `checklist_submission_user_lookup` (`user_id`,`checklist_template_id`,`audit_date`,`scope_key`,`status`),
  ADD KEY `checklist_submissions_branch_restroom_id_foreign` (`branch_restroom_id`),
  ADD KEY `checklist_submissions_restroom_area_index` (`restroom_area`),
  ADD KEY `checklist_submissions_restroom_gender_index` (`restroom_gender`);

--
-- Indexes for table `checklist_templates`
--
ALTER TABLE `checklist_templates`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `checklist_templates_slug_unique` (`slug`),
  ADD KEY `checklist_templates_is_active_index` (`is_active`);

--
-- Indexes for table `dealer_checklist_settings`
--
ALTER TABLE `dealer_checklist_settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `dealer_checklist_settings_dealer_category_unique` (`dealer`,`category`),
  ADD KEY `dealer_checklist_settings_updated_by_user_id_foreign` (`updated_by_user_id`),
  ADD KEY `dealer_checklist_settings_category_is_enabled_index` (`category`,`is_enabled`);

--
-- Indexes for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`);

--
-- Indexes for table `jobs`
--
ALTER TABLE `jobs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `jobs_queue_index` (`queue`);

--
-- Indexes for table `job_batches`
--
ALTER TABLE `job_batches`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `notifications_notifiable_type_notifiable_id_index` (`notifiable_type`,`notifiable_id`),
  ADD KEY `notifications_recipient_read_index` (`notifiable_type`,`notifiable_id`,`read_at`);

--
-- Indexes for table `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  ADD PRIMARY KEY (`email`);

--
-- Indexes for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  ADD KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`),
  ADD KEY `personal_access_tokens_expires_at_index` (`expires_at`);

--
-- Indexes for table `reports`
--
ALTER TABLE `reports`
  ADD PRIMARY KEY (`id`),
  ADD KEY `reports_checklist_submission_id_foreign` (`checklist_submission_id`),
  ADD KEY `reports_generated_by_user_id_foreign` (`generated_by_user_id`),
  ADD KEY `reports_type_generated_at_index` (`type`,`generated_at`),
  ADD KEY `reports_checklist_template_id_generated_at_index` (`checklist_template_id`,`generated_at`);

--
-- Indexes for table `sessions`
--
ALTER TABLE `sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sessions_user_id_index` (`user_id`),
  ADD KEY `sessions_last_activity_index` (`last_activity`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_email_unique` (`email`),
  ADD KEY `users_pic_assignment_type_index` (`pic_assignment_type`);

--
-- Indexes for table `users_before_username_20260924`
--
ALTER TABLE `users_before_username_20260924`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_email_unique` (`email`),
  ADD KEY `users_pic_assignment_type_index` (`pic_assignment_type`);

--
-- Indexes for table `user_usage_events`
--
ALTER TABLE `user_usage_events`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_usage_events_channel_occurred_at_index` (`channel`,`occurred_at`),
  ADD KEY `user_usage_events_user_id_occurred_at_index` (`user_id`,`occurred_at`);

--
-- Indexes for table `web_push_subscriptions`
--
ALTER TABLE `web_push_subscriptions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `web_push_subscriptions_endpoint_hash_unique` (`endpoint_hash`),
  ADD KEY `web_push_subscriptions_user_id_foreign` (`user_id`),
  ADD KEY `web_push_subscriptions_device_token_hash_index` (`device_token_hash`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `branch_restrooms`
--
ALTER TABLE `branch_restrooms`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=219;

--
-- AUTO_INCREMENT for table `checklist_items`
--
ALTER TABLE `checklist_items`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=562;

--
-- AUTO_INCREMENT for table `checklist_responses`
--
ALTER TABLE `checklist_responses`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4174;

--
-- AUTO_INCREMENT for table `checklist_sections`
--
ALTER TABLE `checklist_sections`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=107;

--
-- AUTO_INCREMENT for table `checklist_submissions`
--
ALTER TABLE `checklist_submissions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=124;

--
-- AUTO_INCREMENT for table `checklist_templates`
--
ALTER TABLE `checklist_templates`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `dealer_checklist_settings`
--
ALTER TABLE `dealer_checklist_settings`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jobs`
--
ALTER TABLE `jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=136;

--
-- AUTO_INCREMENT for table `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=38;

--
-- AUTO_INCREMENT for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=452;

--
-- AUTO_INCREMENT for table `reports`
--
ALTER TABLE `reports`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=143;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=311;

--
-- AUTO_INCREMENT for table `users_before_username_20260924`
--
ALTER TABLE `users_before_username_20260924`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=302;

--
-- AUTO_INCREMENT for table `user_usage_events`
--
ALTER TABLE `user_usage_events`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=50;

--
-- AUTO_INCREMENT for table `web_push_subscriptions`
--
ALTER TABLE `web_push_subscriptions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=44;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `checklist_items`
--
ALTER TABLE `checklist_items`
  ADD CONSTRAINT `checklist_items_checklist_section_id_foreign` FOREIGN KEY (`checklist_section_id`) REFERENCES `checklist_sections` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `checklist_items_checklist_template_id_foreign` FOREIGN KEY (`checklist_template_id`) REFERENCES `checklist_templates` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `checklist_responses`
--
ALTER TABLE `checklist_responses`
  ADD CONSTRAINT `checklist_responses_checklist_item_id_foreign` FOREIGN KEY (`checklist_item_id`) REFERENCES `checklist_items` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `checklist_responses_checklist_submission_id_foreign` FOREIGN KEY (`checklist_submission_id`) REFERENCES `checklist_submissions` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `checklist_sections`
--
ALTER TABLE `checklist_sections`
  ADD CONSTRAINT `checklist_sections_checklist_template_id_foreign` FOREIGN KEY (`checklist_template_id`) REFERENCES `checklist_templates` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `checklist_submissions`
--
ALTER TABLE `checklist_submissions`
  ADD CONSTRAINT `checklist_submissions_branch_restroom_id_foreign` FOREIGN KEY (`branch_restroom_id`) REFERENCES `branch_restrooms` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `checklist_submissions_checklist_template_id_foreign` FOREIGN KEY (`checklist_template_id`) REFERENCES `checklist_templates` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `checklist_submissions_submitted_by_user_id_foreign` FOREIGN KEY (`submitted_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `checklist_submissions_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `dealer_checklist_settings`
--
ALTER TABLE `dealer_checklist_settings`
  ADD CONSTRAINT `dealer_checklist_settings_updated_by_user_id_foreign` FOREIGN KEY (`updated_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `reports`
--
ALTER TABLE `reports`
  ADD CONSTRAINT `reports_checklist_submission_id_foreign` FOREIGN KEY (`checklist_submission_id`) REFERENCES `checklist_submissions` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `reports_checklist_template_id_foreign` FOREIGN KEY (`checklist_template_id`) REFERENCES `checklist_templates` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `reports_generated_by_user_id_foreign` FOREIGN KEY (`generated_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `user_usage_events`
--
ALTER TABLE `user_usage_events`
  ADD CONSTRAINT `user_usage_events_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `web_push_subscriptions`
--
ALTER TABLE `web_push_subscriptions`
  ADD CONSTRAINT `web_push_subscriptions_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
