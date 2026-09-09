-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Aug 29, 2026 at 06:57 AM
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
('laravel-cache-6cb5bb9b67d5af5e7f80c02dc185aac943ccb0d3', 'i:1;', 1787975038),
('laravel-cache-6cb5bb9b67d5af5e7f80c02dc185aac943ccb0d3:timer', 'i:1787975038;', 1787975038),
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
(57, 2, 10, 'dos-item-13', 'Is there dedicated appointment bay and walk in receiving bays?', 0, '{\"number\":13,\"level\":\"Standard\",\"subject\":\"Dedicated Appointment and Walk-In Bay\",\"pic\":\"JOB CONTROLLER\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(58, 2, 10, 'dos-item-42', 'Are there no parts on the floor without bin locator? And/ or does each locator stores only one kind of parts?', 1, '{\"number\":42,\"level\":\"Standard\",\"subject\":\"Parts 5S\",\"pic\":\"PART SUPERVISOR\\/ANALYS\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(59, 2, 10, 'dos-item-45', 'Workbays are marked with demarcation lines, and identified with numbers; Cleanliness inside the workshop area is maintained (no lingering oil and water spills, and scattered items)', 2, '{\"number\":45,\"level\":\"Basic\",\"subject\":\"Workshop Maintenance\",\"pic\":\"ASM\",\"escalation\":\"PM \\/ DND\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(60, 2, 10, 'dos-item-47', '> Items are properly sorted and stored\n> Cleanliness inside the tool room is maintained\n> Special service tools are wall-mounted\n> There is an updated borrower\'s logbook', 3, '{\"number\":47,\"level\":\"Standard\",\"subject\":\"Tools Storage Room\",\"pic\":\"TOOL KEEPER\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(61, 2, 10, 'dos-item-48', '> The components repair room is used for its intended purpose\n> The required tools are present and properly managed\n> Has adequate illumination and ventilation', 4, '{\"number\":48,\"level\":\"Standard\",\"subject\":\"Components Repair Room\",\"pic\":\"ASM\",\"escalation\":\"PM \\/ DND\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(62, 2, 10, 'dos-item-49', '> Storage area is enclosed  \n> Drums are placed on top of elevated platforms  \n> No oil spills on the floor and with regular schedule disposal pullout', 5, '{\"number\":49,\"level\":\"Standard\",\"subject\":\"Waste Oil Storage\",\"pic\":\"ASM\",\"escalation\":\"COMPLIANCE ADMINISTRATOR\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(63, 2, 10, 'dos-item-50', '> Storage area is enclosed  \n> Contains storage racks and bins; replaced parts must be secured with box \n> Follows the standard 30-60-90 days sorting scheme \n> Should have a proper tagging and inventory list and monitoring', 6, '{\"number\":50,\"level\":\"Standard\",\"subject\":\"Warranty Parts Storage\",\"pic\":\"WARRANTY OFFICER\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(64, 2, 10, 'dos-item-51', 'Placed at the back part of the service shop and properly maintained', 7, '{\"number\":51,\"level\":\"Standard\",\"subject\":\"Scrapped Parts Storage\",\"pic\":\"ASM\",\"escalation\":\"COMPLIANCE ADMINISTRATOR\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(65, 2, 10, 'dos-item-52', 'Must be in an enclosed area with enough racks and bins for proper sorting', 8, '{\"number\":52,\"level\":\"Standard\",\"subject\":\"Dismantled Parts Storage\",\"pic\":\"ASM\",\"escalation\":\"COMPLIANCE ADMINISTRATOR\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(66, 2, 10, 'dos-item-54', 'See sheet: \"Subform\"', 9, '{\"number\":54,\"level\":\"Standard\",\"subject\":\"Employee Facilities\",\"pic\":\"ASM\",\"escalation\":\"PM \\/ DND\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(67, 2, 10, 'dos-item-55', 'See sheet: \"Subform\"', 10, '{\"number\":55,\"level\":\"Standard\",\"subject\":\"Meeting Room\",\"pic\":\"ASM\",\"escalation\":\"PM \\/ DND\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(68, 2, 10, 'dos-item-74', '5S Checklists are accomplished by PICs.', 11, '{\"number\":74,\"level\":\"Beyond\",\"subject\":\"5S\",\"pic\":\"ASM\",\"escalation\":\"COMPLIANCE ADMINISTRATOR\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(69, 2, 11, 'dos-item-10', 'There should be no pending bookings more than 24hrs after it was created (Otoleap)', 0, '{\"number\":10,\"level\":\"Basic\",\"subject\":\"Otoleap Booking Management\",\"pic\":\"SERVICE CRO\\/RECEPTIONIST\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(70, 2, 11, 'dos-item-17', 'Dedicated digital tablet for walk-around inspection is available. (1 Tablet : 1 SA) (Updated to minimum Google Android ver. 9; Apple iOS 10)', 1, '{\"number\":17,\"level\":\"Standard\",\"subject\":\"CRM Requirements\",\"pic\":\"ASM\",\"escalation\":\"AS BRAND HEAD\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(71, 2, 11, 'dos-item-29', 'Stable internet connection at the ff. area: \n(Bandwidth> 1Mbps and Latency<150ms) via Ookla speedtest\n1. Service Reception\n2. Receiving Bay', 2, '{\"number\":29,\"level\":\"Standard\",\"subject\":\"CRM Requirements\",\"pic\":\"BOM\",\"escalation\":\"IT\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(72, 2, 11, 'dos-item-56', 'Has updated access account on Service Information Portal', 3, '{\"number\":56,\"level\":\"Standard\",\"subject\":\"Service Documents\",\"pic\":\"ASM\",\"escalation\":\"MMPC CS TEAM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(73, 2, 12, 'dos-item-1', 'Check accuracy of manpower list from latest submission to Network Training Department (NTD).', 0, '{\"number\":1,\"level\":\"Standard\",\"subject\":\"Manpower Count\",\"pic\":\"SERVICE ADMIN\",\"escalation\":\"MMPC TRAINING PIC\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(74, 2, 12, 'dos-item-2', 'Dealer has at least 1 designated Aftersales Training person in charge.', 1, '{\"number\":2,\"level\":\"Standard\",\"subject\":\"Training Requirements\",\"pic\":\"ASM\",\"escalation\":\"MMPC TRAINING PIC\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(75, 2, 12, 'dos-item-3', 'All Customer Relations Department personnel are accredited following these timelines:\n*Level 1: within 30 days upon hiring\n*Level 2: within 3-6 months upon hiring\n*Level 3: within 1 year upon hiring', 2, '{\"number\":3,\"level\":\"Standard\",\"subject\":\"Training Requirements\",\"pic\":\"SERVICE ADMIN\",\"escalation\":\"MMPC TRAINING PIC\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(76, 2, 12, 'dos-item-14', 'Customer Relations Department (CRO, Receptionist, Telemarketer) personnel count must be based on the standard requirements.', 3, '{\"number\":14,\"level\":\"Standard\",\"subject\":\"Customer Relations Department\",\"pic\":\"ASM\",\"escalation\":\"MMPC TRAINING PIC\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(77, 2, 12, 'dos-item-57', 'All service personnel should be neatly dressed and Technicians must wear the latest MMPC-prescribed uniform.', 4, '{\"number\":57,\"level\":\"Standard\",\"subject\":\"Employees\' Uniform\",\"pic\":\"ASM\",\"escalation\":\"AS BRAND HEAD\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(78, 2, 13, 'dos-item-4', 'Does Telemarketer follow standard appointment balance for the day?', 0, '{\"number\":4,\"level\":\"Standard\",\"subject\":\"Offering of date and time\",\"pic\":\"ASM\",\"escalation\":\"AS BRAND HEAD\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(79, 2, 13, 'dos-item-5', 'Does Telemarketer record reason of rejection in case customer do not accept PMS appointment.', 1, '{\"number\":5,\"level\":\"Standard\",\"subject\":\"Reason of Rejection\",\"pic\":\"ASM\",\"escalation\":\"AS BRAND HEAD\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(80, 2, 13, 'dos-item-6', 'The CRO and Service Advisor should have a printed QR Code of contact number or hotline number visible to the customers.', 2, '{\"number\":6,\"level\":\"Standard\",\"subject\":\"Contact Details\",\"pic\":\"BOM\",\"escalation\":\"CE CENTRAL\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(81, 2, 14, 'dos-item-7', 'Does Telemarketer perform block time for walk-in customers?', 0, '{\"number\":7,\"level\":\"Standard\",\"subject\":\"Blocking of SA for Walk-In customer\",\"pic\":\"ASM\",\"escalation\":\"AS BRAND HEAD\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(82, 2, 14, 'dos-item-8', 'Does Telemarketer assign and inform each SA their assigned customer with their appointment time?', 1, '{\"number\":8,\"level\":\"Basic\",\"subject\":\"SA assignment\",\"pic\":\"ASM\",\"escalation\":\"AS BRAND HEAD\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(83, 2, 14, 'dos-item-9', 'Does Telemarketer make appointment reconfirmation call the day before?', 2, '{\"number\":9,\"level\":\"Standard\",\"subject\":\"Reconfirmation Call\",\"pic\":\"ASM\",\"escalation\":\"AS BRAND HEAD\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(84, 2, 14, 'dos-item-11', 'Is the Appointment Welcome board visible to customer?\n\nWith complete details as follows:\n1) today\'s date\n2) time slot\n3) name or plate number of customer\n4) SA name\n5) purpose of visit: e.g. 10K PMS, GR, etc.\n6) Arrival Status (Green - On time, Yellow - Late, Red - No Show)', 3, '{\"number\":11,\"level\":\"Standard\",\"subject\":\"Appointment Welcome Board\",\"pic\":\"SERVICE CRO\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(85, 2, 14, 'dos-item-12', 'Telemarketer shares the list of customers booked 1 day before the day of appointment to all concerned after-sales personnel (Security Guard, Job Controller, Leadman, Parts Warehouse Staff, Service Advisor, Service Manager, Sales Executive - optional)', 4, '{\"number\":12,\"level\":\"Basic\",\"subject\":\"Appointment\",\"pic\":\"ASM\",\"escalation\":\"AS BRAND HEAD\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(86, 2, 15, 'dos-item-15', 'Is there a queuing system in the reception area?', 0, '{\"number\":15,\"level\":\"Basic\",\"subject\":\"Queuing system\",\"pic\":\"SECURITY GUARD\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(87, 2, 15, 'dos-item-16', 'Is there a Receptionist who will accommodate customer during peak hours or if all SA\'s are still accomodating the customers?', 1, '{\"number\":16,\"level\":\"Standard\",\"subject\":\"Peak hours\",\"pic\":\"SERVICE CRO\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(88, 2, 15, 'dos-item-18', 'Does SA always inspect vehicle for any car body damage using standard walk around inspection checklist?', 2, '{\"number\":18,\"level\":\"Standard\",\"subject\":\"Walk Around Inspection\",\"pic\":\"SERVICE ADVISOR\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(89, 2, 15, 'dos-item-19', 'Does SA always put the following protective covers before transfering the vehicle to workshop?\n\n1. Steering wheel cover\n2. Seat Cover\n3. Shifting knob cover\n4. Handbrake cover\n5. Floormats', 3, '{\"number\":19,\"level\":\"Standard\",\"subject\":\"Protective Covers\",\"pic\":\"SERVICE ADVISOR\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(90, 2, 15, 'dos-item-20', 'Do all vehicles in the workshop have a vehicle status tag with promised date/ time?', 4, '{\"number\":20,\"level\":\"Standard\",\"subject\":\"Vehicle Status Tag\",\"pic\":\"SERVICE ADVISOR\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(91, 2, 15, 'dos-item-21', 'Is there Direct Reception Process done inside the workshop?', 5, '{\"number\":21,\"level\":\"Beyond\",\"subject\":\"Direct Reption\",\"pic\":\"SERVICE ADVISOR\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(92, 2, 15, 'dos-item-22', 'Workshop entrance/exit is clear of obstructions at all times and not used as parking slots', 6, '{\"number\":22,\"level\":\"Basic\",\"subject\":\"Workshop Driveway\",\"pic\":\"SECURITY GUARD\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(93, 2, 15, 'dos-item-23', 'See sheet: \"Subform\"', 7, '{\"number\":23,\"level\":\"Basic\",\"subject\":\"Service Reception Area\",\"pic\":\"BOM\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(94, 2, 16, 'dos-item-24', 'Does SA provide the customer a promised time of delivery by checking availability of technician through job controller/ Job Progress Monitoring file?', 0, '{\"number\":24,\"level\":\"Standard\",\"subject\":\"Promised Time\",\"pic\":\"SERVICE ADVISOR\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(95, 2, 16, 'dos-item-25', 'On the Repair Order, is cost estimate always attached?', 1, '{\"number\":25,\"level\":\"Standard\",\"subject\":\"Cost Estimate\",\"pic\":\"SERVICE ADVISOR\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(96, 2, 16, 'dos-item-26', 'Does SA have an individual note with promised time of all received customers?', 2, '{\"number\":26,\"level\":\"Standard\",\"subject\":\"SA Individual Note\",\"pic\":\"SERVICE ADVISOR\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(97, 2, 17, 'dos-item-27', '> See sheet: \"Subform\"', 0, '{\"number\":27,\"level\":\"Basic\",\"subject\":\"Customers\' Lounge\",\"pic\":\"BOM\",\"escalation\":\"COMPLIANCE ADMINISTRATOR\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(98, 2, 17, 'dos-item-28', 'Service Personnel/Service Advisor/ CRO/ SA on Duty verbally offers all available lounge amenities to customers (WiFi access/ password, Sofa, TV, CR)\n1) complimentary drink and snack \n2) WIFI, Password\n3) Mobile charging station\n4) How to read YANA vehicle status update\n5) Televison/ reading materials\n6) Comfort Room', 1, '{\"number\":28,\"level\":\"Standard\",\"subject\":\"Offering of amenities\",\"pic\":\"BOM\",\"escalation\":\"IT\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(99, 2, 17, 'dos-item-30', 'Dedicated Vehicle Status Monitor must be visibly displayed and reflects the latest vehicle status update at the Customer Lounge', 2, '{\"number\":30,\"level\":\"Standard\",\"subject\":\"CRM Requirements\",\"pic\":\"BOM\",\"escalation\":\"IT\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(100, 2, 17, 'dos-item-31', 'Does the SA offer shuttle service transportation or assistance (e.g. grab, taxi etc?)?', 3, '{\"number\":31,\"level\":\"Beyond\",\"subject\":\"Shuttle Service Assistance\",\"pic\":\"SERVICE ADVISOR\",\"escalation\":\"BOM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(101, 2, 17, 'dos-item-32', 'Did salesperson make contact with customer who was waiting at the lounge?\n150K > offer new vehicle', 4, '{\"number\":32,\"level\":\"Beyond\",\"subject\":\"Assigned Sales Executive\",\"pic\":\"SALES MANAGER\",\"escalation\":\"BOM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(102, 2, 17, 'dos-item-33', 'Does SA inform progress of vehicle to the waiting customer 1 hr after issuance of RO?', 5, '{\"number\":33,\"level\":\"Standard\",\"subject\":\"Service Advisor\",\"pic\":\"SERVICE ADVISOR\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(103, 2, 17, 'dos-item-34', 'Customer Information Sheet (CIS) and DPA Form is being used by Receptionist to gather customer contact information as needed.', 6, '{\"number\":34,\"level\":\"Standard\",\"subject\":\"Customer Information Sheet\",\"pic\":\"SERVICE CRO\",\"escalation\":\"BOM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(104, 2, 18, 'dos-item-35', 'Did the Job Controller conduct pre-planning  based on the appointment sheet for the day and regularly monitors actual progress of units in the shop?', 0, '{\"number\":35,\"level\":\"Standard\",\"subject\":\"Job Progress Monitoring\",\"pic\":\"JOB CONTROLLER\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(105, 2, 18, 'dos-item-36', 'Is car wash control board available, properly filled out and based on the standard template?', 1, '{\"number\":36,\"level\":\"Standard\",\"subject\":\"Carwash Control Board\",\"pic\":\"CAR WASHER\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(106, 2, 18, 'dos-item-37', 'Did Job Controller make car wash plan and communicate with carwasher the promised time of received customers?', 2, '{\"number\":37,\"level\":\"Standard\",\"subject\":\"Job Progress Monitoring\",\"pic\":\"JOB CONTROLLER\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(107, 2, 18, 'dos-item-38', 'Do technicians clock in as soon as RO is handed over and clock out as soon as job is completed (excluding QC)?', 3, '{\"number\":38,\"level\":\"Standard\",\"subject\":\"Technicians Clock-In\",\"pic\":\"JOB CONTROLLER\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(108, 2, 18, 'dos-item-39', 'Carryover units are properly monitored and managed (with monitoring) by Job Controller.', 4, '{\"number\":39,\"level\":\"Standard\",\"subject\":\"Repair\",\"pic\":\"JOB CONTROLLER\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(109, 2, 19, 'dos-item-40', 'Does Parts Staff pre-pick parts for appointment and walk-in customers?', 0, '{\"number\":40,\"level\":\"Standard\",\"subject\":\"Pre-Picking\",\"pic\":\"PART SUPERVISOR\\/ANALYS\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(110, 2, 19, 'dos-item-41', 'Is there any monitoring to ensure that the Leadman/ technician who is waiting for emergency parts is contacted immediately after delivery/receiving of parts?', 1, '{\"number\":41,\"level\":\"Standard\",\"subject\":\"Emergency Parts\",\"pic\":\"PART SUPERVISOR\\/ANALYS\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(111, 2, 20, 'dos-item-43', 'Does Leadman indicate or instruct target job completion time to the assigned technician?', 0, '{\"number\":43,\"level\":\"Standard\",\"subject\":\"Vehicle Status Tag\",\"pic\":\"LEADMAN\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(112, 2, 20, 'dos-item-44', 'In case of unapproved job by the customer, does SA record as \"future work reminder\" in service history of DMS?', 1, '{\"number\":44,\"level\":\"Standard\",\"subject\":\"Unapproved Job\",\"pic\":\"SERVICE ADVISOR\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(113, 2, 20, 'dos-item-46', 'Service Vehicle:\nAll service vehicle has exterior covers installed (bumper and fender)', 2, '{\"number\":46,\"level\":\"Standard\",\"subject\":\"Repair\",\"pic\":\"SERVICE ADVISOR\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(114, 2, 20, 'dos-item-53', 'See sheet: \"Subform\"', 3, '{\"number\":53,\"level\":\"Standard\",\"subject\":\"Mitsubishi Quick Service\",\"pic\":\"SERVICE ADVISOR\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(115, 2, 21, 'dos-item-58', 'Does vehicle status tag indicate proper status inside the shop? (e.g. if ongoing repair, or for car wash, etc.)', 0, '{\"number\":58,\"level\":\"Standard\",\"subject\":\"Vehicle Status Tag\",\"pic\":\"JOB CONTROLLER\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(116, 2, 21, 'dos-item-59', 'Escorted the customer to his/her vehicle.', 1, '{\"number\":59,\"level\":\"Standard\",\"subject\":\"Delivery\",\"pic\":\"SERVICE ADVISOR\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(117, 2, 21, 'dos-item-60', 'Did SA inform waiting customer and non waiting customer when car is ready for return?', 2, '{\"number\":60,\"level\":\"Standard\",\"subject\":\"Car Return\",\"pic\":\"SERVICE ADVISOR\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(118, 2, 21, 'dos-item-61', 'Documentation:\nProper utilization of all service documents (Rationalized Checksheet, Repair Order, Service Invoice)', 3, '{\"number\":61,\"level\":\"Standard\",\"subject\":\"Repair\",\"pic\":\"BILLING\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(119, 2, 22, 'dos-item-62', 'Does SA refer to the initial agreed RO and quoted price?', 0, '{\"number\":62,\"level\":\"Standard\",\"subject\":\"Actual Cost\",\"pic\":\"SERVICE ADVISOR\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(120, 2, 22, 'dos-item-63', 'Does SA show replaced parts (if applicable) during delivery process?', 1, '{\"number\":63,\"level\":\"Standard\",\"subject\":\"Replaced Parts\",\"pic\":\"SERVICE ADVISOR\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(121, 2, 22, 'dos-item-64', 'Does Service Advisor remind the customer regarding QVOC?', 2, '{\"number\":64,\"level\":\"Standard\",\"subject\":\"QVOC Reminder\",\"pic\":\"ASM\",\"escalation\":\"BOM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(122, 2, 22, 'dos-item-65', 'Does SA remove the Protective Cover Sheet in the presence of Customer before vehicle is delivered back to the Customer?', 3, '{\"number\":65,\"level\":\"Standard\",\"subject\":\"Removal of Protective Cover\",\"pic\":\"SERVICE ADVISOR\",\"escalation\":\"ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(123, 2, 22, 'dos-item-66', 'Does SA mention about the follow up call and its purpose such as the following?\n > to give notice to the customer that follow up call will be made by CRO within 3 days\n > benefit of the follow up call for customer\n > preferable time to receive a call', 4, '{\"number\":66,\"level\":\"Standard\",\"subject\":\"Follow-Up Call\",\"pic\":\"SERVICE CRO\\/RECEPTIONIST\",\"escalation\":\"BOM | CE CENTRAL\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(124, 2, 23, 'dos-item-67', 'Does CRO conduct 3 days after service follow up calls?', 0, '{\"number\":67,\"level\":\"Standard\",\"subject\":\"Follow-Up Call\",\"pic\":\"SERVICE CRO\",\"escalation\":\"BOM | CE CENTRAL\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(125, 2, 23, 'dos-item-68', 'Does CRO categorize concerns based on follow up call result and collected QVOC responses? (i.e. concern on parking, attitude of staff, quality of work, price of RO etc.)', 1, '{\"number\":68,\"level\":\"Standard\",\"subject\":\"Complaint Monitoring Tracking Report\",\"pic\":\"SERVICE CRO\",\"escalation\":\"BOM | CE CENTRAL\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(126, 2, 23, 'dos-item-69', 'Does the Complaint Monitoring Tracking Report include open concern (concern that has no implemented action within 7 calendar days).', 2, '{\"number\":69,\"level\":\"Standard\",\"subject\":\"Complaint Monitoring Tracking Report\",\"pic\":\"SERVICE CRO\",\"escalation\":\"BOM | CE CENTRAL\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(127, 2, 24, 'dos-item-70', 'Is \"Weekly Meeting\" (MAM) organized at least once a week at the same time on the same day of week?', 0, '{\"number\":70,\"level\":\"Standard\",\"subject\":\"MAM\",\"pic\":\"BOM\",\"escalation\":\"COMPLIANCE ADMINISTRATOR | ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(128, 2, 24, 'dos-item-71', 'Is \"Daily Meeting\" (MOM) organized daily with workshop staff at the same time ?', 1, '{\"number\":71,\"level\":\"Standard\",\"subject\":\"MAM\",\"pic\":\"BOM\",\"escalation\":\"COMPLIANCE ADMINISTRATOR | ASM\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(129, 2, 24, 'dos-item-72', 'Is there any information board which displays actions or KPI derived from MAM?', 2, '{\"number\":72,\"level\":\"Standard\",\"subject\":\"MAM\",\"pic\":\"ASM\",\"escalation\":\"AS BRAND HEAD\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(130, 2, 24, 'dos-item-73', 'Is there any information board which displays key information, and suggestions from workshop staff derived from MOM?', 3, '{\"number\":73,\"level\":\"Standard\",\"subject\":\"MOM\",\"pic\":\"ASM\",\"escalation\":\"AS BRAND HEOD\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(131, 2, 24, 'dos-item-75', 'Are the following KPI being monitored and ready to be discussed in case its necessary during \"Weekly Meeting\"?: \n\nMAIN KPI:\n1) Actual SIU and target agreed with MMPC\n2) Actual first retention rate\n3) Actual P&A booking and target agreed with MMPC\n4) Stock month of fast moving parts\n5) Appointment ratio\n6) Dead stock ratio \n7) CSI\n\nTechnician Report:\n8) Efficiency (labor sold hr / actual worked hr)\n9) Utilization (actual worked hr / available hr)\n10) Productivity (efficiency x utilization)\n\nCRO/ Telemarketer:\n11) Reminder call coverage ratio (actual reminder call / target reminder call)\n12) Proactive call acceptance ratio (actual accepted appointment booking / called customer)\n13) Follow up call ratio\n14) Customer Complaint Tracking Discussion (Red alert, critical concerns)\n15) Appointment balance for a day (Morning = 80%, Afternoon = 20%)\n\nJob Controller: \n16) On time delivery and on time arrival ratio (from service time monitoring)\n\nOthers:\n17) Fix it right first time or repeat repair ratio (F1)\n18) Direct reception (optional)\n19) Focus item upselling (optional)', 4, '{\"number\":75,\"level\":\"Standard\",\"subject\":\"MAM\",\"pic\":\"ASM\",\"escalation\":\"AS BRAND HEAD\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(132, 3, 25, 'restroom-item-1', 'Are the restroom well maintained with sufficient lightning, good ventilation and free from any foul odor?', 0, '{\"number\":1,\"response_type\":\"time_slots\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(133, 3, 25, 'restroom-item-2', 'Are the bathroom mirror, floor, ceiling and wall s clean and free from stains and damage?', 1, '{\"number\":2,\"response_type\":\"time_slots\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(134, 3, 25, 'restroom-item-3', 'Are the sinks and faucets working properly with enough water supply?', 2, '{\"number\":3,\"response_type\":\"time_slots\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(135, 3, 25, 'restroom-item-4', 'Is liquid hand soap with a dispenser available?', 3, '{\"number\":4,\"response_type\":\"time_slots\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(136, 3, 25, 'restroom-item-5', 'Is a working hand dryer available in the washing area?', 4, '{\"number\":5,\"response_type\":\"time_slots\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(137, 3, 25, 'restroom-item-6', 'Are bathroom tissue rolls/toilet paper with holders available and consistently maintained in each cubicle?', 5, '{\"number\":6,\"response_type\":\"time_slots\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(138, 3, 25, 'restroom-item-7', 'Are the toilet bowls and urinals functioning properly?', 6, '{\"number\":7,\"response_type\":\"time_slots\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(139, 3, 25, 'restroom-item-8', 'Toilet bowl are clean and with functional bidet?', 7, '{\"number\":8,\"response_type\":\"time_slots\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(140, 3, 25, 'restroom-item-9', 'Are the trash bins available, clean, well-maintained, free from stains, and not overflowing?', 8, '{\"number\":9,\"response_type\":\"time_slots\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(141, 3, 25, 'restroom-item-10', 'Cleaning equipment are kept in order and unseen by the customers?', 9, '{\"number\":10,\"response_type\":\"time_slots\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(142, 3, 25, 'restroom-item-11', 'Orderliness of Restroom is checked every hour by the person-in-charge.', 10, '{\"number\":11,\"response_type\":\"time_slots\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21');

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
  `commitment_date` date DEFAULT NULL,
  `details` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`details`)),
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
(10, 2, 'coverage-1', 'Facilities', 0, NULL, 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(11, 2, 'coverage-2', 'Systems', 1, NULL, 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(12, 2, 'coverage-3', 'Manpower', 2, NULL, 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(13, 2, 'coverage-4', 'Pro-active Customer Contact', 3, NULL, 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(14, 2, 'coverage-5', 'Customer Appointment', 4, NULL, 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(15, 2, 'coverage-6', 'Personalized Customer Reception', 5, NULL, 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(16, 2, 'coverage-7', 'Menu Pricing / Commitment of Price and Time Delivery', 6, NULL, 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(17, 2, 'coverage-8', 'Customer Care and Communication', 7, NULL, 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(18, 2, 'coverage-9', 'Workshop Scheduling', 8, NULL, 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(19, 2, 'coverage-10', 'Advance Info to Parts Store', 9, NULL, 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(20, 2, 'coverage-11', 'Repair Order Processing and Quality of Work', 10, NULL, 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(21, 2, 'coverage-12', 'Repair Order Completion and Invoicing', 11, NULL, 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(22, 2, 'coverage-13', 'Customer Information and Car Return', 12, NULL, 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(23, 2, 'coverage-14', 'Customer After Service Contact', 13, NULL, 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(24, 2, 'coverage-15', 'Concern Prevention and Resolution', 14, NULL, 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(25, 3, 'restroom-hourly-inspection', 'Restroom Hourly Inspection', 0, NULL, 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21');

-- --------------------------------------------------------

--
-- Table structure for table `checklist_submissions`
--

CREATE TABLE `checklist_submissions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `checklist_template_id` bigint(20) UNSIGNED DEFAULT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `submitted_by_user_id` bigint(20) UNSIGNED DEFAULT NULL,
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
(1, 'gateway-5s', 'Gateway Sales and Service 5S Checklist', 'Daily pre-business-hours Sales and Service 5S audit.', 1, '{\"validation_mode\":\"yes_no_na\",\"response_options\":[\"yes\",\"no\",\"na\"],\"instructions\":\"Complete every item before business hours. A remark is required for NO and N\\/A.\",\"schedule\":{\"start\":\"08:00\",\"end\":\"08:30\"},\"source\":\"Gateway 5S Checklist.xlsx \\/ Combined Sales and Service\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(2, 'dealer-operations-standards', 'Dealer Operations Standards', 'FY2025 Aftersales Standards Compliance Audit Main Form.', 1, '{\"validation_mode\":\"dos\",\"response_options\":[\"yes\",\"no\",\"na\"],\"instructions\":\"Judge every standard. NO requires a finding, action plan, and commitment date; N\\/A requires a reason.\",\"scoring\":{\"basic_required_percentage\":100,\"standard_required_percentage\":80,\"overall_required_percentage\":80},\"source\":\"FY25 Aftersales Standards Compliance Audit Sheet_1.xlsx \\/ Main Form\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21'),
(3, 'restroom', 'Restroom Checklist', 'Hourly restroom condition and orderliness inspection.', 1, '{\"validation_mode\":\"time_slots\",\"instructions\":\"Mark each hourly inspection as Good (\\/) or Not Good (X), and add a row remark when needed.\",\"time_slots\":[{\"key\":\"08:00\",\"label\":\"8 AM\"},{\"key\":\"09:00\",\"label\":\"9 AM\"},{\"key\":\"10:00\",\"label\":\"10 AM\"},{\"key\":\"11:00\",\"label\":\"11 AM\"},{\"key\":\"13:00\",\"label\":\"1 PM\"},{\"key\":\"14:00\",\"label\":\"2 PM\"},{\"key\":\"15:00\",\"label\":\"3 PM\"},{\"key\":\"16:00\",\"label\":\"4 PM\"},{\"key\":\"17:00\",\"label\":\"5 PM\"}],\"legend\":{\"good\":\"\\/\",\"not_good\":\"X\"},\"remark_per_item\":true,\"source\":\"Gateway 5S Checklist.xlsx \\/ Restroom Checklist-1\"}', 1, '2026-08-21 23:21:21', '2026-08-21 23:21:21');

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
(14, '2026_08_28_000200_normalize_compliance_administrator_role', 6);

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
(1, 'App\\Models\\User', 7, 'expo-web', '94d68db72e1d9549c1d25f495af719d6989d7ed38aa0b8ff693271d91be66070', '[\"*\"]', NULL, NULL, '2026-08-11 23:47:05', '2026-08-11 23:47:05'),
(2, 'App\\Models\\User', 5, 'expo-web', 'dd00f317a66ec56a5a8869ba442ea9ed9d0b4aa5f84d132305e5e99fd18d8704', '[\"*\"]', NULL, NULL, '2026-08-11 23:47:23', '2026-08-11 23:47:23'),
(3, 'App\\Models\\User', 7, 'expo-web', 'c8a4e5af4ab75adc88568a6c9713dc3c5d0a93f0f5e0ede27e83c00a5379f9aa', '[\"*\"]', NULL, NULL, '2026-08-12 00:52:33', '2026-08-12 00:52:33'),
(4, 'App\\Models\\User', 7, 'expo-web', '8188e64ddd8f9c1875dcca48b7977a11de4da16a3f583ef443e27d6d5c0dcd1b', '[\"*\"]', NULL, NULL, '2026-08-13 17:37:10', '2026-08-13 17:37:10'),
(5, 'App\\Models\\User', 7, 'expo-web', 'b0b0fcb64ed4cedc0295447471a2aea7bb9d09a4115e3908e19018605504a164', '[\"*\"]', NULL, NULL, '2026-08-13 17:59:44', '2026-08-13 17:59:44'),
(6, 'App\\Models\\User', 7, 'expo-mobile', 'eb00c94ffaee8e6ed5c47cf70d3be59224b9480ae9666aaeb271667fec1eb114', '[\"*\"]', NULL, NULL, '2026-08-13 18:48:33', '2026-08-13 18:48:33'),
(7, 'App\\Models\\User', 7, 'expo-mobile', '60449533681011dc4907c84df2585def54d8e1c3fcd8e5f73a0f818aeb66a462', '[\"*\"]', NULL, NULL, '2026-08-13 19:08:05', '2026-08-13 19:08:05'),
(8, 'App\\Models\\User', 7, 'expo-mobile', 'b543649fe021f15c061e6f95d5d05cd877518b5fcca7fd5c99716d2c2f8639ef', '[\"*\"]', NULL, NULL, '2026-08-13 19:14:32', '2026-08-13 19:14:32'),
(9, 'App\\Models\\User', 7, 'expo-mobile', '1e5204b51688e3aae52bcd6179fc73c8ab803bcb275dae634d85f59150f9a3a2', '[\"*\"]', NULL, NULL, '2026-08-13 19:14:50', '2026-08-13 19:14:50'),
(10, 'App\\Models\\User', 7, 'expo-mobile', 'fb8a177c30699dfbe46c22da4a8225a53d59b73bfb87cf301eadde1fdab4b14b', '[\"*\"]', NULL, NULL, '2026-08-13 19:17:42', '2026-08-13 19:17:42'),
(11, 'App\\Models\\User', 7, 'expo-mobile', 'f10ce2b517c464471517de3d7d5ef7c19492c6b778334fbf8506d4b931f9adca', '[\"*\"]', NULL, NULL, '2026-08-13 19:27:57', '2026-08-13 19:27:57'),
(12, 'App\\Models\\User', 7, 'expo-web', '60a8a9e909f6f60bea69ba41a84bbc7b430ad73a9fcc320b54eadec0e55a8745', '[\"*\"]', NULL, NULL, '2026-08-13 19:28:24', '2026-08-13 19:28:24'),
(13, 'App\\Models\\User', 5, 'expo-web', 'a2eea323e951a455cb5d54463b3fb9ca353531f202657ae32b279c95296f4890', '[\"*\"]', NULL, NULL, '2026-08-13 19:35:08', '2026-08-13 19:35:08'),
(14, 'App\\Models\\User', 7, 'expo-web', '02da22744874198ac1d10c1e1f26295e306103abb665d430ecb52cf8d37016ad', '[\"*\"]', NULL, NULL, '2026-08-13 21:11:42', '2026-08-13 21:11:42'),
(15, 'App\\Models\\User', 7, 'expo-web', '4d09083ae7a528222004b84162860599bbaeacb17615ed525501a0553e90fa59', '[\"*\"]', NULL, NULL, '2026-08-14 18:43:19', '2026-08-14 18:43:19'),
(16, 'App\\Models\\User', 7, 'expo-web', 'b15acfddf93499352284308458aa68e1f941498dfe14fe5cf33a757b063d6a3a', '[\"*\"]', NULL, NULL, '2026-08-14 18:45:04', '2026-08-14 18:45:04'),
(17, 'App\\Models\\User', 5, 'expo-web', 'e57d09318e0ec8fc9f0b11d1e78f63ae53b604689b004b40f15bd9d448a76b3d', '[\"*\"]', NULL, NULL, '2026-08-14 18:46:07', '2026-08-14 18:46:07'),
(18, 'App\\Models\\User', 7, 'expo-web', 'beaa3eb94ae5c855ecca3357f7326fe885d86ff318f3f4d970f47dc05781028f', '[\"*\"]', NULL, NULL, '2026-08-14 18:47:35', '2026-08-14 18:47:35'),
(19, 'App\\Models\\User', 7, 'expo-web', 'ff52161d8f4c206139367938c696c37d0dbacaa4b73f2b339057b53ea82b0030', '[\"*\"]', NULL, NULL, '2026-08-14 19:11:48', '2026-08-14 19:11:48'),
(20, 'App\\Models\\User', 7, 'expo-web', 'bb398816ee8886513d79daee555aad9ea4a39351656d58f1659b1bfcb02eaea1', '[\"*\"]', NULL, NULL, '2026-08-14 19:21:21', '2026-08-14 19:21:21'),
(21, 'App\\Models\\User', 7, 'expo-web', 'cc94fa6cdbdd77d87c59678e159edcfde40e21f118ef4cad3ab6ee802d0c17c1', '[\"*\"]', NULL, NULL, '2026-08-14 19:41:44', '2026-08-14 19:41:44'),
(22, 'App\\Models\\User', 5, 'expo-web', '45c8dd8d7cc65ea8af688ed712fe9cda3c6d2bae1a16607f97d6f2342a400b42', '[\"*\"]', NULL, NULL, '2026-08-14 21:21:40', '2026-08-14 21:21:40'),
(23, 'App\\Models\\User', 7, 'expo-web', 'ea2f5b15fc2b0c30404e530dfb38ac7ca508e4b41e9b8bee0767fa8f54234f7e', '[\"*\"]', NULL, NULL, '2026-08-14 21:22:57', '2026-08-14 21:22:57'),
(24, 'App\\Models\\User', 7, 'expo-web', 'c81f4da71cc77bd60acb736e002d0954b97f5adbd7fc88fdc639d314cd1f87e6', '[\"*\"]', NULL, NULL, '2026-08-15 00:41:39', '2026-08-15 00:41:39'),
(25, 'App\\Models\\User', 7, 'expo-web', 'e48aba70615750748a8382378fa7e05c11badaaa4197c05782d3b5b2bf0a638a', '[\"*\"]', NULL, NULL, '2026-08-16 18:13:22', '2026-08-16 18:13:22'),
(26, 'App\\Models\\User', 7, 'expo-web', 'ab7436d95e42e022823bd650381e216b4ebab5e41d191267a0fd4afacc417339', '[\"*\"]', NULL, NULL, '2026-08-16 19:45:48', '2026-08-16 19:45:48'),
(27, 'App\\Models\\User', 7, 'expo-web', 'afcc7f60ec9247eb2b536be706c491701947bdd8d74cc0bcd7bd72779678c278', '[\"*\"]', NULL, NULL, '2026-08-16 21:24:56', '2026-08-16 21:24:56'),
(28, 'App\\Models\\User', 7, 'expo-web', '564f95f77423a81d835cfcb66a01e67251fbd1301bd1b4c8a84ff07911863b73', '[\"*\"]', NULL, NULL, '2026-08-16 21:50:28', '2026-08-16 21:50:28'),
(29, 'App\\Models\\User', 7, 'expo-web', '725483dad71382da75cd6ee3f553bee9fab7f6a5fc994fcaafebc172995b418e', '[\"*\"]', NULL, NULL, '2026-08-16 21:58:20', '2026-08-16 21:58:20'),
(30, 'App\\Models\\User', 7, 'expo-web', 'd1dd8935bf4633b272255fcb1c1cc14c0871dc611f284f0d33138c5a42a63f51', '[\"*\"]', NULL, NULL, '2026-08-17 16:26:10', '2026-08-17 16:26:10'),
(31, 'App\\Models\\User', 7, 'expo-web', '092aa4e2dc16798b3c2831d4fe5f256ca1f2e3dd0a4ac6935f8599b6fab6e6a2', '[\"*\"]', NULL, NULL, '2026-08-17 16:56:15', '2026-08-17 16:56:15'),
(32, 'App\\Models\\User', 7, 'expo-web', '147e7c6def04aa90e067fba3a8717b2336c09626854c209a4e01ef30dbdcf466', '[\"*\"]', NULL, NULL, '2026-08-17 17:03:33', '2026-08-17 17:03:33'),
(33, 'App\\Models\\User', 7, 'expo-web', '74d04da7860406fb8988a97b2b78dc8eeec216295d7bfd761ef8384d0261a573', '[\"*\"]', NULL, NULL, '2026-08-17 17:04:05', '2026-08-17 17:04:05'),
(34, 'App\\Models\\User', 7, 'expo-web', 'a2b17fc52e0568053076e14f57b90b3f17ca6a268eda986c0d9043d08c5ee9d1', '[\"*\"]', NULL, NULL, '2026-08-17 17:14:11', '2026-08-17 17:14:11'),
(35, 'App\\Models\\User', 7, 'expo-web', 'bcdd00b66eb923851b21df2d9b006cfa635dfbc7e43349d149e6bd410206a621', '[\"*\"]', NULL, NULL, '2026-08-17 17:26:08', '2026-08-17 17:26:08'),
(36, 'App\\Models\\User', 7, 'expo-web', '8a576a155836479e6d898f2b49c1bdb18854a9e4feeea1840b2c3c3d379d89d5', '[\"*\"]', NULL, NULL, '2026-08-17 17:36:18', '2026-08-17 17:36:18'),
(37, 'App\\Models\\User', 7, 'expo-web', 'bea59c29fc232eed0988227e508d15807581aa2c2d3e45c4cb3d71ac973cb2bd', '[\"*\"]', NULL, NULL, '2026-08-17 19:46:41', '2026-08-17 19:46:41'),
(38, 'App\\Models\\User', 7, 'expo-mobile', 'e5e2aefe0c7149af3a7cdfa3f5fce05159981dd1980563602f9f3bd73b9bf7dd', '[\"*\"]', NULL, NULL, '2026-08-17 22:14:47', '2026-08-17 22:14:47'),
(39, 'App\\Models\\User', 7, 'expo-mobile', '8d4dc8dad392bed30dc79e07360b99227e1ffe9414999f242e436e0c84b51ff6', '[\"*\"]', NULL, NULL, '2026-08-17 22:20:27', '2026-08-17 22:20:27'),
(40, 'App\\Models\\User', 7, 'expo-mobile', '68b96983860e7c60e1c1987eed962e98c59e4c62e88b1cb895f8ad64edf05d23', '[\"*\"]', NULL, NULL, '2026-08-17 22:25:35', '2026-08-17 22:25:35'),
(41, 'App\\Models\\User', 7, 'expo-mobile', '1c9e66f4af97a8b745ed4f2c2a89c4c4ed8a752e4f3303c2da278460848931db', '[\"*\"]', NULL, NULL, '2026-08-17 22:30:30', '2026-08-17 22:30:30'),
(42, 'App\\Models\\User', 7, 'expo-mobile', 'd043ea4462876a3e59d978ab083cab458d46dca02893b9f6d8a8ad945cc2d6a8', '[\"*\"]', NULL, NULL, '2026-08-17 22:38:23', '2026-08-17 22:38:23'),
(43, 'App\\Models\\User', 7, 'expo-web', 'a93416288a3f34c473dc3e23a61827b66cba090e44cbe5a6b1bf108ee41386ba', '[\"*\"]', NULL, NULL, '2026-08-20 18:28:23', '2026-08-20 18:28:23'),
(44, 'App\\Models\\User', 7, 'expo-mobile', '98fd8665281442cc4d5c887922ed9d34745dd0b125cd591d5caa295308d9f445', '[\"*\"]', NULL, NULL, '2026-08-20 18:49:38', '2026-08-20 18:49:38'),
(45, 'App\\Models\\User', 7, 'expo-mobile', '96a42c8010612265f5cd9868be5e0ecb816f285ad04caaad4845413116c297d3', '[\"*\"]', NULL, NULL, '2026-08-28 16:54:11', '2026-08-28 16:54:11'),
(46, 'App\\Models\\User', 7, 'expo-web', '000e85e4452818e42c998f62a85da84e1546d7f6e4636faeff24d4d55657819c', '[\"*\"]', NULL, NULL, '2026-08-28 17:16:26', '2026-08-28 17:16:26'),
(47, 'App\\Models\\User', 7, 'expo-mobile', 'c6efffa12870fc7c34b4422b0a135a72700dae36c19862364f5f936e151b3c5f', '[\"*\"]', NULL, NULL, '2026-08-28 17:50:36', '2026-08-28 17:50:36'),
(48, 'App\\Models\\User', 7, 'expo-mobile', '870da263aaa9fedb1515c9fb334e155ab6efa1f4d7e1fd9950d6317186b26f87', '[\"*\"]', NULL, NULL, '2026-08-28 18:56:00', '2026-08-28 18:56:00'),
(49, 'App\\Models\\User', 7, 'expo-mobile', '213757c40f9784923bf8b877667924d8536d0a2e401bbb1695f205ea89deb11b', '[\"*\"]', NULL, NULL, '2026-08-28 18:58:59', '2026-08-28 18:58:59'),
(50, 'App\\Models\\User', 7, 'expo-mobile', '72d4542f286d2e4155a528f17a30618c846770acfba280288ad553066c76a74e', '[\"*\"]', NULL, NULL, '2026-08-28 19:29:15', '2026-08-28 19:29:15'),
(51, 'App\\Models\\User', 7, 'expo-mobile', 'a8d5c28148f671bd546077439313c961fcb9eb42ad4aaec12940aa38161247f3', '[\"*\"]', NULL, NULL, '2026-08-28 19:42:58', '2026-08-28 19:42:58');

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

--
-- Dumping data for table `reports`
--

INSERT INTO `reports` (`id`, `checklist_submission_id`, `checklist_template_id`, `generated_by_user_id`, `type`, `title`, `status`, `filters`, `data_snapshot`, `generated_at`, `created_at`, `updated_at`) VALUES
(1, NULL, NULL, 5, 'csv_export', 'Checklist audit CSV export', 'ready', '[]', '{\"format\":\"csv\",\"filename\":\"gateway-audit-report-2026-08-22-075128.csv\",\"row_count\":0,\"submission_ids\":[],\"summary\":{\"score\":null,\"completion\":null,\"yes\":0,\"no\":0,\"na\":0,\"applicable\":0,\"answered\":0,\"total\":0,\"audit_count\":0,\"submitted_count\":0,\"draft_count\":0,\"findings_count\":0},\"access_scope\":{\"type\":\"all_branches\",\"branch\":null}}', '2026-08-21 23:51:28', '2026-08-21 23:51:28', '2026-08-21 23:51:28'),
(2, NULL, NULL, 5, 'csv_export', 'Checklist audit CSV export', 'ready', '[]', '{\"format\":\"csv\",\"filename\":\"gateway-audit-report-2026-08-29-022553.csv\",\"row_count\":0,\"submission_ids\":[],\"summary\":{\"score\":null,\"completion\":null,\"yes\":0,\"no\":0,\"na\":0,\"applicable\":0,\"answered\":0,\"total\":0,\"audit_count\":0,\"submitted_count\":0,\"draft_count\":0,\"findings_count\":0},\"access_scope\":{\"type\":\"all_branches\",\"branch\":null}}', '2026-08-28 18:25:53', '2026-08-28 18:25:53', '2026-08-28 18:25:53');

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
('BKxg1v2ZnOQRbgM2pjdTFM7FzQrogTE47o2TwrVW', 5, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36', 'YTo1OntzOjY6Il90b2tlbiI7czo0MDoiRzRYcE1oeVFTdWZuczNNZTF6Q0U3eFE0bEZ5MjlGakJodXpYeXhrVCI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MTMwOiJodHRwOi8vMTI3LjAuMC4xOjgwMDAvY2hlY2tsaXN0cy9kZWFsZXItb3BlcmF0aW9ucy1zdGFuZGFyZHMvcmVjb3JkP2JyYW5jaD1QYXNvbmclMjBUYW1vJmNoZWNrbGlzdF9kYXRlPTIwMjYtMDgtMjkmZGF0ZT0yMDI2LTA4LTI5IjtzOjU6InJvdXRlIjtzOjE1OiJjaGVja2xpc3RzLmxvYWQiO31zOjM6InVybCI7YTowOnt9czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6NTt9', 1787964746),
('dI2TSEqKmrC6NkEI68cfCOGIEF8fdwBy0lUhmBpV', 5, '10.0.20.100', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36', 'YTo1OntzOjY6Il90b2tlbiI7czo0MDoiaExGMGVmOEI4OWFYZWZ3NUZMU0RvRElSTjlGbThIcVNEQXRsSzRrTiI7czozOiJ1cmwiO2E6MDp7fXM6OToiX3ByZXZpb3VzIjthOjI6e3M6MzoidXJsIjtzOjMzOiJodHRwOi8vMTAuMC4yMC4xMDA6ODAwMC9kYXNoYm9hcmQiO3M6NToicm91dGUiO3M6OToiZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6NTt9', 1787975205);

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
  `account_status` varchar(20) NOT NULL DEFAULT 'active',
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `remember_token` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `branch`, `user_type`, `account_status`, `email_verified_at`, `password`, `remember_token`, `created_at`, `updated_at`) VALUES
(5, 'General Manager', 'gm@gateway.com', 'Pasong Tamo', 'ADMIN', 'active', NULL, '$2y$12$RrF5pTnu.LzSea2SpvEMp.ZqSQFdQaFekRdcG2fJe/mN7.0nGVG8e', 'B6CFsTzcKjslMJsvCxmYOD4gUv2Bixf3jj2b185SgHODag7mCXTLPA8swqVx', '2026-08-06 17:48:51', '2026-08-06 17:48:51'),
(7, 'Person In Charge', 'pic@gateway.com', 'Pasong Tamo', 'PIC', 'active', NULL, '$2y$12$93m0JSexxMjTPIuTISzfPuX.knkGX0Ru.brxMsfxcWD8EPZ6h0C92', NULL, '2026-08-11 23:21:27', '2026-08-11 23:21:27');

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
  ADD KEY `checklist_submissions_user_id_foreign` (`user_id`),
  ADD KEY `checklist_submissions_submitted_by_user_id_foreign` (`submitted_by_user_id`),
  ADD KEY `checklist_submission_lookup` (`checklist_template_id`,`audit_date`,`scope_key`,`status`),
  ADD KEY `checklist_submissions_status_submitted_at_index` (`status`,`submitted_at`);

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
  ADD UNIQUE KEY `users_email_unique` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `checklist_items`
--
ALTER TABLE `checklist_items`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=143;

--
-- AUTO_INCREMENT for table `checklist_responses`
--
ALTER TABLE `checklist_responses`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `checklist_sections`
--
ALTER TABLE `checklist_sections`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT for table `checklist_submissions`
--
ALTER TABLE `checklist_submissions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `checklist_templates`
--
ALTER TABLE `checklist_templates`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

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
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=52;

--
-- AUTO_INCREMENT for table `reports`
--
ALTER TABLE `reports`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

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
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
