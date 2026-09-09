-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Sep 08, 2026 at 03:23 AM
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
('laravel-cache-5c785c036466adea360111aa28563bfd556b5fba', 'i:2;', 1788595772),
('laravel-cache-5c785c036466adea360111aa28563bfd556b5fba:timer', 'i:1788595772;', 1788595772),
('laravel-cache-6cb5bb9b67d5af5e7f80c02dc185aac943ccb0d3', 'i:1;', 1788830230),
('laravel-cache-6cb5bb9b67d5af5e7f80c02dc185aac943ccb0d3:timer', 'i:1788830230;', 1788830230),
('laravel-cache-itmanager@gateway.com|127.0.0.1', 'i:1;', 1787962204),
('laravel-cache-itmanager@gateway.com|127.0.0.1:timer', 'i:1787962204;', 1787962204),
('laravel-cache-mindanao.technician@gateway.com|127.0.0.1', 'i:1;', 1787962206),
('laravel-cache-mindanao.technician@gateway.com|127.0.0.1:timer', 'i:1787962206;', 1787962206);

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
(528, 3, 96, 'restroom-item-1', 'All are working', 0, '{\"number\":1,\"response_type\":\"time_slots\",\"subject\":\"Lighting\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(529, 3, 96, 'restroom-item-2', 'Light switch are working', 1, '{\"number\":2,\"response_type\":\"time_slots\",\"subject\":\"Lighting\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(530, 3, 97, 'restroom-item-3', 'All exhaust fans are working', 0, '{\"number\":3,\"response_type\":\"time_slots\",\"subject\":\"Exhaust\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(531, 3, 97, 'restroom-item-4', 'All exhaust fans are clean', 1, '{\"number\":4,\"response_type\":\"time_slots\",\"subject\":\"Exhaust\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(532, 3, 97, 'restroom-item-5', 'No foul smell is present', 2, '{\"number\":5,\"response_type\":\"time_slots\",\"subject\":\"Exhaust\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(533, 3, 98, 'restroom-item-6', 'All are clean', 0, '{\"number\":6,\"response_type\":\"time_slots\",\"subject\":\"Floor, Wall & Ceiling\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(534, 3, 98, 'restroom-item-7', 'Tiles are complete and no cracks', 1, '{\"number\":7,\"response_type\":\"time_slots\",\"subject\":\"Floor, Wall & Ceiling\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(535, 3, 98, 'restroom-item-8', 'Floor drain is working', 2, '{\"number\":8,\"response_type\":\"time_slots\",\"subject\":\"Floor, Wall & Ceiling\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(536, 3, 99, 'restroom-item-9', 'All are clean', 0, '{\"number\":9,\"response_type\":\"time_slots\",\"subject\":\"Toilet Bowl\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(537, 3, 99, 'restroom-item-10', 'Flush is working properly', 1, '{\"number\":10,\"response_type\":\"time_slots\",\"subject\":\"Toilet Bowl\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(538, 3, 99, 'restroom-item-11', 'Bidet is working properly', 2, '{\"number\":11,\"response_type\":\"time_slots\",\"subject\":\"Toilet Bowl\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(539, 3, 99, 'restroom-item-12', 'No water leak', 3, '{\"number\":12,\"response_type\":\"time_slots\",\"subject\":\"Toilet Bowl\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(540, 3, 100, 'restroom-item-13', 'All are clean', 0, '{\"number\":13,\"response_type\":\"time_slots\",\"subject\":\"Urinal\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(541, 3, 100, 'restroom-item-14', 'Flush is working properly', 1, '{\"number\":14,\"response_type\":\"time_slots\",\"subject\":\"Urinal\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(542, 3, 100, 'restroom-item-15', 'No water leak', 2, '{\"number\":15,\"response_type\":\"time_slots\",\"subject\":\"Urinal\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(543, 3, 101, 'restroom-item-16', 'All are clean', 0, '{\"number\":16,\"response_type\":\"time_slots\",\"subject\":\"Sink and faucet\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(544, 3, 101, 'restroom-item-17', 'Faucet is working properly', 1, '{\"number\":17,\"response_type\":\"time_slots\",\"subject\":\"Sink and faucet\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(545, 3, 101, 'restroom-item-18', 'Drain is working properly', 2, '{\"number\":18,\"response_type\":\"time_slots\",\"subject\":\"Sink and faucet\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(546, 3, 101, 'restroom-item-19', 'No water leak', 3, '{\"number\":19,\"response_type\":\"time_slots\",\"subject\":\"Sink and faucet\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(547, 3, 102, 'restroom-item-20', 'Toilet tissue is available', 0, '{\"number\":20,\"response_type\":\"time_slots\",\"subject\":\"Toilet Accessories\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(548, 3, 102, 'restroom-item-21', 'Toilet tissue holder is available', 1, '{\"number\":21,\"response_type\":\"time_slots\",\"subject\":\"Toilet Accessories\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(549, 3, 102, 'restroom-item-22', 'Liquid Soap is available', 2, '{\"number\":22,\"response_type\":\"time_slots\",\"subject\":\"Toilet Accessories\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(550, 3, 102, 'restroom-item-23', 'Liquid Soap Dispenser is available', 3, '{\"number\":23,\"response_type\":\"time_slots\",\"subject\":\"Toilet Accessories\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(551, 3, 102, 'restroom-item-24', 'Hand  Drier is working', 4, '{\"number\":24,\"response_type\":\"time_slots\",\"subject\":\"Toilet Accessories\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(552, 3, 102, 'restroom-item-25', 'Mirror is clean', 5, '{\"number\":25,\"response_type\":\"time_slots\",\"subject\":\"Toilet Accessories\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(553, 3, 102, 'restroom-item-26', 'Mirror has no damage', 6, '{\"number\":26,\"response_type\":\"time_slots\",\"subject\":\"Toilet Accessories\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(554, 3, 103, 'restroom-item-27', 'All are clean', 0, '{\"number\":27,\"response_type\":\"time_slots\",\"subject\":\"Trash Bin\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(555, 3, 103, 'restroom-item-28', 'All bin with trash bag', 1, '{\"number\":28,\"response_type\":\"time_slots\",\"subject\":\"Trash Bin\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(556, 3, 104, 'restroom-item-29', 'Water pressure is ok', 0, '{\"number\":29,\"response_type\":\"time_slots\",\"subject\":\"Water Supply\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(557, 3, 105, 'restroom-item-30', 'Are stored properly', 0, '{\"number\":30,\"response_type\":\"time_slots\",\"subject\":\"Cleaning Materials\"}', 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(143, 4, 26, 'item-1', 'Is the parking area clearly visible and easy for customers to find, with well-defined parking lines and proper signage?', 0, '{\"number\":1}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(144, 4, 26, 'item-2', 'Is the parking area clean, free from dirt and debris, and well maintained?', 1, '{\"number\":2}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(145, 4, 27, 'item-3', 'Is the area clean and well-organized, with no unnecessary items on the floor?', 0, '{\"number\":3}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(146, 4, 27, 'item-4', 'Are there no broken or damaged tiles?', 1, '{\"number\":4}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(147, 4, 27, 'item-5', 'Are all the lights in the showroom functioning properly?', 2, '{\"number\":5}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(148, 4, 27, 'item-6', 'Are the sales materials (posters, banners, and illuminated signage) current, well-maintained, clean, and properly organized?', 3, '{\"number\":6}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(149, 4, 27, 'item-7', 'Are the windows clean and free from fingerprints, watermarks, tape, or any other marks?', 4, '{\"number\":7}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(150, 4, 27, 'item-8', 'Are the ceilings and walls free from dirt, damage, and water leakage?', 5, '{\"number\":8}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(151, 4, 27, 'item-9', 'Are the sales negotiation tables and chairs clean and properly sanitized?', 6, '{\"number\":9}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(152, 4, 27, 'item-10', 'Is free Wi-Fi available and easily accessible to customers?', 7, '{\"number\":10}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(153, 4, 27, 'item-11', 'Is the ventilation and A/C system adequate and fully operational?', 8, '{\"number\":11}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(154, 4, 28, 'item-12', 'Is the reception area kept neat and tidy, with the surroundings free from dirt, waste, and visible personal belongings?', 0, '{\"number\":12}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(155, 4, 28, 'item-13', 'Are the reception counter and chairs clean and free from damage?', 1, '{\"number\":13}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(156, 4, 29, 'item-14', 'Is the vehicle display area clean, free from dirt and waste, and properly sanitized?', 0, '{\"number\":14}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(157, 4, 29, 'item-15', 'Is at least one unit of each MG model displayed in the showroom, including the latest model year and a mix of high-end variants?', 1, '{\"number\":15}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(158, 4, 29, 'item-16', 'Is an information stand available near each display unit?', 2, '{\"number\":16}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(159, 4, 29, 'item-17', 'Are the displayed vehicles clean and free of protective coverings?', 3, '{\"number\":17}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(160, 4, 29, 'item-18', 'Are the engine compartments clean?', 4, '{\"number\":18}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(161, 4, 29, 'item-19', 'Are the display units unlocked?', 5, '{\"number\":19}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(162, 4, 29, 'item-20', 'Are genuine floor mats installed, with no paper mats in use?', 6, '{\"number\":20}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(163, 4, 29, 'item-21', 'Is the battery charged or connected to a floor power supply, with all electrical equipment functioning properly?', 7, '{\"number\":21}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(164, 4, 29, 'item-22', 'Are the vehicle interiors clean?', 8, '{\"number\":22}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(165, 4, 29, 'item-23', 'Is sufficient space maintained between the vehicles?', 9, '{\"number\":23}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(166, 4, 29, 'item-24', 'Are the test-drive units available, organized, and properly sanitized?', 10, '{\"number\":24}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(167, 4, 30, 'item-25', 'Are the necessary supplies, such as paper products, soap, and hand-drying facilities, available?', 0, '{\"number\":25}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(168, 4, 30, 'item-26', 'Is the restroom free from dirt and waste, including the floor, walls, and tiles?', 1, '{\"number\":26}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(169, 4, 30, 'item-27', 'Are the sinks and faucets in proper working condition?', 2, '{\"number\":27}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(170, 4, 30, 'item-28', 'Are the toilet bowls and urinals in proper working condition?', 3, '{\"number\":28}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(171, 4, 30, 'item-29', 'Is the female restroom clean and sanitized, with no water splashes around the sink or unnecessary items on the floor?', 4, '{\"number\":29}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(172, 4, 30, 'item-30', 'Is the male restroom clean and sanitized, with no water splashes around the sink or unnecessary items on the floor?', 5, '{\"number\":30}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(173, 4, 30, 'item-31', 'Is the PWD restroom clean and sanitized, with no water splashes around the sink or unnecessary items on the floor?', 6, '{\"number\":31}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(174, 4, 30, 'item-32', 'Is the restroom checklist updated?', 7, '{\"number\":32}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(175, 4, 31, 'item-33', 'Are complimentary snacks, such as biscuits, available?', 0, '{\"number\":33}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(176, 4, 31, 'item-34', 'Are complimentary refreshments, including coffee and water, available?', 1, '{\"number\":34}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(177, 4, 31, 'item-35', 'Are the seats and sofas comfortable, undamaged, and properly sanitized?', 2, '{\"number\":35}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(178, 4, 31, 'item-36', 'Is the LED television in working condition and well maintained?', 3, '{\"number\":36}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(179, 4, 31, 'item-37', 'Is the ventilation and A/C system adequate and fully operational?', 4, '{\"number\":37}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(180, 4, 31, 'item-38', 'Is free Wi-Fi available and easily accessible to customers?', 5, '{\"number\":38}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(181, 4, 32, 'item-39', 'Are the sales executives wearing the prescribed uniform and ID badge?', 0, '{\"number\":39}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(182, 4, 32, 'item-40', 'Are the sales executives well-groomed and dressed in the proper uniform?', 1, '{\"number\":40}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(183, 4, 32, 'item-41', 'Do the sales executives have the complete Sales Kit, including the price list, business cards, and bank application form?', 2, '{\"number\":41}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(184, 5, 33, 'item-1', 'Is the service parking area clearly visible and easy for customers to find, with well-defined parking lines and proper signage?', 0, '{\"number\":1}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(185, 5, 33, 'item-2', 'Is the parking area clean, free from dirt and debris, and well maintained?', 1, '{\"number\":2}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(186, 5, 34, 'item-3', 'Is the area clean and well-organized, with no unnecessary items on the floor?', 0, '{\"number\":3}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(187, 5, 34, 'item-4', 'Are there no broken or damaged tiles?', 1, '{\"number\":4}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(188, 5, 34, 'item-5', 'Are all the lights in the service reception area functioning properly?', 2, '{\"number\":5}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(189, 5, 34, 'item-6', 'Are the windows clean and free from fingerprints, watermarks, tape, or any other marks?', 3, '{\"number\":6}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(190, 5, 34, 'item-7', 'Are the ceilings and walls free from dirt, damage, and water leakage?', 4, '{\"number\":7}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(191, 5, 34, 'item-8', 'Are the service reception tables and chairs clean and properly sanitized?', 5, '{\"number\":8}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(192, 5, 34, 'item-9', 'Is free Wi-Fi available and easily accessible to customers?', 6, '{\"number\":9}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(193, 5, 34, 'item-10', 'Is the ventilation and A/C system adequate and fully operational?', 7, '{\"number\":10}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(194, 5, 34, 'item-11', 'Are the service reception counter and chairs clean and free from damage?', 8, '{\"number\":11}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(195, 5, 35, 'item-12', 'Is the working bay clean, free from dirt and waste, and properly sanitized?', 0, '{\"number\":12}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(196, 5, 35, 'item-13', 'Are all trolleys stored within the painted work bay when not in use, with no unnecessary items such as drinking bottles or shoes left behind?', 1, '{\"number\":13}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(197, 5, 35, 'item-14', 'Are there no used parts or empty plastic containers left in the work bay?', 2, '{\"number\":14}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(198, 5, 35, 'item-15', 'Are the lifters clean and returned to their normal down position when not in use and at the end of working hours?', 3, '{\"number\":15}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(199, 5, 35, 'item-16', 'Are the vehicle windows closed at all times, except when repairs are in progress?', 4, '{\"number\":16}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(200, 5, 35, 'item-17', 'Are the tools organized, complete, and placed in their proper locations?', 5, '{\"number\":17}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(201, 5, 36, 'item-18', 'Are the necessary supplies, such as paper products, soap, and hand-drying facilities, available?', 0, '{\"number\":18}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(202, 5, 36, 'item-19', 'Is the restroom free from dirt and waste, including the floor, walls, and tiles?', 1, '{\"number\":19}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(203, 5, 36, 'item-20', 'Are the sinks and faucets in proper working condition?', 2, '{\"number\":20}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(204, 5, 36, 'item-21', 'Are the toilet bowls and urinals in proper working condition?', 3, '{\"number\":21}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(205, 5, 36, 'item-22', 'Is the female restroom clean and sanitized, with no water splashes around the sink or unnecessary items on the floor?', 4, '{\"number\":22}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(206, 5, 36, 'item-23', 'Is the male restroom clean and sanitized, with no water splashes around the sink or unnecessary items on the floor?', 5, '{\"number\":23}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(207, 5, 36, 'item-24', 'Is the PWD restroom clean and sanitized, with no water splashes around the sink or unnecessary items on the floor?', 6, '{\"number\":24}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(208, 5, 36, 'item-25', 'Is the restroom checklist updated?', 7, '{\"number\":25}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(209, 5, 37, 'item-26', 'Are complimentary snacks, such as biscuits, available?', 0, '{\"number\":26}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(210, 5, 37, 'item-27', 'Are complimentary refreshments, including coffee and water, available?', 1, '{\"number\":27}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(211, 5, 37, 'item-28', 'Are the seats and sofas comfortable, undamaged, and properly sanitized?', 2, '{\"number\":28}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(212, 5, 37, 'item-29', 'Is the LED television in working condition and well maintained?', 3, '{\"number\":29}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(213, 5, 37, 'item-30', 'Is the ventilation and A/C system adequate and fully operational?', 4, '{\"number\":30}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(214, 5, 37, 'item-31', 'Is free Wi-Fi available and easily accessible to customers?', 5, '{\"number\":31}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(215, 5, 38, 'item-32', 'Are the Service frontliners wearing the prescribed uniform and ID badge?', 0, '{\"number\":32}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(216, 5, 38, 'item-33', 'Are the Service frontliners well-groomed and dressed in the proper uniform?', 1, '{\"number\":33}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(307, 6, 83, 'dos-1', 'Fascia or badge sign and letterings are complete, undamaged, clean, no watermarks, no obstructions, no discoloration and stains', 1, '{\"number\":1,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Facade\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"property_management\",\"how_to_check\":\"1. Check through observation if it meets the MMPC VI Standard Requirements\"}', 1, '2026-09-05 08:08:23', '2026-09-07 02:38:51'),
(308, 6, 83, 'dos-2', 'Pylon (Single/Two-Post / Tower / Wall Projecting) sign/s and letterings are complete, undamaged, clean, no watermarks, no obstructions, no discoloration and stains', 2, '{\"number\":2,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Facade\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"property_management\",\"how_to_check\":\"1. Check through observation if it meets the MMPC VI Standard Requirements\"}', 1, '2026-09-05 08:08:23', '2026-09-07 02:38:51'),
(309, 6, 83, 'dos-3', 'All exterior Visual Identity including building walls, exterior paint and finishes, are clean and free from damage.', 3, '{\"number\":3,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Facade\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"property_management\",\"how_to_check\":\"1. Check through observation if it meets the MMPC VI Standard Requirements\"}', 1, '2026-09-05 08:08:23', '2026-09-07 02:38:51'),
(310, 6, 83, 'dos-4', 'Showroom glass is clean, free from cracks, scratches, damage, dust, stains and water marks', 4, '{\"number\":4,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Facade\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"property_management\",\"how_to_check\":\"1. Check through observation if compliant\"}', 1, '2026-09-05 08:08:23', '2026-09-07 02:38:51'),
(311, 6, 83, 'dos-5', '\"Customer Parking\" signs are available, undamaged and well maintained', 5, '{\"number\":5,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Facade\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"property_management\",\"how_to_check\":\"1. Check through observation if it meets the MMPC VI Standard Requirements\"}', 1, '2026-09-05 08:08:23', '2026-09-07 02:38:51'),
(312, 6, 83, 'dos-6', 'No new units \"stock\" parked in customer parking area.', 6, '{\"number\":6,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Facade\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"\",\"escalation\":\"\",\"how_to_check\":\"1. Check through observation if compliant\"}', 1, '2026-09-05 08:08:23', '2026-09-07 02:38:51'),
(313, 6, 83, 'dos-7', 'PWD parking slot and ramp with railings should be unobstructed and painted with standard PWD Logo.', 7, '{\"number\":7,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Facade\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"property_management\",\"how_to_check\":\"1. Check through observation if compliant\"}', 1, '2026-09-05 08:08:23', '2026-09-07 02:38:51'),
(314, 6, 83, 'dos-13', 'Reception Desk is installed in the entrance following the VI Standards; desk is clean, organized, and free of unecessary items; accent wall remains free of any designs', 8, '{\"number\":13,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check if it meets the MMPC VI Standard Requirements\\n2. Check if there are no designs on the accent wall\\n3. Check if the reception desk is clean, organized, and free of unnecessary items (5S)\"}', 1, '2026-09-05 08:08:23', '2026-09-07 02:38:51'),
(315, 6, 83, 'dos-14', 'No duplicate vehicle model variants were displayed', 9, '{\"number\":14,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check if all displayed units have no duplicate vehicle model variants\\n\\nNote: Check the unit inventory (if necessary)\"}', 1, '2026-09-05 08:08:23', '2026-09-07 02:38:51'),
(316, 6, 83, 'dos-15', 'Display units are clean and in good condition (no dents, scratches, fingerprints, etc.)', 10, '{\"number\":15,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check if the display units are compliant\"}', 1, '2026-09-05 08:08:23', '2026-09-07 02:38:51'),
(317, 6, 83, 'dos-16', 'All displayed cars have their corresponding and updated specs stands.', 11, '{\"number\":16,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check if all displayed units have corresponding specs stands\\n2. Check if the specs sheet is updated and matches the displayed unit\"}', 1, '2026-09-05 08:08:23', '2026-09-07 02:38:51'),
(318, 6, 83, 'dos-23', 'Showroom Tiles or tiles has no damages', 16, '{\"number\":23,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"property_management\",\"how_to_check\":\"1. Check if there are no broken or damaged tiles on the showroom floor\"}', 1, '2026-09-05 08:08:23', '2026-09-07 02:38:51'),
(319, 6, 83, 'dos-24', 'Ceiling of showroom should be cob web free; no discoloration and stains', 17, '{\"number\":24,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"property_management\",\"how_to_check\":\"1. Check if the showroom ceiling is clean and free from cob web, no discolorations and stains\"}', 1, '2026-09-05 08:08:23', '2026-09-07 02:38:51'),
(320, 6, 83, 'dos-25', 'No busted lights in the Showroom Area and Customer Lounge', 18, '{\"number\":25,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"property_management\",\"how_to_check\":\"1. Check if there are no busted lights in the showroom\"}', 1, '2026-09-05 08:08:23', '2026-09-07 02:38:51'),
(321, 6, 83, 'dos-26', 'Directional signs to Sales, Service, and Parts follow MMPC VI standards, undamaged and visible.', 19, '{\"number\":26,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"property_management\",\"how_to_check\":\"1. Check if the directional signages are compliant\"}', 1, '2026-09-05 08:08:23', '2026-09-07 02:38:51'),
(322, 6, 83, 'dos-27', 'All showroom lighted signages, banners and tarpaulins are up to date and in good condition and no damages', 20, '{\"number\":27,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"MARKETING\\nPM\",\"how_to_check\":\"1. Check if the displays are within the current lineup only, no FUSO, Adventure, or any old model and no damages\"}', 1, '2026-09-05 08:08:23', '2026-09-07 02:38:51'),
(323, 6, 83, 'dos-28', 'All installed A/C systems in the showroom and sales lounge are functioning properly', 21, '{\"number\":28,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"property_management\",\"how_to_check\":\"1. Check all A/C systems if they are properly functioning\\n2. Check the thermometer in the following areas and ensure the thermostat does not exceed 27°C:\\n-Showroom/Negotiation Area\\n-Showroom lounge\"}', 1, '2026-09-05 08:08:23', '2026-09-07 02:38:51'),
(324, 6, 83, 'dos-29', 'The sofas/chairs in the customer lounge and the negotiation area are in good condition, sufficient, organized, clean, and comply with MMPC VI Standard Requirements', 22, '{\"number\":29,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> GM to submit request to purchasing\\n> BOM to monitor progress until compliant.\",\"escalation\":\"PURCHASING\",\"how_to_check\":\"1. Check if the customer lounge and negotiation area have enough sofas\\/chairs that are comfortable, well-maintained, free from tears, and meet the MMPC VI Standard Requirements\\n2. Check if the dealer is not using monobloc chairs in the showroom area\"}', 1, '2026-09-05 08:08:23', '2026-09-07 02:38:51'),
(325, 6, 83, 'dos-34', 'Rest Rooms must have clean water supply, toilet bowl, sink, urinal, bidet, trash cans, tissue, paper towel or hand dryer, and hand wash soap; no foul smell', 23, '{\"number\":34,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> Remind utility personnel of daily 5S task.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check all restrooms designated for customers (Male, Female, PWD)\\n2. Check if the restrooms are well-lit\"}', 1, '2026-09-05 08:08:23', '2026-09-07 02:38:51'),
(326, 6, 84, 'dos-8', 'Test drive vehicle are maintained clean, fully functional and is readily available for use.', 1, '{\"number\":8,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Product Presentation and Test Drive\",\"subject\":\"Test Drive\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> SM to advise BOM of any damage\\n> BOM prepare request for PMS or damage repair and send to Inventory\\n> BOM must maintain aTest drive monitoring file record which includes, km reading, PMS and damage record. \\n> PMS interval will be based on prescribed km reading or prescribed months whichever comes first.\",\"escalation\":\"INVENTORY\",\"how_to_check\":\"1. Check if the designated test drive units is compliant\"}', 1, '2026-09-05 08:08:23', '2026-09-07 02:38:51'),
(327, 6, 84, 'dos-9', '> Test drive parking area with a roof (tent) should be installed in front of the showroom\n> Test drive advertisement with Dealer\'s contact number visibly displayed at the dealership', 2, '{\"number\":9,\"level\":\"Beyond\",\"category\":\"Beyond\",\"coverage\":\"Product Presentation and Test Drive\",\"subject\":\"Test Drive\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> prepare request for tent design standards from marketing\\n> submit purchase request with design to Purchasing\",\"escalation\":\"MARKETING \\/ PURCHASING\",\"how_to_check\":\"1. Check through observation if the testdrive advertisement and dealership contact details are updated\"}', 1, '2026-09-05 08:08:23', '2026-09-07 02:38:51'),
(328, 6, 84, 'dos-10', 'Test drive route map is available', 3, '{\"number\":10,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Product Presentation and Test Drive\",\"subject\":\"Test Drive\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check if route map is available\\n> advise GM if no route map is available.\\n> follow up until compliant.\",\"escalation\":\"MARKETING\",\"how_to_check\":\"1. Check if the testdrive route map is available at the showroom area\\n2. Check if there are 2 - 3 test drive route map available\"}', 1, '2026-09-05 08:08:23', '2026-09-07 02:38:51'),
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
(344, 2, 63, 'dos-as-29', 'Stable internet connection at the ff. area: \n(Bandwidth> 1Mbps and Latency<150ms) via Ookla speedtest\n1. Service Reception\n2. Receiving Bay', 3, '{\"number\":29,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Systems\",\"subject\":\"CRM Requirements\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check via Ookla speedtest\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(345, 2, 63, 'dos-as-56', 'Has updated access account on Service Information Portal', 4, '{\"number\":56,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Systems\",\"subject\":\"Service Documents\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Confirm with ASM and Service Admin if they have updated access in the system (SeIP)\\n - Check when did they last log-in in the system\\n - follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check if can access Service Information Portal (SIP); if none, provide email\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(346, 2, 64, 'dos-as-13', 'Is there dedicated appointment bay and walk in receiving bays?', 1, '{\"number\":13,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Dedicated Appointment and Walk-In Bay\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check if SA\\/ Car Jockey is aware of the allocation of appointment and walk in receiving bays (minimum of 2 bays).\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47');
INSERT INTO `checklist_items` (`id`, `checklist_template_id`, `checklist_section_id`, `key`, `prompt`, `sort_order`, `metadata`, `is_active`, `created_at`, `updated_at`) VALUES
(347, 2, 64, 'dos-as-42', 'Are there no parts on the floor without bin locator? And/ or does each locator stores only one kind of parts?', 2, '{\"number\":42,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Parts 5S\",\"checker\":\"Parts Supervisor\",\"pic\":\"ASM\",\"bom_task\":\"- Check if all parts inside the warehouse are stored with bin locators\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check parts warehouse as indicated.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(348, 2, 64, 'dos-as-45', 'Workbays are marked with demarcation lines, and identified with numbers; Cleanliness inside the workshop area is maintained (no lingering oil and water spills, and scattered items)', 3, '{\"number\":45,\"level\":\"Basic\",\"category\":\"Basic\",\"coverage\":\"Facilities\",\"subject\":\"Workshop Maintenance\",\"checker\":\"WS\",\"pic\":\"ASM\",\"bom_task\":\"- Visual check of cleanliness in the workshop.\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check as indicated.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(349, 2, 64, 'dos-as-47', '> Items are properly sorted and stored\n> Cleanliness inside the tool room is maintained\n> Special service tools are wall-mounted\n> There is an updated borrower\'s logbook', 4, '{\"number\":47,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Tools Storage Room\",\"checker\":\"WS\",\"pic\":\"ASM\",\"bom_task\":\"- Visual check\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check as indicated.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(350, 2, 64, 'dos-as-48', '> The components repair room is used for its intended purpose\n> The required tools are present and properly managed\n> Has adequate illumination and ventilation', 5, '{\"number\":48,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Components Repair Room\",\"checker\":\"WS\",\"pic\":\"ASM\",\"bom_task\":\"- Visual check\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check as indicated.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(351, 2, 64, 'dos-as-49', '> Storage area is enclosed  \n> Drums are placed on top of elevated platforms  \n> No oil spills on the floor and with regular schedule disposal pullout', 6, '{\"number\":49,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Waste Oil Storage\",\"checker\":\"WS\",\"pic\":\"ASM\",\"bom_task\":\"- Visual check\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check as indicated.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(352, 2, 64, 'dos-as-50', '> Storage area is enclosed  \n> Contains storage racks and bins; replaced parts must be secured with box \n> Follows the standard 30-60-90 days sorting scheme \n> Should have a proper tagging and inventory list and monitoring', 7, '{\"number\":50,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Warranty Parts Storage\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Visual check and validate if ageing warranty are correct\\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check as indicated.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(353, 2, 64, 'dos-as-51', 'Placed at the back part of the service shop and properly maintained', 8, '{\"number\":51,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Scrapped Parts Storage\",\"checker\":\"WS\",\"pic\":\"ASM\",\"bom_task\":\"- Visual check if scrapped parts is  properly stored in its designated area\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check as indicated.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(354, 2, 64, 'dos-as-52', 'Must be in an enclosed area with enough racks and bins for proper sorting', 9, '{\"number\":52,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Dismantled Parts Storage\",\"checker\":\"WS\",\"pic\":\"ASM\",\"bom_task\":\"- Visual check if dismantled parts is  properly stored in its designated area\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check as indicated.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
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
(380, 2, 68, 'dos-as-39', 'Carryover units are properly monitored and managed (with monitoring) by Job Controller.', 5, '{\"number\":39,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Workshop Scheduling\",\"subject\":\"Repair\",\"checker\":\"WS\",\"pic\":\"ASM\",\"bom_task\":\"- Check job control WIP monitoring if updated and match the actual units in the workshop\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check if there is a carry over units monitoring being utilized to monitor all remaining vehicles inside the shop.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(381, 2, 69, 'dos-as-40', 'Does Parts Staff pre-pick parts for appointment and walk-in customers?', 1, '{\"number\":40,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Advance Info to Parts Store\",\"subject\":\"Pre-Picking\",\"checker\":\"Parts Supervisor\",\"pic\":\"ASM\",\"bom_task\":\"- Physical Checking of pre-picked parts of corrent\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check if there are pre-picked parts in a basket\\/ container with standard pre-picking tag in a storage shelves\\/ rack.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(382, 2, 69, 'dos-as-41', 'Is there any monitoring to ensure that the Leadman/ technician who is waiting for emergency parts is contacted immediately after delivery/receiving of parts?', 2, '{\"number\":41,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Advance Info to Parts Store\",\"subject\":\"Emergency Parts\",\"checker\":\"Parts Supervisor\",\"pic\":\"ASM\",\"bom_task\":\"- Ask workshop supervisor\\/ leadman if they were immediately informed if emergency parts already arrived in the dealership\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check monitoring tool used by the Parts Staff for emergency orders.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(383, 2, 70, 'dos-as-43', 'Does Leadman indicate or instruct target job completion time to the assigned technician?', 1, '{\"number\":43,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Repair Order Processing and Quality of Work\",\"subject\":\"Vehicle Status Tag\",\"checker\":\"WS\",\"pic\":\"ASM\",\"bom_task\":\"- Check if technician visualization tag if updated by leadman and if the details on the Tag is correct vs the actual job.\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check if vehicle status tag has promised time of delivery and in the windshield and Technician Visualization Tag is available and updated on a real time basis.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(384, 2, 70, 'dos-as-44', 'In case of unapproved job by the customer, does SA record as \"future work reminder\" in service history of DMS?', 2, '{\"number\":44,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Repair Order Processing and Quality of Work\",\"subject\":\"Unapproved Job\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Gather Estimate Report from ASM to check. \\n(Do we need to allow access for BOM?) \\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check DMS if there are notes on jobs rejected by customers (at least 3 samples)\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(385, 2, 70, 'dos-as-46', 'Service Vehicle:\nAll service vehicle has exterior covers installed (bumper and fender)', 3, '{\"number\":46,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Repair Order Processing and Quality of Work\",\"subject\":\"Repair\",\"checker\":\"WS\",\"pic\":\"ASM\",\"bom_task\":\"- Visual check\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check if vehicle being serviced has complete exterior protective covers.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(386, 2, 70, 'dos-as-53', 'Compliance with Mitsubishi Quick Service standards (4 sub-requirements). All items must pass.', 4, '{\"number\":53,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Repair Order Processing and Quality of Work\",\"subject\":\"Mitsubishi Quick Service\",\"checker\":\"WS\",\"pic\":\"ASM\",\"bom_task\":\"Check with ASM and see if the form was accomplished properly.\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"All check items in the subform must be \\\"YES\\\" to count this item compliant.\\n\\nSubform Verification Requirements:\\n1. Dedicated MQS bay with complete MQS basic and advanced tools\\n2. Proper execution of MQS sequence\\n3. Check 1 sample of MQS vehicle if within prescribed time\\n4. MQS technician must be provided with complete QS uniforms\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(387, 2, 71, 'dos-as-58', 'Does vehicle status tag indicate proper status inside the shop? (e.g. if ongoing repair, or for car wash, etc.)', 1, '{\"number\":58,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Repair Order Completion and Invoicing\",\"subject\":\"Vehicle Status Tag\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Visual check\\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check 3 samples of vehicles inside the shop with vehicle status tag that is updated based on actual status (e.g. if ongoing repair, or for car wash, etc.)\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(388, 2, 71, 'dos-as-59', 'Escorted the customer to his/her vehicle.', 2, '{\"number\":59,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Repair Order Completion and Invoicing\",\"subject\":\"Delivery\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Check with SA and security Guard\\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Observe SA during vehicle handover process (2 samples)\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(389, 2, 71, 'dos-as-60', 'Did SA inform waiting customer and non waiting customer when car is ready for return?', 3, '{\"number\":60,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Repair Order Completion and Invoicing\",\"subject\":\"Car Return\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Check with SA and security Guard\\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Observe 2 customers that is being reminded by Service Advisor that their vehicle is ready for hand over.\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(390, 2, 71, 'dos-as-61', 'Documentation:\nProper utilization of all service documents (Rationalized Checksheet, Repair Order, Service Invoice)', 4, '{\"number\":61,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Repair Order Completion and Invoicing\",\"subject\":\"Repair\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Verify if proper documentation was applied depending on the type of transaction (e.g QC Stamp, customer signatures etc)\\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"All check items must be compliant (3 samples)\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(391, 2, 72, 'dos-as-62', 'Does SA refer to the initial agreed RO and quoted price?', 1, '{\"number\":62,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Information and Car Return\",\"subject\":\"Actual Cost\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Check if quotations\\/estimate is signed by the customer\\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check 3 samples if Service Invoice matches with the Cost Estimate (same amount or below as agreed with customer)\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(392, 2, 72, 'dos-as-63', 'Does SA show replaced parts (if applicable) during delivery process?', 2, '{\"number\":63,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Information and Car Return\",\"subject\":\"Replaced Parts\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"- Check if replaced parts was returned to the customer. If not, verify if there is proper documentation for it.\\nfollow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check 2 vehicle handover process if replaced parts are shown to customer\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(393, 2, 72, 'dos-as-64', 'Does Service Advisor remind the customer regarding QVOC?', 3, '{\"number\":64,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Information and Car Return\",\"subject\":\"QVOC Reminder\",\"checker\":\"CE SERVICE\",\"pic\":\"ASM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check if there is a poster stating about the survey and shows the sample content of message\\nSA - Main PIC; Receptionist - Sub PIC\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
(394, 2, 72, 'dos-as-65', 'Does SA remove the Protective Cover Sheet in the presence of Customer before vehicle is delivered back to the Customer?', 4, '{\"number\":65,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Information and Car Return\",\"subject\":\"Removal of Protective Cover\",\"checker\":\"WS\",\"pic\":\"ASM\",\"bom_task\":\"- check with security if covers are removed in the presence of customers.\\nfollow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Check 2 vehicle handover process\"}', 1, '2026-09-05 08:08:23', '2026-09-06 17:18:47'),
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
(413, 7, 76, 'subform-ef-1', 'Employees\' Restroom (Maintained clean and must have the proper amenities for convenience of use i.e. soap, water supply, tissue, etc.)', 0, '{\"number\":1,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Employee Facilities\",\"checker\":\"WS SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Inspect employee restroom cleanliness, soap, water, and tissue.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(414, 7, 76, 'subform-ef-2', 'Technician Locker Room and Shower are adjacent with each other', 1, '{\"number\":2,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Employee Facilities\",\"checker\":\"WS SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify technician locker room and shower are adjacent.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(415, 7, 76, 'subform-ef-3', 'Sufficient no. of technicians\' lockers', 2, '{\"number\":3,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Employee Facilities\",\"checker\":\"WS SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify sufficient lockers allocated for all technicians.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(416, 7, 76, 'subform-ef-4', 'Technician Locker Room has sufficient no. of tables and benches', 3, '{\"number\":4,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Employee Facilities\",\"checker\":\"WS SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check adequacy of tables and seating in locker room.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(417, 7, 76, 'subform-ef-5', 'Technician Locker Room walls and flooring must have proper paint', 4, '{\"number\":5,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Employee Facilities\",\"checker\":\"WS SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Inspect condition of paint on walls and flooring.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(418, 7, 76, 'subform-ef-6', 'Technician Locker Room has proper lighting and ventilation', 5, '{\"number\":6,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Employee Facilities\",\"checker\":\"WS SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Inspect lighting and ventilation operational status.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(419, 7, 76, 'subform-ef-7', 'Technician Shower Room has sufficient no. of showers, urinals, and toilet cubicle', 6, '{\"number\":7,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Employee Facilities\",\"checker\":\"WS SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Count and check function of showers, urinals, cubicles.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(420, 7, 76, 'subform-ef-8', 'Technician Shower Room has clean toilets bowls with flush, bidet, tissue and soap', 7, '{\"number\":8,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Employee Facilities\",\"checker\":\"WS SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check amenities in shower room toilets.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(421, 7, 76, 'subform-ef-9', 'Technician shower and toilets are completely functional', 8, '{\"number\":9,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Employee Facilities\",\"checker\":\"WS SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Test all fixtures for water flow, drainage, and flushing.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(422, 7, 76, 'subform-ef-10', 'Technician waiting area (Near the Job Controller room for efficient job order dispatch)', 9, '{\"number\":10,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Employee Facilities\",\"checker\":\"WS SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify location is near JC room for dispatch.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02');
INSERT INTO `checklist_items` (`id`, `checklist_template_id`, `checklist_section_id`, `key`, `prompt`, `sort_order`, `metadata`, `is_active`, `created_at`, `updated_at`) VALUES
(423, 7, 76, 'subform-ef-11', 'Technician waiting area (Sufficient benches)', 10, '{\"number\":11,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Employee Facilities\",\"checker\":\"WS SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify benches are sufficient for technicians on standby.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(424, 7, 76, 'subform-ef-12', 'Technician handwash booth (Adequate supply of water) (separate booth is optional)', 11, '{\"number\":12,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Employee Facilities\",\"checker\":\"WS SUP\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify water supply and cleanliness at handwash station.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(425, 7, 77, 'subform-mr-1', 'Allocated Meeting/ Conference Room especially for online trainings', 0, '{\"number\":1,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Meeting Room\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Verify designated meeting\\/conference room exists.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(426, 7, 77, 'subform-mr-2', 'Available projector and PC/laptop (to be used for online trainings)', 1, '{\"number\":2,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Meeting Room\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Check presence and functionality of projector\\/laptop.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(427, 7, 77, 'subform-mr-3', 'Available Wi-Fi (Internet Connection = 10mbps)', 2, '{\"number\":3,\"level\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Meeting Room\",\"checker\":\"ASM\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"AS BRAND HEAD\",\"how_to_check\":\"Run speed test to verify minimum 10mbps connection.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(428, 7, 78, 'subform-mqs-1', 'Dedicated MQS bay with complete MQS basic and advanced tools', 0, '{\"number\":1,\"level\":\"Standard\",\"coverage\":\"Repair Order Processing and Quality of Work\",\"subject\":\"Mitsubishi Quick Service\",\"checker\":\"WS\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Verify dedicated MQS bay has complete basic and advanced tool sets.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(429, 7, 78, 'subform-mqs-2', 'Proper execution of MQS sequence', 1, '{\"number\":2,\"level\":\"Standard\",\"coverage\":\"Repair Order Processing and Quality of Work\",\"subject\":\"Mitsubishi Quick Service\",\"checker\":\"WS\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Observe technicians conducting standard MQS sequence.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(430, 7, 78, 'subform-mqs-3', 'Check 1 sample of MQS vehicle if within prescribed time', 2, '{\"number\":3,\"level\":\"Standard\",\"coverage\":\"Repair Order Processing and Quality of Work\",\"subject\":\"Mitsubishi Quick Service\",\"checker\":\"WS\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Sample 1 MQS job to ensure adherence to promised delivery duration.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(431, 7, 78, 'subform-mqs-4', 'MQS technician must be provided with complete QS uniforms', 3, '{\"number\":4,\"level\":\"Standard\",\"coverage\":\"Repair Order Processing and Quality of Work\",\"subject\":\"Mitsubishi Quick Service\",\"checker\":\"WS\",\"pic\":\"GM\",\"bom_task\":\"follow up action plan and monitor compliance\",\"escalation\":\"GM\",\"how_to_check\":\"Inspect MQS technician uniforms.\"}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
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
(460, 6, 83, 'dos-17', 'Training facility/room shall be within standard room size based on Circular NTD-STS-2024-010', 12, '{\"number\":17,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Dealer Training Facilities and Equipment Standards\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"DND\",\"how_to_check\":\"1. Standard training room \\nRoom size must be sufficient based on dealer category:\\nA \\u2013 37 & above m\\u00b2\\nB - 30 to 36 m\\u00b2\\nC \\u2013 25 to 29 m\\u00b2\\nD \\u2013 18 to 24 m\\u00b2\\nE \\u2013 16 to 18 m\\u00b2\\nF \\u2013 15 to 16 m\\u00b2\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(461, 6, 83, 'dos-18', 'Training facility/room shall have complete tools and equipment for training based on Circular NTD-STS-2024-010', 13, '{\"number\":18,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Dealer Training Facilities and Equipment Standards\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check tools and equipment:\\n\\u2022 Table and chairs\\n\\u2022 Projector\\/TV\\n\\u2022 External speaker with 3.5mm jack \\n\\u2022 HDMI and\\/or VGA cable \\n\\u2022 Presentation clicker\\n\\u2022 Office Supplies\\n\\u2022 Whiteboard\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(462, 6, 83, 'dos-19', 'Sales Executives/Sales CROs must have a secured and stable internet connection during training', 14, '{\"number\":19,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Dealer Training Facilities and Equipment Standards\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise IT of non compliance.\\n> follow up until compliant.\",\"escalation\":\"IT\",\"how_to_check\":\"1. Check connection being used by SE.\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(463, 6, 83, 'dos-20', 'Dealers must have a dedicated computer/laptop within the required specification for training and other tools/software.', 15, '{\"number\":20,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Facilities\",\"subject\":\"Dealer Training Facilities and Equipment Standards\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"IT\",\"how_to_check\":\"1. Check if the dealer follows the minimum requirement for desktop\\/laptop\\n\\n\\u2022 CPU: At least Ryzen 5\\/Intel Core i5 or \\nhigher \\n\\u2022 RAM: At least 8GB DDR4 or higher \\n\\u2022 Web camera: At least 720p or higher \\n\\u2022 Microphone: Internal microphone \\n\\u2022 SSD\\/HDD: At least 512GB internal \\nstorage or higher \\n\\u2022 OS: Licensed Windows 10 or higher \\n\\u2022 Productivity: Licensed Microsoft Office \\n(Excel, PowerPoint & Word)\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(464, 6, 84, 'dos-38', 'Low-performing SEs based on Sales and SSI Performance are identified and given corrective measures.', 4, '{\"number\":38,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Product Presentation and Test Drive\",\"subject\":\"Sales Operation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\\nCE CENTRAL\",\"how_to_check\":\"1. Check List of low performing SEs for both Sales and SSI\\n2. Check training schedule\\n3. Check the coaching forms compiled by the SM\\/TL or Sales Trainer.\\n4. Check the latest role play records\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(465, 6, 84, 'dos-49', 'Updated KANBAN materials of all units are available', 5, '{\"number\":49,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Product Presentation and Test Drive\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"MMPC CS TEAM\",\"how_to_check\":\"Ask SEs to present the updated hard copy of KANBAN material\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(466, 6, 84, 'dos-50', 'Sales Executive knows the MMPC 6pt Walk-around Product Presentation', 6, '{\"number\":50,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Product Presentation and Test Drive\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview 2-3 SEs\\n2. Check if the SEs can correctly enumerate the 6-point walk-around\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(467, 6, 85, 'dos-11', 'MMPC greeting standard is done by all dealer staff.', 1, '{\"number\":11,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Engagement and Showroom Operations\",\"subject\":\"Greetings\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check if all dealer staff follow the standard greeting (Smile, Greet & Bow) and are consistently done.\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(468, 6, 85, 'dos-12', 'Customers were escorted during the entrance and sent off with an umbrella service (if necessary).', 2, '{\"number\":12,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Engagement and Showroom Operations\",\"subject\":\"Greetings\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check through observation if the available umbrella at the dealership is either within MMPC branding or has no branding\\/logos.\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(469, 6, 85, 'dos-21', 'Hero Car Display (new model) is displayed on a standard black platform.', 3, '{\"number\":21,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Engagement and Showroom Operations\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check if the Hero Car is compliant\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(470, 6, 85, 'dos-22', 'Has a display car with recommended MMPC accessories', 4, '{\"number\":22,\"level\":\"Beyond\",\"category\":\"Beyond\",\"coverage\":\"Customer Engagement and Showroom Operations\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check if there is a display car is equipped with accessories\\n2. Check if the display accessories are MMPC merchandise\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(471, 6, 85, 'dos-30', 'Showroom and customer lounge have designated amenity corner with the required signage', 5, '{\"number\":30,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Engagement and Showroom Operations\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> Accomplish Inspection Request\\n> Submit & Follow up with PM\\n> Monitor progress until completion\\n> signs completion report\",\"escalation\":\"CE CENTRAL\",\"how_to_check\":\"1. Check if the amenity corner signage clearly states that it is intended for customers\\n2. Check if the amenity corner signage is clearly visible.\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(472, 6, 85, 'dos-31', 'Amenity corner has minimum of 3 beverage options available (water, juice, coffee, etc.)', 6, '{\"number\":31,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Engagement and Showroom Operations\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> follow up request for replenishment from GM\\n> BOM to replenish items\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check if the amenity corner is compliant\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(473, 6, 85, 'dos-32', 'Amenity corner has available snacks (biscuits, cupcakes, candies)', 7, '{\"number\":32,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Customer Engagement and Showroom Operations\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> follow up request for replenishment from GM\\n> BOM to replenish items\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check if the amenity corner is compliant\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(474, 6, 85, 'dos-33', 'Sales Executives proactively offer beverages, snacks, Wi-Fi access, and lounge entertainment (TV)', 8, '{\"number\":33,\"level\":\"Beyond\",\"category\":\"Beyond\",\"coverage\":\"Customer Engagement and Showroom Operations\",\"subject\":\"Showroom Area\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check if the TV is working and accessible for viewing\\n2. Check if the Wi-Fi is available and  instruction on how to connect  to the Wi-Fi is available\\n3. Check if SE is doing proactive offering\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(475, 6, 86, 'dos-35', 'Availability of Sales Performance Control Board with correct format /pattern and updated with corresponding progress indicator.', 1, '{\"number\":35,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Sales Operation Management\",\"subject\":\"Sales Operation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check the actual SPC board.\\n- 1 General SPC Board for Branch Head\\n- 1 for each Sales Team\\n2. Check the ff:\\n- Complete and correct data\\n- Correct Pattern\\n- With progress indicator\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(476, 6, 86, 'dos-36', 'Availability of sales activity with 2 months rolling plan, including SE duties.', 2, '{\"number\":36,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Sales Operation Management\",\"subject\":\"Sales Operation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GM\",\"how_to_check\":\"1. Check Sales Activity Plan\\n2. Check if it follows a two-month rolling format\\n3. Check if the plan aligns with the actual activity\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(477, 6, 86, 'dos-37', 'Conduct Gap analysis', 3, '{\"number\":37,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Sales Operation Management\",\"subject\":\"Sales Operation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Check the Gap analysis of the previous month\\n2. Check the Minutes of the Meeting (MOM) of the latest monthly Team Meeting to confirm if the Gap analysis was discussed\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(478, 6, 86, 'dos-43', 'Sales Executives are well informed on the structure of SPC and  targets are cascaded.', 4, '{\"number\":43,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Sales Operation Management\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview 2-3 Ses\\n2. Ask about their understanding of the SPC structure\\n3. Ask the targets they recognize and follow\\n4. Check if their stated targets align with the actual SPC board\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(479, 6, 86, 'dos-61', 'Dealer facilitates monthly General Sales Meetings, supported by Minutes of the Meeting (MOM).', 5, '{\"number\":61,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Sales Operation Management\",\"subject\":\"Documentation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"N\\/A\",\"how_to_check\":\"1. Check the latest Minutes of the Meeting (MOM) for the General Sales Meeting from the BH\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(480, 6, 86, 'dos-62', 'SMs facilitates daily meetings with the SEs in front of the SPC Board, supported by  Minutes of the Meeting (MOM).', 6, '{\"number\":62,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Sales Operation Management\",\"subject\":\"Documentation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Check the latest Minutes of the Meeting (MOM) for the daily meeting from the SMs\\/TLs\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(481, 6, 86, 'dos-63', 'Monitoring and reporting of SSI Score Evaluation including the Voice of the Customer (VOC)', 7, '{\"number\":63,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Sales Operation Management\",\"subject\":\"Documentation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> Assigned to CE Central\",\"escalation\":\"GENERAL MANAGER\\nCE CENTRAL\",\"how_to_check\":\"1. Check the previous month\'s report:\\n- SSI score trend \\n-SSI by SE \\n-VOC (Voice of Customers)\\n2. Check the Minutes of the Meeting (MOM) from the previous month to confirm if the SSI analysis was reported during GSM.\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(482, 6, 86, 'dos-76', 'Sales KPI Monitoring Sheet is up to date', 8, '{\"number\":76,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Sales Operation Management\",\"subject\":\"Monitoring\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"\",\"how_to_check\":\"1. Check if the KPI Monitoring Sheet is updated with complete details, including data from the previous month\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(483, 6, 87, 'dos-39', 'Check plan including area setting, evaluation of the area and  assigned SE', 1, '{\"number\":39,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Lead Generation and Management\",\"subject\":\"Sales Operation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"N\\/A\",\"how_to_check\":\"1. Check the availability of the area setting\\n2. Check market evaluation of the area\\n3. Check the assigned team in the area for saturation activity\\n\\nNote: Check if the activity has been properly executed\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(484, 6, 87, 'dos-40', 'Conduct Prospect Party atleast once a year', 2, '{\"number\":40,\"level\":\"Beyond\",\"category\":\"Beyond\",\"coverage\":\"Lead Generation and Management\",\"subject\":\"Sales Operation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"MARKETING\",\"how_to_check\":\"For 1st half, check if dealer has plan to conduct Prospect Party.\\nFor 2nd half, check if dealer conducted Prospect Party. Check proof such as photo and attendance list.\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(485, 6, 87, 'dos-41', 'Conduct Key Opinion Leaders (KOLs) atleast once a year', 3, '{\"number\":41,\"level\":\"Beyond\",\"category\":\"Beyond\",\"coverage\":\"Lead Generation and Management\",\"subject\":\"Sales Operation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"MARKETING\",\"how_to_check\":\"For 1st half, check if dealer has plan to have KOL.\\nFor 2nd half, check if dealer conducted collaborated with KOL. Check proof such as photo and attendance list.\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(486, 6, 87, 'dos-44', 'Sales Executives understand the Source of Sales', 4, '{\"number\":44,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Lead Generation and Management\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview to 2-3 SEs\\n2. Check if SEs can identify the sources of new leads and repeat customers.\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(487, 6, 87, 'dos-45', 'Sales Executives can identify the correct definition of Hot, Warm and Cold', 5, '{\"number\":45,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Lead Generation and Management\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview 2-3 SEs\\n2. Check if the definition of (Hot, Warm, Cold) is correct\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(488, 6, 87, 'dos-54', 'Dealers must have an official FB page following MMPC Branding and is properly maintained', 6, '{\"number\":54,\"level\":\"Beyond\",\"category\":\"Beyond\",\"coverage\":\"Lead Generation and Management\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Look for the actual Facebook page of the Dealer\\n2. Check if it follows MMPC Branding\\n3. Check who is responsible for marketing posts on the page, ideally from the Marketing Department\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(489, 6, 87, 'dos-55', 'Responses to online inquiries are within the standard response time.', 7, '{\"number\":55,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Lead Generation and Management\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Check the actual Facebook page of SEs\\n2. Check if the response time is within 15 minutes as per the standard\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(490, 6, 87, 'dos-70', 'Leads Database contains customer data from the past 5 years and is being monitored', 8, '{\"number\":70,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Lead Generation and Management\",\"subject\":\"Monitoring\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"CENTRAL ADMIN\",\"how_to_check\":\"1. Check if the Leads Database is available and includes customer data from the past 5 years\\n2. Check if the database is being utilized, monitored, and updated.\\n\\nSample:\\nCurrent year = 2025 \\u2192 Extract customer database for 2019 and below\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(491, 6, 87, 'dos-71', 'Fleet Account Monitoring is available and updated', 9, '{\"number\":71,\"level\":\"Beyond\",\"category\":\"Beyond\",\"coverage\":\"Lead Generation and Management\",\"subject\":\"Monitoring\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"\",\"how_to_check\":\"1. Check if there are fleet accounts\\n2. Check if fleet monitoring exists\\n3. Check if the fleet monitoring contact plan and tracking is updated\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(492, 6, 88, 'dos-42', 'Sales Executives wear the proper uniform (showroom duty, vehicle release, or field duty attire)', 1, '{\"number\":42,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Manpower\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"Check all SEs are in the prescribed uniform.\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(493, 6, 88, 'dos-87', 'All CROs are accredited following these timelines:\n*Level 1: Introductory Course -  within 1 month upon hiring\n*Level 2: Basic Sales CRO Training - within 3 to 6 months upon hiring', 2, '{\"number\":87,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Manpower\",\"subject\":\"Training\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"\",\"escalation\":\"MMPC TRAINING TEAM\",\"how_to_check\":\"1. Check the training record from Training Department\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(494, 6, 88, 'dos-88', 'All SEs are accredited following these timelines:\n*Level 1: Introductory Course -  within 30 days upon hiring\n*Level 2: Basic Course - within 6 months upon hiring\n*Level 3: Advanced Course   - within 1 year upon hiring', 3, '{\"number\":88,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Manpower\",\"subject\":\"Training\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"MMPC TRAINING TEAM\",\"how_to_check\":\"1. Check the training record from Training Department\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(495, 6, 88, 'dos-89', 'Dealer has a designated Sales Training PIC', 4, '{\"number\":89,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Manpower\",\"subject\":\"Person-in-Charge\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"MMPC TRAINING TEAM\",\"how_to_check\":\"1. Check the training record from Training Department\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(496, 6, 88, 'dos-90', 'Sales Training Accreditation monthly report is updated by assigned dealer personnel', 5, '{\"number\":90,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Manpower\",\"subject\":\"Documentation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> submit report to distributor\",\"escalation\":\"MMPC TRAINING TEAM\",\"how_to_check\":\"1. Check if PIC submitted monthly report\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(497, 6, 89, 'dos-46', 'Tagging of rating status (Hot, Warm and Cold) in the Otoleap is accurate.', 1, '{\"number\":46,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Needs Analysis\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview 2-3 SEs\\n2. Check the Otoleap of SEs\\n2. Check if the date of lead creation matches the correct tagged rating status\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(498, 6, 89, 'dos-47', 'Sales Executives are knowledgable on the 10 Basic Needs.', 2, '{\"number\":47,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Needs Analysis\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview 2-3 SEs\\n2. Check if the SEs can identify at least 3 items under Key Needs Item\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(499, 6, 89, 'dos-48', 'Sales Executives know the right approach for customers who owns other brands or customers who are likely to buy to other brands.', 3, '{\"number\":48,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Needs Analysis\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview 2-3 SEs\\n2. Check the approach of the SEs\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(500, 6, 90, 'dos-51', 'Sales Executives are informed on the latest discount policies', 1, '{\"number\":51,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Deal and Closing Management\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview 2-3 SEs\\n2. Ask how they stay informed about the latest discount policies\\n3. Request proof, such as a group chat message or minutes of the meeting (MOM)\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(501, 6, 90, 'dos-56', 'Sales Executive provides a formal vehicle cost computation and digital copy of an updated specification sheet', 2, '{\"number\":56,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Deal and Closing Management\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview 2-3 SEs\\n2.  Check the most recent Facebook inquiry that includes a price discussion\\n3. Check If SEs provided formal computation and updated specification sheet\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(502, 6, 91, 'dos-52', 'Sales Executives are informed on the latest updates on banks/financial institutions', 1, '{\"number\":52,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Application Process Support\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"N\\/A\",\"how_to_check\":\"1. Interview 2-3 SEs\\n2. Ask how they stay informed about the latest updates\\n3. Request proof, such as a group chat message or minutes of the meeting (MOM)\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(503, 6, 91, 'dos-53', 'Sales Executive provide a list of required documents to the customers.', 2, '{\"number\":53,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Application Process Support\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview 2-3 Ses\\n2. Check the requirement list provided to the customers\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(504, 6, 91, 'dos-57', 'Sales Executive informed customers of the status of their loan approvals.', 3, '{\"number\":57,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Application Process Support\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview 2-3 SEs\\n2. Check if there are on-going loan application\\n3. Check if SEs actively inform customers about their loan status by requesting proof of communication or documentation\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(505, 6, 92, 'dos-58', 'Sales Executive informed customers of the release date and time', 1, '{\"number\":58,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Vehicle Release Management\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> refer to GM\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview 2-3 SEs\\n2. Check if SEs can provide proof of informing customers about the release date and time of their recent vehicle release\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(506, 6, 92, 'dos-59', 'The Release Ceremony was conducted', 2, '{\"number\":59,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Vehicle Release Management\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"BOM\",\"how_to_check\":\"1. Interview 2-3 SEs\\n2. Check the most recent photos of released customers Proof should have the ff:\\n- Thank you board with customer name\\n- Congratualtions Banner\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(507, 6, 92, 'dos-60', 'Have special gift/amenities for new vehicle-releasing customers.', 3, '{\"number\":60,\"level\":\"Beyond\",\"category\":\"Beyond\",\"coverage\":\"Vehicle Release Management\",\"subject\":\"SE Process\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Interview 2-3 SEs\\n2. Ask if they have special gift \\/ amenities provided for releasing customers\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(508, 6, 92, 'dos-64', 'All required documents are complete and duly signed by the customer, including:\n1. Customer Information Sheet (CIS) and DPA Form  \n2. Copy of Customer ID  \n3. MMVSO (Vehicle Sales Order)  \n4. SE Delivery Declaration Form (SDDF)\n5. New Vehicle Releasing Checklist (NVRC)  \n6. Sales Invoice (SI)  \n7. Delivery Receipt (DR)\n8. MMPC and Dealer’s copy of Warranty Certificate', 4, '{\"number\":64,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Vehicle Release Management\",\"subject\":\"Documentation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\",\"escalation\":\"BOM\",\"how_to_check\":\"1. Request the actual folder of release for the previous month from the Sales Admin\\/Accounting Staff; choose (3) samples.\\n2.Check if all required documents are complete and properly filled out with customer\'s signature\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(509, 6, 92, 'dos-65', 'All customer\'s  document has digital backup', 5, '{\"number\":65,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Vehicle Release Management\",\"subject\":\"Documentation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> SM to perform doc scanning and upload in file storage.\\n> BOM to check for compliance.\",\"escalation\":\"CENTRAL ADMIN\",\"how_to_check\":\"1. Request the actual folder of release for the previous month from the Sales Admin\\/Accounting Staff; choose (3) samples.\\n2. Check if all key documents have been scanned and securely stored on a shared network or online drive and password-protected\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(510, 6, 92, 'dos-66', 'Customer documents are stored in a dedicated folder labeled with Customer Name, Plate/CS No., and Purchase Date and all folders are stored in a locked filing cabinet.', 6, '{\"number\":66,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Vehicle Release Management\",\"subject\":\"Documentation\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> advise GM of non compliance.\\n> follow up until compliant.\\n> BOM in charge for storage and safekeep.\",\"escalation\":\"CENTRAL ADMIN\",\"how_to_check\":\"1. Check if all customer folders have proper labels and contain all necessary documents\\n2. Check if hard copies are securely stored in a locked filing cabinet.\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51');
INSERT INTO `checklist_items` (`id`, `checklist_template_id`, `checklist_section_id`, `key`, `prompt`, `sort_order`, `metadata`, `is_active`, `created_at`, `updated_at`) VALUES
(511, 6, 92, 'dos-67', 'The time duration recorded in the New Vehicle Releasing Checklist is within the standard 2-hour releasing', 7, '{\"number\":67,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Vehicle Release Management\",\"subject\":\"Vehicle Delivery\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> recommend compliance plan\\n> consult with support teams\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Request the actual folder of release for the previous month from the Sales Admin\\/Accounting Staff; choose (3) samples.\\n2. Check NVRC attachment: \\\"Arrival Time\\\" and \\\"Departure Time\\\" should be within 2hrs for Cash \\/ PO Transaction\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(512, 6, 92, 'dos-68', 'Release area is clean and with good atmosphere', 8, '{\"number\":68,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Vehicle Release Management\",\"subject\":\"Vehicle Delivery\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> Remind utility personnel of daily 5S task.\",\"escalation\":\"BOM\",\"how_to_check\":\"1. Check the actual release area\\n2. Check if there are no vehicles parked in the release area aside from \\\"for release\\\" unit\\/s\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(513, 6, 92, 'dos-69', 'Releasing Area is inside the showroom', 9, '{\"number\":69,\"level\":\"Beyond\",\"category\":\"Beyond\",\"coverage\":\"Vehicle Release Management\",\"subject\":\"Vehicle Delivery\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"Check if the vehicle releasing area is located inside the showroom\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(514, 6, 92, 'dos-72', 'PDI is done 3 days prior to customer release', 10, '{\"number\":72,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Vehicle Release Management\",\"subject\":\"Monitoring\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> system based release timing\",\"escalation\":\"LOGISTIC\",\"how_to_check\":\"1. Check the Daily Release Monitoring\\n2. Check if the date in the PDI column is 3 days prior to delivery date\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(515, 6, 92, 'dos-73', 'Daily Release Monitoring is being utilized.', 11, '{\"number\":73,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Vehicle Release Management\",\"subject\":\"Monitoring\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> system based release monitoring\",\"escalation\":\"GENERAL MANAGER\",\"how_to_check\":\"1. Check if all releases for the day are recorded on the Daily Release Monitoring\\n2. Check the current status of the vehicle vs. the monitoring sheet\\n\\nNote: If no release for the day, check the scheduled release for the next 2 days.\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(516, 6, 93, 'dos-74', 'Birthday/Anniversary Message Greeting was sent to customers with proper monitoring and tracking', 1, '{\"number\":74,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Post-Release Customer Management\",\"subject\":\"Monitoring\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> Assigned to CE Central\",\"escalation\":\"CE CENTRAL\",\"how_to_check\":\"1. Check photo or message of sending Birthday and Anniversary Greetings\\n2. Check if the monitoring is updated\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(517, 6, 93, 'dos-75', 'Sales CROs have their monitoring file for valid complaints and negative feedback', 2, '{\"number\":75,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Post-Release Customer Management\",\"subject\":\"Monitoring\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"\",\"escalation\":\"CE CENTRAL\",\"how_to_check\":\"1. Check if there are valid red alert items\\n2. Check if the valid Red Alert items are recorded in the complaint monitoring file\\n3. Check if the monitoring file is updated\\n4. Check if the monitoring file was submitted to MMPC on time by reviewing the submission date\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(518, 6, 93, 'dos-81', 'All red alerts are reflected on the Complaint Tracker Monitoring', 3, '{\"number\":81,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Post-Release Customer Management\",\"subject\":\"Quick VOC System\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"\",\"escalation\":\"CE CENTRAL\",\"how_to_check\":\"1. All red alerts received should be reflected on the Complaint Tracker Monitoring\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(519, 6, 94, 'dos-77', 'New release vehicle is updated in YANA NVDO within 2 business days', 1, '{\"number\":77,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Systems\",\"subject\":\"YANA\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\",\"escalation\":\"CENTRAL ADMIN\",\"how_to_check\":\"1. Access the YANA and select New Vehicle > Delivery\\n2. Extract all data with a Delivery Date exactly three business days from the actual visit\\n3. Check if the \\\"Created On\\\" date falls within two business days of the Delivery Date\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(520, 6, 94, 'dos-78', 'Sales has an access to Sales Information Portal', 2, '{\"number\":78,\"level\":\"Beyond\",\"category\":\"Beyond\",\"coverage\":\"Systems\",\"subject\":\"Sales Information Portal (SIP)\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"\",\"escalation\":\"MMPC CS TEAM\",\"how_to_check\":\"1. Based on the monitoring list of those with SIP access, request them to open and navigate the system.\\n2. Check if the sales staff are aware of other members who have access to SIP\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(521, 6, 94, 'dos-79', 'Manpower report is updated monthly by assigned SEIS officer-in-charge', 3, '{\"number\":79,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Systems\",\"subject\":\"Sales Executive Information System (SEIS)\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> follow up with SMs\\n> Monitor progress until compliant.\\n> BOM submit to Central Admin\",\"escalation\":\"MMPC TRAINING TEAM\",\"how_to_check\":\"1. Check if PIC submitted monthly manpower report\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(522, 6, 94, 'dos-80', 'Manpower report (based on latest submission) is matched on the actual personnel count in the dealership', 4, '{\"number\":80,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Systems\",\"subject\":\"Sales Executive Information System (SEIS)\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> actual count, manpower report versus warm bodies.\",\"escalation\":\"MMPC TRAINING TEAM\",\"how_to_check\":\"1. Check actual manpower list in the dealership\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(523, 6, 95, 'dos-82', 'Report shall be sent on or before 5pm of the set deadline.', 1, '{\"number\":82,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Mandatory Reports\",\"subject\":\"GVD Report\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"\",\"escalation\":\"CENTRAL ADMIN\",\"how_to_check\":\"Check actual through respective FSM for the accomplishment\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(524, 6, 95, 'dos-83', '100% accuracy of the reports; shall be sent 2 working days after closing date.', 2, '{\"number\":83,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Mandatory Reports\",\"subject\":\"Gross Sales and Actual Dealer Inventory Reports\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> submit to Central Admin\",\"escalation\":\"CENTRAL ADMIN\",\"how_to_check\":\"Check actual through respective FSM for the accomplishment\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(525, 6, 95, 'dos-84', 'Report shall be sent 2 working days after closing date.', 3, '{\"number\":84,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Mandatory Reports\",\"subject\":\"Customer Waiting List\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> check for compliance\\n> submit to Central Admin\",\"escalation\":\"CENTRAL ADMIN\",\"how_to_check\":\"Check actual through respective FSM for the accomplishment\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(526, 6, 95, 'dos-85', 'Report shall be sent 3 working days after closing Date', 4, '{\"number\":85,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Mandatory Reports\",\"subject\":\"BH Finance Report\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"\",\"escalation\":\"CENTRAL ADMIN\",\"how_to_check\":\"Check actual through respective FSM for the accomplishment\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(527, 6, 95, 'dos-86', 'Timeliness and accuracy of submitted billing documents and Subsidy Claim Requirements (please refer to monthly email advice and circular for the complete mechanics of the said documents)', 5, '{\"number\":86,\"level\":\"Standard\",\"category\":\"Standard\",\"coverage\":\"Mandatory Reports\",\"subject\":\"Billing Documents and Subsidy Claims\",\"checker\":\"SALES MANAGER\",\"pic\":\"GM\",\"bom_task\":\"> Assigned to Central Admin\",\"escalation\":\"CENTRAL ADMIN\",\"how_to_check\":\"Check actual through Sales Control for the accomplishment\"}', 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51');

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
(96, 3, 'restroom-lighting', 'Lighting', 0, NULL, 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(97, 3, 'restroom-exhaust', 'Exhaust', 1, NULL, 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(98, 3, 'restroom-floor-wall-ceiling', 'Floor, Wall & Ceiling', 2, NULL, 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(99, 3, 'restroom-toilet-bowl', 'Toilet Bowl', 3, NULL, 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(100, 3, 'restroom-urinal', 'Urinal', 4, NULL, 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(101, 3, 'restroom-sink-and-faucet', 'Sink and faucet', 5, NULL, 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(102, 3, 'restroom-toilet-accessories', 'Toilet Accessories', 6, NULL, 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(103, 3, 'restroom-trash-bin', 'Trash Bin', 7, NULL, 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(104, 3, 'restroom-water-supply', 'Water Supply', 8, NULL, 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(105, 3, 'restroom-cleaning-materials', 'Cleaning Materials', 9, NULL, 1, '2026-09-08 17:12:00', '2026-09-08 17:12:00'),
(26, 4, 'parking-area', 'Parking Area', 0, NULL, 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(27, 4, 'showroom-sales-negotiation-area', 'Showroom / Sales Negotiation Area', 1, NULL, 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(28, 4, 'sales-reception-area', 'Sales Reception Area', 2, NULL, 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(29, 4, 'vehicles-display', 'Vehicles Display', 3, NULL, 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(30, 4, 'restrooms', 'Restrooms', 4, NULL, 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(31, 4, 'customer-lounge', 'Customer Lounge', 5, NULL, 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(32, 4, 'sales-executives-on-showroom-duty', 'Sales Executives on Showroom Duty', 6, NULL, 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
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
(83, 6, 'sales-coverage-1', 'Facilities', 1, NULL, 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(84, 6, 'sales-coverage-2', 'Product Presentation and Test Drive', 2, NULL, 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(85, 6, 'sales-coverage-3', 'Customer Engagement and Showroom Operations', 3, NULL, 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(86, 6, 'sales-coverage-4', 'Sales Operation Management', 4, NULL, 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(87, 6, 'sales-coverage-5', 'Lead Generation and Management', 5, NULL, 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(88, 6, 'sales-coverage-6', 'Manpower', 6, NULL, 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(89, 6, 'sales-coverage-7', 'Needs Analysis', 7, NULL, 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(90, 6, 'sales-coverage-8', 'Deal and Closing Management', 8, NULL, 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(91, 6, 'sales-coverage-9', 'Application Process Support', 9, NULL, 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(92, 6, 'sales-coverage-10', 'Vehicle Release Management', 10, NULL, 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(93, 6, 'sales-coverage-11', 'Post-Release Customer Management', 11, NULL, 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(94, 6, 'sales-coverage-12', 'Systems', 12, NULL, 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51'),
(95, 6, 'sales-coverage-13', 'Mandatory Reports', 13, NULL, 1, '2026-09-07 02:38:51', '2026-09-07 02:38:51');

-- --------------------------------------------------------

--
-- Table structure for table `checklist_submissions`
--

CREATE TABLE `checklist_submissions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `checklist_template_id` bigint(20) UNSIGNED DEFAULT NULL,
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
(2, 'dealer-operations-standards', 'Dealer Operations Standards - Aftersales', 'FY2025 Aftersales Standards Compliance Audit Sheet (75 Standards)', 2, '{\"validation_mode\":\"dos\",\"response_options\":[\"yes\",\"no\",\"na\"],\"instructions\":\"Judge every standard. NO requires a finding; N\\/A requires a reason.\",\"scoring\":{\"basic_required_percentage\":100,\"standard_required_percentage\":80,\"overall_required_percentage\":80},\"source\":\"FY25 Aftersales Standards Compliance Audit Sheet_updated as 08262026.xlsx\",\"short_name\":\"DOS Aftersales\",\"time_slots\":[]}', 1, '2026-08-21 23:21:21', '2026-09-05 08:08:23'),
(3, 'restroom', 'Restroom Checklist', 'Hourly restroom condition and orderliness inspection.', 2, '{\"validation_mode\":\"time_slots\",\"instructions\":\"Mark each hourly inspection as Good (\/) or Not Good (X), and add a row remark when needed.\",\"time_slots\":[{\"key\":\"08:00\",\"label\":\"8 AM\"},{\"key\":\"09:00\",\"label\":\"9 AM\"},{\"key\":\"10:00\",\"label\":\"10 AM\"},{\"key\":\"11:00\",\"label\":\"11 AM\"},{\"key\":\"13:00\",\"label\":\"1 PM\"},{\"key\":\"14:00\",\"label\":\"2 PM\"},{\"key\":\"15:00\",\"label\":\"3 PM\"},{\"key\":\"16:00\",\"label\":\"4 PM\"},{\"key\":\"17:00\",\"label\":\"5 PM\"}],\"legend\":{\"good\":\"\/\",\"not_good\":\"X\"},\"remark_per_item\":true,\"source\":\"Gateway 5S Checklist_2.xlsx \/ Restroom - Utility\"}', 1, '2026-08-21 23:21:21', '2026-09-08 17:12:00'),
(4, 'sales', 'Sales Checklist', 'Daily Sales showroom, reception, vehicle-display, and customer-readiness audit.', 1, '{\"validation_mode\":\"yes_no_na\",\"response_options\":[\"yes\",\"no\",\"na\"],\"instructions\":\"Complete every Sales item before business hours. A remark is required for NO and N/A.\",\"schedule\":{\"start\":\"08:00\",\"end\":\"08:30\"},\"source\":\"Gateway 5S Checklist.xlsx / Sales sections\",\"workspace_order\":20}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(5, 'service', 'Service Checklist', 'Daily Service reception, working-bay, and customer-readiness audit.', 1, '{\"validation_mode\":\"yes_no_na\",\"response_options\":[\"yes\",\"no\",\"na\"],\"instructions\":\"Complete every Service item before business hours. A remark is required for NO and N/A.\",\"schedule\":{\"start\":\"08:00\",\"end\":\"08:30\"},\"source\":\"Gateway 5S Checklist.xlsx / Service sections\",\"workspace_order\":30}', 1, '2026-08-28 22:40:08', '2026-08-28 22:40:08'),
(6, 'dealer-operations-standards-sales', 'Dealer Operations Standards - Sales', 'FY2025 Sales Standards Compliance Audit Main Form (90 Standards)', 1, '{\"validation_mode\":\"dos\",\"response_options\":[\"yes\",\"no\",\"na\"],\"instructions\":\"Judge every standard. NO requires a finding; N\\/A requires a reason.\",\"scoring\":{\"basic_required_percentage\":100,\"standard_required_percentage\":80,\"overall_required_percentage\":80},\"source\":\"FY25 Sales Standards Compliance Audit Sheet (REV02)_1.xlsx\",\"short_name\":\"DOS Sales\",\"time_slots\":[]}', 1, '2026-09-05 08:07:55', '2026-09-07 02:38:51'),
(7, 'dealer-operations-standards-subform', 'Dealer Operations Standards - Subform', 'FY2025 Aftersales Standards Compliance Audit Subform (39 Standards).', 1, '{\"validation_mode\":\"dos_subform\",\"response_options\":[\"yes\",\"no\",\"na\"],\"instructions\":\"Check each standard according to your assigned role. Note: Choosing \\\"No\\\" triggers a prerequisite cascade setting related items in the section to No.\",\"prerequisite_cascade\":true,\"short_name\":\"DOS Subform\",\"time_slots\":[]}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02'),
(8, 'dealer-operations-standards-documentation', 'Dealer Operations Standards - Documentation', 'FY2025 Aftersales Standards Compliance Audit Documentation Sheet (17 Standards).', 1, '{\"validation_mode\":\"dos_documentation\",\"response_options\":[\"yes\",\"no\",\"na\"],\"instructions\":\"Audit service documents (Rationalized Checksheet, Repair Order, Service Invoice) across multiple customers.\",\"prerequisite_cascade\":true,\"multi_customer\":true,\"default_customer_count\":3,\"short_name\":\"DOS Documentation\",\"time_slots\":[]}', 1, '2026-09-06 22:35:02', '2026-09-06 22:35:02');

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
(27, '2026_09_07_001300_finish_property_management_terminology_backfill', 17);

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
(2, 'App\\Models\\User', 5, 'expo-web', 'dd00f317a66ec56a5a8869ba442ea9ed9d0b4aa5f84d132305e5e99fd18d8704', '[\"*\"]', NULL, NULL, '2026-08-11 23:47:23', '2026-08-11 23:47:23'),
(13, 'App\\Models\\User', 5, 'expo-web', 'a2eea323e951a455cb5d54463b3fb9ca353531f202657ae32b279c95296f4890', '[\"*\"]', NULL, NULL, '2026-08-13 19:35:08', '2026-08-13 19:35:08'),
(17, 'App\\Models\\User', 5, 'expo-web', 'e57d09318e0ec8fc9f0b11d1e78f63ae53b604689b004b40f15bd9d448a76b3d', '[\"*\"]', NULL, NULL, '2026-08-14 18:46:07', '2026-08-14 18:46:07'),
(22, 'App\\Models\\User', 5, 'expo-web', '45c8dd8d7cc65ea8af688ed712fe9cda3c6d2bae1a16607f97d6f2342a400b42', '[\"*\"]', NULL, NULL, '2026-08-14 21:21:40', '2026-08-14 21:21:40'),
(58, 'App\\Models\\User', 5, 'expo-mobile', '757415fb13f9f54a93bb70587d9c09dbd512c1939b374613b73affad854d7817', '[\"*\"]', NULL, NULL, '2026-08-31 18:15:52', '2026-08-31 18:15:52'),
(59, 'App\\Models\\User', 5, 'expo-mobile', '841dbfd1f248d62320871da2a832fbebb929aa80aaad10c2c70fc04fd6692193', '[\"*\"]', NULL, NULL, '2026-08-31 18:22:05', '2026-08-31 18:22:05'),
(93, 'App\\Models\\User', 108, 'gateway-expo-app', 'b350004196f3c67bddee168d3840678c244b3c9372db5a291a7dee10ade90dd8', '[\"*\"]', '2026-09-04 23:57:08', NULL, '2026-09-04 23:56:39', '2026-09-04 23:57:08'),
(94, 'App\\Models\\User', 107, 'gateway-expo-app', '343b1c38cdc078bb682fdc89929d3c00314a8aadeedae837d55d6d3eb0fa6d29', '[\"*\"]', '2026-09-04 23:58:00', NULL, '2026-09-04 23:57:46', '2026-09-04 23:58:00'),
(95, 'App\\Models\\User', 107, 'gateway-expo-app', '2301a26cebb13716c55695237408bfff75478750be1f15a9030ee96776610bfc', '[\"*\"]', '2026-09-05 00:08:32', NULL, '2026-09-05 00:08:32', '2026-09-05 00:08:32'),
(96, 'App\\Models\\User', 108, 'gateway-expo-app', 'cce45a7e2742836dd444d3df467d6b5b8e613cecd72895e07bd1145afe656796', '[\"*\"]', '2026-09-05 00:08:34', NULL, '2026-09-05 00:08:33', '2026-09-05 00:08:34'),
(97, 'App\\Models\\User', 107, 'gateway-expo-app', '478ca1d7d5186710cf6299a6de39a7c715967b94d1aba80f714b7d612c832d19', '[\"*\"]', '2026-09-05 00:21:19', NULL, '2026-09-05 00:19:30', '2026-09-05 00:21:19'),
(98, 'App\\Models\\User', 107, 'gateway-expo-app', 'f94ec6f719718f6e7b67f807161ef447614a762bcebe9faaf3a0a09998fe8321', '[\"*\"]', '2026-09-05 00:56:32', NULL, '2026-09-05 00:55:56', '2026-09-05 00:56:32'),
(99, 'App\\Models\\User', 107, 'gateway-expo-app', '08de187ee72fdfd3a70e8c7c9dce2da7aaf5daf69463fec6391714348313cdb9', '[\"*\"]', '2026-09-05 00:58:48', NULL, '2026-09-05 00:58:45', '2026-09-05 00:58:48'),
(100, 'App\\Models\\User', 108, 'gateway-expo-app', '0b429d45e2182e2e05d4c389e9bee87abb05639c5dd1b2ded31151f1f0b8e49f', '[\"*\"]', '2026-09-05 00:59:28', NULL, '2026-09-05 00:59:25', '2026-09-05 00:59:28'),
(101, 'App\\Models\\User', 113, 'gateway-expo-app', '9f1b7c31b4e5c7a2f936fd567c9f98f827a9793ad3f19dca4cc7e7f03c686ca7', '[\"*\"]', '2026-09-05 01:00:05', NULL, '2026-09-05 01:00:02', '2026-09-05 01:00:05'),
(102, 'App\\Models\\User', 107, 'gateway-expo-app', '73f2a1a006c9ba899c05b466b79a85a04998c8bdbe3dd30c059e16f0cea08d67', '[\"*\"]', '2026-09-06 16:21:33', NULL, '2026-09-06 16:20:54', '2026-09-06 16:21:33'),
(104, 'App\\Models\\User', 107, 'gateway-expo-app', '48e6d42bd340e50b824fadc39b2a18c9a49b1f9c17e5497756bd4cb045730dd0', '[\"*\"]', '2026-09-06 16:35:54', NULL, '2026-09-06 16:35:51', '2026-09-06 16:35:54'),
(106, 'App\\Models\\User', 107, 'gateway-expo-app', 'ebce57ce13a9aab5472db14a69b7711bbe19eca8a4454b27e0c735a5d2f8c67a', '[\"*\"]', '2026-09-06 16:39:24', NULL, '2026-09-06 16:39:22', '2026-09-06 16:39:24'),
(107, 'App\\Models\\User', 107, 'gateway-expo-app', 'd00c0e0e8f4af9d086e82ef5c185a71a9f2288c052bd83ac2cf8abae5c2ae21a', '[\"*\"]', '2026-09-06 17:21:35', NULL, '2026-09-06 17:19:12', '2026-09-06 17:21:35'),
(108, 'App\\Models\\User', 107, 'gateway-expo-app', 'f59ab6b9cf1d2d897fb286a0694a3c2c33194af73e7d6a0bba40e90f6fcf85c6', '[\"*\"]', '2026-09-06 17:23:41', NULL, '2026-09-06 17:23:23', '2026-09-06 17:23:41'),
(110, 'App\\Models\\User', 108, 'gateway-expo-app', '45b3f5bcffe341ba01047d35d8d8cd66bbb8ffbd354cabe538e1f29129af7c45', '[\"*\"]', '2026-09-06 17:45:16', NULL, '2026-09-06 17:45:11', '2026-09-06 17:45:16'),
(117, 'App\\Models\\User', 107, 'gateway-expo-app', '403dbc204189657d96631a6ea8766b269edfe615933d9e31fd4f08f193b210d3', '[\"*\"]', '2026-09-06 18:48:50', NULL, '2026-09-06 18:45:25', '2026-09-06 18:48:50'),
(118, 'App\\Models\\User', 107, 'gateway-expo-app', 'cb69047f06e014c0f15936d1cb0f850ebe12d9956a317e72700e4d7994c9f452', '[\"*\"]', '2026-09-06 19:26:26', NULL, '2026-09-06 19:15:44', '2026-09-06 19:26:26'),
(123, 'App\\Models\\User', 107, 'gateway-expo-app', '51cc68c810b1eefc0ec8a081aa87c967050f627dfb59809b3f2d1c0bebedb001', '[\"*\"]', '2026-09-06 20:10:11', NULL, '2026-09-06 20:09:44', '2026-09-06 20:10:11'),
(124, 'App\\Models\\User', 107, 'gateway-expo-app', '02ade2fb9c8c444cdda3a7ea943d8af4f4d4afe4bdac2778af1c27708c58d16f', '[\"*\"]', '2026-09-06 20:26:44', NULL, '2026-09-06 20:25:26', '2026-09-06 20:26:44'),
(126, 'App\\Models\\User', 108, 'gateway-expo-app', 'e70f12d23e93bc8dd2f31ec4210c39815385dbff488afa1edb83163e2d881b52', '[\"*\"]', '2026-09-06 20:51:31', NULL, '2026-09-06 20:47:20', '2026-09-06 20:51:31'),
(129, 'App\\Models\\User', 112, 'gateway-expo-app', 'd85bf3c902eeb1ec278862c7d35d73673e40f0a44f61e0366ef9fad8bddc04c2', '[\"*\"]', '2026-09-06 21:57:48', NULL, '2026-09-06 21:54:37', '2026-09-06 21:57:48'),
(131, 'App\\Models\\User', 108, 'gateway-expo-app', '9414e1fb841de7f56983dc43ecfeac8b6662bc7f36cd5bde3309b22b67aa4de2', '[\"*\"]', '2026-09-06 22:01:49', NULL, '2026-09-06 22:01:20', '2026-09-06 22:01:49'),
(132, 'App\\Models\\User', 108, 'gateway-expo-app', '632abbb5691c9069d097ea87391af07c4f2b3d6bdf87397d5a521fb8b3ff9282', '[\"*\"]', '2026-09-06 22:07:29', NULL, '2026-09-06 22:02:38', '2026-09-06 22:07:29'),
(134, 'App\\Models\\User', 108, 'gateway-expo-app', 'afd8fc77573884861c3f3652a8929555cf1275197c1f49aacbaa707b8e88eca9', '[\"*\"]', '2026-09-06 22:36:55', NULL, '2026-09-06 22:18:20', '2026-09-06 22:36:55'),
(135, 'App\\Models\\User', 107, 'gateway-expo-app', 'fd07d9a2deed2780cb443acbf8f15432fd0c6188bbb98f168b55384107b3f410', '[\"*\"]', '2026-09-06 23:14:56', NULL, '2026-09-06 23:14:29', '2026-09-06 23:14:56'),
(136, 'App\\Models\\User', 107, 'gateway-expo-app', 'f997dea622651bcb6339a4f3ddacde0fd35a538438076884d96ca34d95dfdd41', '[\"*\"]', '2026-09-06 23:45:56', NULL, '2026-09-06 23:22:56', '2026-09-06 23:45:56'),
(137, 'App\\Models\\User', 108, 'gateway-expo-app', 'e73482db8c5afb9535966bbd581f0911943d5796a70e7315e53f0a6e2e3a810d', '[\"*\"]', '2026-09-07 00:29:28', NULL, '2026-09-07 00:13:57', '2026-09-07 00:29:28'),
(141, 'App\\Models\\User', 120, 'gateway-expo-app', '1d6610168426ca5a0d63479c76a17fd5460cc55709bd7e1486696438369623cf', '[\"*\"]', '2026-09-07 01:19:56', NULL, '2026-09-07 01:19:51', '2026-09-07 01:19:56'),
(143, 'App\\Models\\User', 107, 'gateway-expo-app', '826aec1cfd27bc0ab0e5b7de78aec6bb431877b5abcba5467fc674f9d95873d8', '[\"*\"]', '2026-09-07 01:55:38', NULL, '2026-09-07 01:55:32', '2026-09-07 01:55:38'),
(145, 'App\\Models\\User', 108, 'gateway-expo-app', '1ce753d83e7a85325d4a00364e745decc75a4027519d38bf99cbfad812b99fb7', '[\"*\"]', '2026-09-07 16:24:38', NULL, '2026-09-07 16:19:23', '2026-09-07 16:24:38'),
(147, 'App\\Models\\User', 108, 'gateway-expo-app', '74d19bd632ce741801b72056da4a7dbf99e8df904bc6ba8ad8c57f0e27caea8c', '[\"*\"]', '2026-09-07 17:09:14', NULL, '2026-09-07 16:50:47', '2026-09-07 17:09:14'),
(149, 'App\\Models\\User', 108, 'gateway-expo-app', '69595e59b3eb59ce951aa8b612dfd75233c13ac5f49c7e80f2e52b41de88ec1e', '[\"*\"]', '2026-09-07 17:14:56', NULL, '2026-09-07 17:10:36', '2026-09-07 17:14:56'),
(150, 'App\\Models\\User', 108, 'gateway-expo-app', 'e4d026bf09af5bbfe7451dbf4828f01b24186e64ad45a4e623d7860fd6f2770b', '[\"*\"]', '2026-09-07 17:18:45', NULL, '2026-09-07 17:16:10', '2026-09-07 17:18:45');

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
('2AXBDd8SeXVZm7DswZJ5t8yiQi7mQvs1RQVhJO4g', NULL, '192.168.102.55', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoiQW9XUTY5NWwwWFhPYXlJWHA4NHpodHV3aEVZZWpxREprc2VxZWlYUCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzY6Imh0dHA6Ly8xOTIuMTY4LjEwMi41NTo4MDAwL2Rhc2hib2FyZCI7czo1OiJyb3V0ZSI7czo5OiJkYXNoYm9hcmQiO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX1zOjM6InVybCI7YToxOntzOjg6ImludGVuZGVkIjtzOjM2OiJodHRwOi8vMTkyLjE2OC4xMDIuNTU6ODAwMC9kYXNoYm9hcmQiO319', 1788778317),
('aO2El9afp2pkzUxPZ7pwMexpFvIHoAy9sX8S9HGe', NULL, '10.0.20.100', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoieUNQbGFON1g2VDRPS2IyVllKTW9TVFFQd25ka1pFckh4VEdNNUpNSiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MjM6Imh0dHA6Ly8xMC4wLjIwLjEwMDo4MDAwIjtzOjU6InJvdXRlIjtOO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1788826010),
('KQ7fDOO3N7qozZBtf62v89p4CFhcWYq0TWJE9RqW', 5, '192.168.102.55', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36', 'YTo1OntzOjY6Il90b2tlbiI7czo0MDoiOHZ1WnkzVEZBYklIQkpuZkUxVjNOcEU3bFpSVlNWYXBZWnB4SHhOWiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzY6Imh0dHA6Ly8xOTIuMTY4LjEwMi41NTo4MDAwL2Rhc2hib2FyZCI7czo1OiJyb3V0ZSI7czo5OiJkYXNoYm9hcmQiO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX1zOjM6InVybCI7YTowOnt9czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6NTt9', 1788778745),
('XcEbk7w86kCcfYytbW7RvXtPucTH8sF3kh6K1oEt', 5, '10.0.20.100', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36', 'YTo1OntzOjY6Il90b2tlbiI7czo0MDoiU3VEWlVTaGJMTGluek9JNDNoWGxtak9kTjFIa2FiaFZQcDlkVHp1SiI7czozOiJ1cmwiO2E6MDp7fXM6OToiX3ByZXZpb3VzIjthOjI6e3M6MzoidXJsIjtzOjMzOiJodHRwOi8vMTAuMC4yMC4xMDA6ODAwMC9kYXNoYm9hcmQiO3M6NToicm91dGUiO3M6OToiZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6NTt9', 1788776877),
('XFWfBAxSIhECnpQZLuukmtncQLklMiRodLSLrb9L', 5, '10.0.20.100', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36', 'YTo1OntzOjY6Il90b2tlbiI7czo0MDoid0U2bnJoNW5zdnBmbGFGcjBSNmdWdUFJTU5LNDc4Vmt4c1l2UGlYaSI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NzI6Imh0dHA6Ly8xMC4wLjIwLjEwMDo4MDAwL2Rhc2hib2FyZD9icmFuY2g9R2F0ZXdheSUyMEJhbGludGF3YWsmZm9ybT1zYWxlcyI7czo1OiJyb3V0ZSI7czo5OiJkYXNoYm9hcmQiO31zOjM6InVybCI7YTowOnt9czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6NTt9', 1788830381);

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

INSERT INTO `users` (`id`, `name`, `email`, `branch`, `user_type`, `pic_assignment_type`, `account_status`, `email_verified_at`, `avatar_path`, `password`, `remember_token`, `created_at`, `updated_at`) VALUES
(5, 'General Manager', 'gm@gateway.com', 'SUZUKI PASONG TAMO', 'ADMIN', NULL, 'active', '2026-09-05 01:43:56', NULL, '$2y$12$VlZTNVXmlM2Z44Z.NrtwoeKiP6zOBjkCZBj0MpPREwDNyH26od7N.', 'IqQoNUDuMaWb9QEzMxCsWxO5CTeXnVzk9S2wwEAuMYrPvCMVPQZYOXz3wu0K', '2026-08-06 17:48:51', '2026-09-06 16:19:42'),
(107, 'Marcus Sales (Sales Manager)', 'sm@gateway.com', 'SUZUKI PASONG TAMO', 'SALES_MANAGER', NULL, 'active', '2026-09-05 01:43:56', NULL, '$2y$10$24HFdoMQkcr1WdIyiF0LZucDl3jlYgEPh/.HISQN5p208WG7D8qcq', NULL, '2026-09-05 01:43:56', '2026-09-05 01:43:56'),
(108, 'Carlo Mendoza (Aftersales Manager)', 'asm@gateway.com', 'SUZUKI PASONG TAMO', 'ASM', NULL, 'active', '2026-09-05 01:43:56', NULL, '$2y$10$24HFdoMQkcr1WdIyiF0LZucDl3jlYgEPh/.HISQN5p208WG7D8qcq', NULL, '2026-09-05 01:43:56', '2026-09-05 01:43:56'),
(109, 'Maria Santos (CE Service)', 'ce@gateway.com', 'SUZUKI PASONG TAMO', 'CE SERVICE', NULL, 'active', '2026-09-05 01:43:56', NULL, '$2y$10$24HFdoMQkcr1WdIyiF0LZucDl3jlYgEPh/.HISQN5p208WG7D8qcq', NULL, '2026-09-05 01:43:56', '2026-09-05 01:43:56'),
(110, 'David Cruz (Job Controller)', 'jc@gateway.com', 'SUZUKI PASONG TAMO', 'JOB CONTROLLER', NULL, 'active', '2026-09-05 01:43:56', NULL, '$2y$10$24HFdoMQkcr1WdIyiF0LZucDl3jlYgEPh/.HISQN5p208WG7D8qcq', NULL, '2026-09-05 01:43:56', '2026-09-05 01:43:56'),
(111, 'Peter Reyes (Parts Supervisor)', 'parts@gateway.com', 'SUZUKI PASONG TAMO', 'PARTS SUPERVISOR', NULL, 'active', '2026-09-05 01:43:56', NULL, '$2y$10$24HFdoMQkcr1WdIyiF0LZucDl3jlYgEPh/.HISQN5p208WG7D8qcq', NULL, '2026-09-05 01:43:56', '2026-09-05 01:43:56'),
(112, 'William Bautista (Workshop Supervisor)', 'ws.sup@gateway.com', 'SUZUKI PASONG TAMO', 'WORKSHOP SUP', NULL, 'active', '2026-09-05 01:43:56', NULL, '$2y$10$24HFdoMQkcr1WdIyiF0LZucDl3jlYgEPh/.HISQN5p208WG7D8qcq', NULL, '2026-09-05 01:43:56', '2026-09-05 01:43:56'),
(113, 'Walter Ramos (Workshop)', 'ws@gateway.com', 'SUZUKI PASONG TAMO', 'WORKSHOP', NULL, 'active', '2026-09-05 01:43:56', NULL, '$2y$10$24HFdoMQkcr1WdIyiF0LZucDl3jlYgEPh/.HISQN5p208WG7D8qcq', NULL, '2026-09-05 01:43:56', '2026-09-05 01:43:56'),
(114, 'Roberto Garcia (Branch Operations Manager)', 'bom@gateway.com', 'SUZUKI PASONG TAMO', 'BOM', NULL, 'active', '2026-09-05 01:43:56', NULL, '$2y$12$ntW5yyZmjCepLfG5jkwXnuLuMUHyYnSsLbis/iSD6LXrQFyeroqv2', NULL, '2026-09-05 01:43:56', '2026-09-07 16:08:58'),
(116, '5S Utilities', 'utilities@gateway.com', 'SUZUKI PASONG TAMO', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(117, '5S Service', 'service@gateway.com', 'SUZUKI PASONG TAMO', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$WyCpeHxFgv4mVJKL5ChSj.kDFq43cuvQEN3aHrYM.Ekt6L28CSKQm', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(118, '5S Sales', 'sales@gateway.com', 'SUZUKI PASONG TAMO', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$BEmNeN8XBaloAtkVfvh0h.KfEvRWJABxxIImQ8s4PBO1HribWMk2O', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(119, 'HONDA MAKATI 5S Utilities', 'honda-makati.utilities@5s.gateway.local', 'HONDA MAKATI', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(120, 'HONDA MAKATI 5S Service', 'honda-makati.service@5s.gateway.local', 'HONDA MAKATI', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(121, 'HONDA MAKATI 5S Sales', 'honda-makati.sales@5s.gateway.local', 'HONDA MAKATI', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(122, 'HYUNDAI MAKATI 5S Utilities', 'hyundai-makati.utilities@5s.gateway.local', 'HYUNDAI MAKATI', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(123, 'HYUNDAI MAKATI 5S Service', 'hyundai-makati.service@5s.gateway.local', 'HYUNDAI MAKATI', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(124, 'HYUNDAI MAKATI 5S Sales', 'hyundai-makati.sales@5s.gateway.local', 'HYUNDAI MAKATI', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(125, 'SUZUKI PASONG TAMO 5S Utilities', 'suzuki-pasong-tamo.utilities@5s.gateway.local', 'SUZUKI PASONG TAMO', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(126, 'SUZUKI PASONG TAMO 5S Service', 'suzuki-pasong-tamo.service@5s.gateway.local', 'SUZUKI PASONG TAMO', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(127, 'SUZUKI PASONG TAMO 5S Sales', 'suzuki-pasong-tamo.sales@5s.gateway.local', 'SUZUKI PASONG TAMO', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(128, 'KIA OTIS 5S Utilities', 'kia-otis.utilities@5s.gateway.local', 'KIA OTIS', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(129, 'KIA OTIS 5S Service', 'kia-otis.service@5s.gateway.local', 'KIA OTIS', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(130, 'KIA OTIS 5S Sales', 'kia-otis.sales@5s.gateway.local', 'KIA OTIS', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(131, 'HONDA FAIRVIEW 5S Utilities', 'honda-fairview.utilities@5s.gateway.local', 'HONDA FAIRVIEW', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(132, 'HONDA FAIRVIEW 5S Service', 'honda-fairview.service@5s.gateway.local', 'HONDA FAIRVIEW', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(133, 'HONDA FAIRVIEW 5S Sales', 'honda-fairview.sales@5s.gateway.local', 'HONDA FAIRVIEW', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(134, 'MITSUBISHI FAIRVIEW 5S Utilities', 'mitsubishi-fairview.utilities@5s.gateway.local', 'MITSUBISHI FAIRVIEW', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(135, 'MITSUBISHI FAIRVIEW 5S Service', 'mitsubishi-fairview.service@5s.gateway.local', 'MITSUBISHI FAIRVIEW', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(136, 'MITSUBISHI FAIRVIEW 5S Sales', 'mitsubishi-fairview.sales@5s.gateway.local', 'MITSUBISHI FAIRVIEW', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(137, 'MITSUBISHI QUEZON AVENUE 5S Utilities', 'mitsubishi-quezon-avenue.utilities@5s.gateway.local', 'MITSUBISHI QUEZON AVENUE', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(138, 'MITSUBISHI QUEZON AVENUE 5S Service', 'mitsubishi-quezon-avenue.service@5s.gateway.local', 'MITSUBISHI QUEZON AVENUE', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(139, 'MITSUBISHI QUEZON AVENUE 5S Sales', 'mitsubishi-quezon-avenue.sales@5s.gateway.local', 'MITSUBISHI QUEZON AVENUE', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(140, 'HONDA MARCOS HIGHWAY 5S Utilities', 'honda-marcos-highway.utilities@5s.gateway.local', 'HONDA MARCOS HIGHWAY', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(141, 'HONDA MARCOS HIGHWAY 5S Service', 'honda-marcos-highway.service@5s.gateway.local', 'HONDA MARCOS HIGHWAY', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(142, 'HONDA MARCOS HIGHWAY 5S Sales', 'honda-marcos-highway.sales@5s.gateway.local', 'HONDA MARCOS HIGHWAY', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(143, 'HONDA CAINTA 5S Utilities', 'honda-cainta.utilities@5s.gateway.local', 'HONDA CAINTA', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(144, 'HONDA CAINTA 5S Service', 'honda-cainta.service@5s.gateway.local', 'HONDA CAINTA', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(145, 'HONDA CAINTA 5S Sales', 'honda-cainta.sales@5s.gateway.local', 'HONDA CAINTA', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(146, 'GEELY CAINTA 5S Utilities', 'geely-cainta.utilities@5s.gateway.local', 'GEELY CAINTA', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(147, 'GEELY CAINTA 5S Service', 'geely-cainta.service@5s.gateway.local', 'GEELY CAINTA', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(148, 'GEELY CAINTA 5S Sales', 'geely-cainta.sales@5s.gateway.local', 'GEELY CAINTA', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(149, 'MITSUBISHI PASIG 5S Utilities', 'mitsubishi-pasig.utilities@5s.gateway.local', 'MITSUBISHI PASIG', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(150, 'MITSUBISHI PASIG 5S Service', 'mitsubishi-pasig.service@5s.gateway.local', 'MITSUBISHI PASIG', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(151, 'MITSUBISHI PASIG 5S Sales', 'mitsubishi-pasig.sales@5s.gateway.local', 'MITSUBISHI PASIG', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(152, 'MITSUBISHI SUCAT 5S Utilities', 'mitsubishi-sucat.utilities@5s.gateway.local', 'MITSUBISHI SUCAT', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(153, 'MITSUBISHI SUCAT 5S Service', 'mitsubishi-sucat.service@5s.gateway.local', 'MITSUBISHI SUCAT', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(154, 'MITSUBISHI SUCAT 5S Sales', 'mitsubishi-sucat.sales@5s.gateway.local', 'MITSUBISHI SUCAT', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(155, 'HONDA ALABANG 5S Utilities', 'honda-alabang.utilities@5s.gateway.local', 'HONDA ALABANG', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(156, 'HONDA ALABANG 5S Service', 'honda-alabang.service@5s.gateway.local', 'HONDA ALABANG', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(157, 'HONDA ALABANG 5S Sales', 'honda-alabang.sales@5s.gateway.local', 'HONDA ALABANG', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(158, 'MG LAS PINAS 5S Utilities', 'mg-las-pinas.utilities@5s.gateway.local', 'MG LAS PINAS', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(159, 'MG LAS PINAS 5S Service', 'mg-las-pinas.service@5s.gateway.local', 'MG LAS PINAS', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(160, 'MG LAS PINAS 5S Sales', 'mg-las-pinas.sales@5s.gateway.local', 'MG LAS PINAS', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(161, 'CHANGAN BACOOR (old Nissan) 5S Utilities', 'changan-bacoor-old-nissan.utilities@5s.gateway.local', 'CHANGAN BACOOR (old Nissan)', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(162, 'CHANGAN BACOOR (old Nissan) 5S Service', 'changan-bacoor-old-nissan.service@5s.gateway.local', 'CHANGAN BACOOR (old Nissan)', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(163, 'CHANGAN BACOOR (old Nissan) 5S Sales', 'changan-bacoor-old-nissan.sales@5s.gateway.local', 'CHANGAN BACOOR (old Nissan)', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(164, 'KIA DASMARINAS 5S Utilities', 'kia-dasmarinas.utilities@5s.gateway.local', 'KIA DASMARINAS', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(165, 'KIA DASMARINAS 5S Service', 'kia-dasmarinas.service@5s.gateway.local', 'KIA DASMARINAS', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(166, 'KIA DASMARINAS 5S Sales', 'kia-dasmarinas.sales@5s.gateway.local', 'KIA DASMARINAS', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(167, 'MG MARILAO 5S Utilities', 'mg-marilao.utilities@5s.gateway.local', 'MG MARILAO', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(168, 'MG MARILAO 5S Service', 'mg-marilao.service@5s.gateway.local', 'MG MARILAO', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(169, 'MG MARILAO 5S Sales', 'mg-marilao.sales@5s.gateway.local', 'MG MARILAO', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(170, 'MG/GEELY ANGELES 5S Utilities', 'mg-geely-angeles.utilities@5s.gateway.local', 'MG/GEELY ANGELES', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(171, 'MG/GEELY ANGELES 5S Service', 'mg-geely-angeles.service@5s.gateway.local', 'MG/GEELY ANGELES', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(172, 'MG/GEELY ANGELES 5S Sales', 'mg-geely-angeles.sales@5s.gateway.local', 'MG/GEELY ANGELES', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(173, 'GEELY TARLAC 5S Utilities', 'geely-tarlac.utilities@5s.gateway.local', 'GEELY TARLAC', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(174, 'GEELY TARLAC 5S Service', 'geely-tarlac.service@5s.gateway.local', 'GEELY TARLAC', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(175, 'GEELY TARLAC 5S Sales', 'geely-tarlac.sales@5s.gateway.local', 'GEELY TARLAC', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(176, 'HONDA ISABELA 5S Utilities', 'honda-isabela.utilities@5s.gateway.local', 'HONDA ISABELA', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(177, 'HONDA ISABELA 5S Service', 'honda-isabela.service@5s.gateway.local', 'HONDA ISABELA', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(178, 'HONDA ISABELA 5S Sales', 'honda-isabela.sales@5s.gateway.local', 'HONDA ISABELA', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(179, 'SUZUKI SANTA ROSA 5S Utilities', 'suzuki-santa-rosa.utilities@5s.gateway.local', 'SUZUKI SANTA ROSA', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(180, 'SUZUKI SANTA ROSA 5S Service', 'suzuki-santa-rosa.service@5s.gateway.local', 'SUZUKI SANTA ROSA', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(181, 'SUZUKI SANTA ROSA 5S Sales', 'suzuki-santa-rosa.sales@5s.gateway.local', 'SUZUKI SANTA ROSA', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(182, 'MITSUBISHI CALAMBA 5S Utilities', 'mitsubishi-calamba.utilities@5s.gateway.local', 'MITSUBISHI CALAMBA', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(183, 'MITSUBISHI CALAMBA 5S Service', 'mitsubishi-calamba.service@5s.gateway.local', 'MITSUBISHI CALAMBA', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(184, 'MITSUBISHI CALAMBA 5S Sales', 'mitsubishi-calamba.sales@5s.gateway.local', 'MITSUBISHI CALAMBA', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(185, 'GEELY LIPA 5S Utilities', 'geely-lipa.utilities@5s.gateway.local', 'GEELY LIPA', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(186, 'GEELY LIPA 5S Service', 'geely-lipa.service@5s.gateway.local', 'GEELY LIPA', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(187, 'GEELY LIPA 5S Sales', 'geely-lipa.sales@5s.gateway.local', 'GEELY LIPA', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(188, 'SUZUKI ALAMINOS 5S Utilities', 'suzuki-alaminos.utilities@5s.gateway.local', 'SUZUKI ALAMINOS', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(189, 'SUZUKI ALAMINOS 5S Service', 'suzuki-alaminos.service@5s.gateway.local', 'SUZUKI ALAMINOS', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(190, 'SUZUKI ALAMINOS 5S Sales', 'suzuki-alaminos.sales@5s.gateway.local', 'SUZUKI ALAMINOS', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(191, 'KIA SAN PABLO 5S Utilities', 'kia-san-pablo.utilities@5s.gateway.local', 'KIA SAN PABLO', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(192, 'KIA SAN PABLO 5S Service', 'kia-san-pablo.service@5s.gateway.local', 'KIA SAN PABLO', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(193, 'KIA SAN PABLO 5S Sales', 'kia-san-pablo.sales@5s.gateway.local', 'KIA SAN PABLO', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(194, 'MG SAN PABLO 5S Utilities', 'mg-san-pablo.utilities@5s.gateway.local', 'MG SAN PABLO', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(195, 'MG SAN PABLO 5S Service', 'mg-san-pablo.service@5s.gateway.local', 'MG SAN PABLO', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(196, 'MG SAN PABLO 5S Sales', 'mg-san-pablo.sales@5s.gateway.local', 'MG SAN PABLO', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(197, 'MITSUBISHI PILI 5S Utilities', 'mitsubishi-pili.utilities@5s.gateway.local', 'MITSUBISHI PILI', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(198, 'MITSUBISHI PILI 5S Service', 'mitsubishi-pili.service@5s.gateway.local', 'MITSUBISHI PILI', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(199, 'MITSUBISHI PILI 5S Sales', 'mitsubishi-pili.sales@5s.gateway.local', 'MITSUBISHI PILI', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(200, 'MITSUBISHI LEGAZPI 5S Utilities', 'mitsubishi-legazpi.utilities@5s.gateway.local', 'MITSUBISHI LEGAZPI', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(201, 'MITSUBISHI LEGAZPI 5S Service', 'mitsubishi-legazpi.service@5s.gateway.local', 'MITSUBISHI LEGAZPI', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(202, 'MITSUBISHI LEGAZPI 5S Sales', 'mitsubishi-legazpi.sales@5s.gateway.local', 'MITSUBISHI LEGAZPI', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(203, 'MITSUBISHI GREENHILLS 5S Utilities', 'mitsubishi-greenhills.utilities@5s.gateway.local', 'MITSUBISHI GREENHILLS', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(204, 'MITSUBISHI GREENHILLS 5S Service', 'mitsubishi-greenhills.service@5s.gateway.local', 'MITSUBISHI GREENHILLS', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(205, 'MITSUBISHI GREENHILLS 5S Sales', 'mitsubishi-greenhills.sales@5s.gateway.local', 'MITSUBISHI GREENHILLS', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(206, 'HONDA MANILA BAY 5S Utilities', 'honda-manila-bay.utilities@5s.gateway.local', 'HONDA MANILA BAY', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(207, 'HONDA MANILA BAY 5S Service', 'honda-manila-bay.service@5s.gateway.local', 'HONDA MANILA BAY', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(208, 'HONDA MANILA BAY 5S Sales', 'honda-manila-bay.sales@5s.gateway.local', 'HONDA MANILA BAY', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(209, 'HYUNDAI MANDAUE 5S Utilities', 'hyundai-mandaue.utilities@5s.gateway.local', 'HYUNDAI MANDAUE', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(210, 'HYUNDAI MANDAUE 5S Service', 'hyundai-mandaue.service@5s.gateway.local', 'HYUNDAI MANDAUE', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(211, 'HYUNDAI MANDAUE 5S Sales', 'hyundai-mandaue.sales@5s.gateway.local', 'HYUNDAI MANDAUE', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(212, 'KIA / GEELY MANDAUE 5S Utilities', 'kia-geely-mandaue.utilities@5s.gateway.local', 'KIA / GEELY MANDAUE', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(213, 'KIA / GEELY MANDAUE 5S Service', 'kia-geely-mandaue.service@5s.gateway.local', 'KIA / GEELY MANDAUE', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(214, 'KIA / GEELY MANDAUE 5S Sales', 'kia-geely-mandaue.sales@5s.gateway.local', 'KIA / GEELY MANDAUE', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(215, 'MERCEDES-BENZ MANDAUE 5S Utilities', 'mercedes-benz-mandaue.utilities@5s.gateway.local', 'MERCEDES-BENZ MANDAUE', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(216, 'MERCEDES-BENZ MANDAUE 5S Service', 'mercedes-benz-mandaue.service@5s.gateway.local', 'MERCEDES-BENZ MANDAUE', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(217, 'MERCEDES-BENZ MANDAUE 5S Sales', 'mercedes-benz-mandaue.sales@5s.gateway.local', 'MERCEDES-BENZ MANDAUE', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(218, 'OMODA & JAECOO CEBU CITY 5S Utilities', 'omoda-jaecoo-cebu-city.utilities@5s.gateway.local', 'OMODA & JAECOO CEBU CITY', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(219, 'OMODA & JAECOO CEBU CITY 5S Service', 'omoda-jaecoo-cebu-city.service@5s.gateway.local', 'OMODA & JAECOO CEBU CITY', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(220, 'OMODA & JAECOO CEBU CITY 5S Sales', 'omoda-jaecoo-cebu-city.sales@5s.gateway.local', 'OMODA & JAECOO CEBU CITY', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(221, 'MITSUBISHI TALISAY 5S Utilities', 'mitsubishi-talisay.utilities@5s.gateway.local', 'MITSUBISHI TALISAY', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(222, 'MITSUBISHI TALISAY 5S Service', 'mitsubishi-talisay.service@5s.gateway.local', 'MITSUBISHI TALISAY', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(223, 'MITSUBISHI TALISAY 5S Sales', 'mitsubishi-talisay.sales@5s.gateway.local', 'MITSUBISHI TALISAY', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(224, 'HONDA TALISAY 5S Utilities', 'honda-talisay.utilities@5s.gateway.local', 'HONDA TALISAY', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(225, 'HONDA TALISAY 5S Service', 'honda-talisay.service@5s.gateway.local', 'HONDA TALISAY', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(226, 'HONDA TALISAY 5S Sales', 'honda-talisay.sales@5s.gateway.local', 'HONDA TALISAY', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(227, 'GEELY TALISAY 5S Utilities', 'geely-talisay.utilities@5s.gateway.local', 'GEELY TALISAY', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(228, 'GEELY TALISAY 5S Service', 'geely-talisay.service@5s.gateway.local', 'GEELY TALISAY', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(229, 'GEELY TALISAY 5S Sales', 'geely-talisay.sales@5s.gateway.local', 'GEELY TALISAY', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(230, 'MITSUBISHI GORORDO 5S Utilities', 'mitsubishi-gorordo.utilities@5s.gateway.local', 'MITSUBISHI GORORDO', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(231, 'MITSUBISHI GORORDO 5S Service', 'mitsubishi-gorordo.service@5s.gateway.local', 'MITSUBISHI GORORDO', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(232, 'MITSUBISHI GORORDO 5S Sales', 'mitsubishi-gorordo.sales@5s.gateway.local', 'MITSUBISHI GORORDO', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(233, 'MG NRA 5S Utilities', 'mg-nra.utilities@5s.gateway.local', 'MG NRA', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(234, 'MG NRA 5S Service', 'mg-nra.service@5s.gateway.local', 'MG NRA', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(235, 'MG NRA 5S Sales', 'mg-nra.sales@5s.gateway.local', 'MG NRA', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(236, 'KIA NRA 5S Utilities', 'kia-nra.utilities@5s.gateway.local', 'KIA NRA', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(237, 'KIA NRA 5S Service', 'kia-nra.service@5s.gateway.local', 'KIA NRA', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(238, 'KIA NRA 5S Sales', 'kia-nra.sales@5s.gateway.local', 'KIA NRA', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(239, 'GEELY CEBU 5S Utilities', 'geely-cebu.utilities@5s.gateway.local', 'GEELY CEBU', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(240, 'GEELY CEBU 5S Service', 'geely-cebu.service@5s.gateway.local', 'GEELY CEBU', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(241, 'GEELY CEBU 5S Sales', 'geely-cebu.sales@5s.gateway.local', 'GEELY CEBU', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(242, 'JETOUR TALISAY 5S Utilities', 'jetour-talisay.utilities@5s.gateway.local', 'JETOUR TALISAY', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(243, 'JETOUR TALISAY 5S Service', 'jetour-talisay.service@5s.gateway.local', 'JETOUR TALISAY', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(244, 'JETOUR TALISAY 5S Sales', 'jetour-talisay.sales@5s.gateway.local', 'JETOUR TALISAY', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(245, 'MERCEDES-BENZ BOHOL 5S Utilities', 'mercedes-benz-bohol.utilities@5s.gateway.local', 'MERCEDES-BENZ BOHOL', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(246, 'MERCEDES-BENZ BOHOL 5S Service', 'mercedes-benz-bohol.service@5s.gateway.local', 'MERCEDES-BENZ BOHOL', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(247, 'MERCEDES-BENZ BOHOL 5S Sales', 'mercedes-benz-bohol.sales@5s.gateway.local', 'MERCEDES-BENZ BOHOL', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(248, 'GEELY BACOLOD 5S Utilities', 'geely-bacolod.utilities@5s.gateway.local', 'GEELY BACOLOD', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(249, 'GEELY BACOLOD 5S Service', 'geely-bacolod.service@5s.gateway.local', 'GEELY BACOLOD', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(250, 'GEELY BACOLOD 5S Sales', 'geely-bacolod.sales@5s.gateway.local', 'GEELY BACOLOD', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(251, 'HONDA MANDAUE 5S Utilities', 'honda-mandaue.utilities@5s.gateway.local', 'HONDA MANDAUE', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(252, 'HONDA MANDAUE 5S Service', 'honda-mandaue.service@5s.gateway.local', 'HONDA MANDAUE', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(253, 'HONDA MANDAUE 5S Sales', 'honda-mandaue.sales@5s.gateway.local', 'HONDA MANDAUE', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(254, 'MITSUBISHI MATINA 5S Utilities', 'mitsubishi-matina.utilities@5s.gateway.local', 'MITSUBISHI MATINA', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(255, 'MITSUBISHI MATINA 5S Service', 'mitsubishi-matina.service@5s.gateway.local', 'MITSUBISHI MATINA', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(256, 'MITSUBISHI MATINA 5S Sales', 'mitsubishi-matina.sales@5s.gateway.local', 'MITSUBISHI MATINA', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(257, 'HYUNDAI BUHANGIN 5S Utilities', 'hyundai-buhangin.utilities@5s.gateway.local', 'HYUNDAI BUHANGIN', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(258, 'HYUNDAI BUHANGIN 5S Service', 'hyundai-buhangin.service@5s.gateway.local', 'HYUNDAI BUHANGIN', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(259, 'HYUNDAI BUHANGIN 5S Sales', 'hyundai-buhangin.sales@5s.gateway.local', 'HYUNDAI BUHANGIN', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(260, 'JAECO & OMODA LANANG 5S Utilities', 'jaeco-omoda-lanang.utilities@5s.gateway.local', 'JAECO & OMODA LANANG', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(261, 'JAECO & OMODA LANANG 5S Service', 'jaeco-omoda-lanang.service@5s.gateway.local', 'JAECO & OMODA LANANG', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(262, 'JAECO & OMODA LANANG 5S Sales', 'jaeco-omoda-lanang.sales@5s.gateway.local', 'JAECO & OMODA LANANG', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(263, 'MITSUBISHI DIGOS 5S Utilities', 'mitsubishi-digos.utilities@5s.gateway.local', 'MITSUBISHI DIGOS', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(264, 'MITSUBISHI DIGOS 5S Service', 'mitsubishi-digos.service@5s.gateway.local', 'MITSUBISHI DIGOS', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(265, 'MITSUBISHI DIGOS 5S Sales', 'mitsubishi-digos.sales@5s.gateway.local', 'MITSUBISHI DIGOS', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(266, 'BRP KIDAPAWAN 5S Utilities', 'brp-kidapawan.utilities@5s.gateway.local', 'BRP KIDAPAWAN', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(267, 'BRP KIDAPAWAN 5S Service', 'brp-kidapawan.service@5s.gateway.local', 'BRP KIDAPAWAN', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(268, 'BRP KIDAPAWAN 5S Sales', 'brp-kidapawan.sales@5s.gateway.local', 'BRP KIDAPAWAN', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(269, 'MITSUBISHI COTABATO CITY 5S Utilities', 'mitsubishi-cotabato-city.utilities@5s.gateway.local', 'MITSUBISHI COTABATO CITY', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(270, 'MITSUBISHI COTABATO CITY 5S Service', 'mitsubishi-cotabato-city.service@5s.gateway.local', 'MITSUBISHI COTABATO CITY', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(271, 'MITSUBISHI COTABATO CITY 5S Sales', 'mitsubishi-cotabato-city.sales@5s.gateway.local', 'MITSUBISHI COTABATO CITY', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(272, 'MITSUBISHI TAGUM 5S Utilities', 'mitsubishi-tagum.utilities@5s.gateway.local', 'MITSUBISHI TAGUM', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(273, 'MITSUBISHI TAGUM 5S Service', 'mitsubishi-tagum.service@5s.gateway.local', 'MITSUBISHI TAGUM', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(274, 'MITSUBISHI TAGUM 5S Sales', 'mitsubishi-tagum.sales@5s.gateway.local', 'MITSUBISHI TAGUM', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(275, 'MITSUBISHI PANABO 5S Utilities', 'mitsubishi-panabo.utilities@5s.gateway.local', 'MITSUBISHI PANABO', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(276, 'MITSUBISHI PANABO 5S Service', 'mitsubishi-panabo.service@5s.gateway.local', 'MITSUBISHI PANABO', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(277, 'MITSUBISHI PANABO 5S Sales', 'mitsubishi-panabo.sales@5s.gateway.local', 'MITSUBISHI PANABO', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(278, 'GEELY SAN FRANCISCO 5S Utilities', 'geely-san-francisco.utilities@5s.gateway.local', 'GEELY SAN FRANCISCO', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(279, 'GEELY SAN FRANCISCO 5S Service', 'geely-san-francisco.service@5s.gateway.local', 'GEELY SAN FRANCISCO', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(280, 'GEELY SAN FRANCISCO 5S Sales', 'geely-san-francisco.sales@5s.gateway.local', 'GEELY SAN FRANCISCO', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(281, 'MITSUBISHI NEGROS 5S Utilities', 'mitsubishi-negros.utilities@5s.gateway.local', 'MITSUBISHI NEGROS', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(282, 'MITSUBISHI NEGROS 5S Service', 'mitsubishi-negros.service@5s.gateway.local', 'MITSUBISHI NEGROS', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(283, 'MITSUBISHI NEGROS 5S Sales', 'mitsubishi-negros.sales@5s.gateway.local', 'MITSUBISHI NEGROS', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(284, 'MITSUBISHI BACOLOD 5S Utilities', 'mitsubishi-bacolod.utilities@5s.gateway.local', 'MITSUBISHI BACOLOD', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(285, 'MITSUBISHI BACOLOD 5S Service', 'mitsubishi-bacolod.service@5s.gateway.local', 'MITSUBISHI BACOLOD', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(286, 'MITSUBISHI BACOLOD 5S Sales', 'mitsubishi-bacolod.sales@5s.gateway.local', 'MITSUBISHI BACOLOD', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(287, 'MITSUBISHI CAGAYAN DE ORO 5S Utilities', 'mitsubishi-cagayan-de-oro.utilities@5s.gateway.local', 'MITSUBISHI CAGAYAN DE ORO', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(288, 'MITSUBISHI CAGAYAN DE ORO 5S Service', 'mitsubishi-cagayan-de-oro.service@5s.gateway.local', 'MITSUBISHI CAGAYAN DE ORO', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(289, 'MITSUBISHI CAGAYAN DE ORO 5S Sales', 'mitsubishi-cagayan-de-oro.sales@5s.gateway.local', 'MITSUBISHI CAGAYAN DE ORO', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(290, 'HONDA BUTUAN 5S Utilities', 'honda-butuan.utilities@5s.gateway.local', 'HONDA BUTUAN', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(291, 'HONDA BUTUAN 5S Service', 'honda-butuan.service@5s.gateway.local', 'HONDA BUTUAN', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(292, 'HONDA BUTUAN 5S Sales', 'honda-butuan.sales@5s.gateway.local', 'HONDA BUTUAN', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(293, 'KIA VALENCIA 5S Utilities', 'kia-valencia.utilities@5s.gateway.local', 'KIA VALENCIA', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(294, 'KIA VALENCIA 5S Service', 'kia-valencia.service@5s.gateway.local', 'KIA VALENCIA', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(295, 'KIA VALENCIA 5S Sales', 'kia-valencia.sales@5s.gateway.local', 'KIA VALENCIA', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(296, 'JAECO & OMODA ILIGIAN 5S Utilities', 'jaeco-omoda-iligian.utilities@5s.gateway.local', 'JAECO & OMODA ILIGIAN', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(297, 'JAECO & OMODA ILIGIAN 5S Service', 'jaeco-omoda-iligian.service@5s.gateway.local', 'JAECO & OMODA ILIGIAN', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(298, 'JAECO & OMODA ILIGIAN 5S Sales', 'jaeco-omoda-iligian.sales@5s.gateway.local', 'JAECO & OMODA ILIGIAN', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(299, 'HONDA DIPOLOG 5S Utilities', 'honda-dipolog.utilities@5s.gateway.local', 'HONDA DIPOLOG', '5S_UTILITIES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(300, 'HONDA DIPOLOG 5S Service', 'honda-dipolog.service@5s.gateway.local', 'HONDA DIPOLOG', '5S_SERVICE', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35'),
(301, 'HONDA DIPOLOG 5S Sales', 'honda-dipolog.sales@5s.gateway.local', 'HONDA DIPOLOG', '5S_SALES', NULL, 'active', '2026-09-06 22:57:35', NULL, '$2y$12$wOfk7VtJLa7G8w6KjRq4qemM8fmObh3yoM2b2hzhkIdWyS2usjgRO', NULL, '2026-09-06 22:57:35', '2026-09-06 22:57:35');

--
-- Indexes for dumped tables
--

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
  ADD KEY `checklist_submission_user_lookup` (`user_id`,`checklist_template_id`,`audit_date`,`scope_key`,`status`);

--
-- Indexes for table `checklist_templates`
--
ALTER TABLE `checklist_templates`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `checklist_templates_slug_unique` (`slug`),
  ADD KEY `checklist_templates_is_active_index` (`is_active`);

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
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `checklist_items`
--
ALTER TABLE `checklist_items`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=558;

--
-- AUTO_INCREMENT for table `checklist_responses`
--
ALTER TABLE `checklist_responses`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `checklist_sections`
--
ALTER TABLE `checklist_sections`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=106;

--
-- AUTO_INCREMENT for table `checklist_submissions`
--
ALTER TABLE `checklist_submissions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `checklist_templates`
--
ALTER TABLE `checklist_templates`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jobs`
--
ALTER TABLE `jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- AUTO_INCREMENT for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=151;

--
-- AUTO_INCREMENT for table `reports`
--
ALTER TABLE `reports`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=302;

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
  ADD CONSTRAINT `checklist_submissions_checklist_template_id_foreign` FOREIGN KEY (`checklist_template_id`) REFERENCES `checklist_templates` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `checklist_submissions_submitted_by_user_id_foreign` FOREIGN KEY (`submitted_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `checklist_submissions_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `reports`
--
ALTER TABLE `reports`
  ADD CONSTRAINT `reports_checklist_submission_id_foreign` FOREIGN KEY (`checklist_submission_id`) REFERENCES `checklist_submissions` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `reports_checklist_template_id_foreign` FOREIGN KEY (`checklist_template_id`) REFERENCES `checklist_templates` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `reports_generated_by_user_id_foreign` FOREIGN KEY (`generated_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;
-- Keep the hourly Restroom instruction aligned with the Yes / No / N/A UI.
UPDATE `checklist_templates`
SET `settings` = JSON_SET(
  `settings`,
  '$.instructions',
  'Mark each hourly inspection as Yes or No, and add a row remark when needed.'
)
WHERE `slug` = 'restroom';

COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
