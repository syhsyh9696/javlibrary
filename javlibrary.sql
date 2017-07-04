/*
Navicat MySQL Data Transfer

Source Server Version : 50718
Source Database       : javlibrary

Target Server Type    : MYSQL
Target Server Version : 50718
File Encoding         : 65001

Date: 2017-07-01 17:00:15
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for actor
-- ----------------------------
DROP TABLE IF EXISTS `actor`;
CREATE TABLE `actor` (
  `actor_id` int(11) NOT NULL AUTO_INCREMENT,
  `actor_name` varchar(255) NOT NULL,
  `actor_label` varchar(20) NOT NULL,
  `type` varchar(1) DEFAULT NULL,
  PRIMARY KEY (`actor_id`),
  UNIQUE KEY `actor_name_unique` (`actor_name`)
) ENGINE=InnoDB AUTO_INCREMENT=272360 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for category
-- ----------------------------
DROP TABLE IF EXISTS `category`;
CREATE TABLE `category` (
  `category_id` int(11) NOT NULL AUTO_INCREMENT,
  `category_name` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`category_id`),
  UNIQUE KEY `category_name_unique` (`category_name`),
  KEY `category_name` (`category_name`)
) ENGINE=InnoDB AUTO_INCREMENT=778 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for label
-- ----------------------------
DROP TABLE IF EXISTS `label`;
CREATE TABLE `label` (
  `video_num` int(11) NOT NULL AUTO_INCREMENT,
  `video_label` varchar(100) NOT NULL,
  `video_download` tinyint(1) unsigned zerofill NOT NULL DEFAULT '0',
  PRIMARY KEY (`video_num`),
  UNIQUE KEY `label_unique` (`video_label`)
) ENGINE=InnoDB AUTO_INCREMENT=1420347 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for v2a
-- ----------------------------
DROP TABLE IF EXISTS `v2a`;
CREATE TABLE `v2a` (
  `v2a_id` int(11) NOT NULL AUTO_INCREMENT,
  `v2a_fk_video` int(11) DEFAULT NULL,
  `v2a_fk_actor` int(11) DEFAULT NULL,
  PRIMARY KEY (`v2a_id`),
  KEY `v2a_fk_video` (`v2a_fk_video`),
  KEY `v2a_fk_actor` (`v2a_fk_actor`),
  CONSTRAINT `v2a_ibfk_1` FOREIGN KEY (`v2a_fk_actor`) REFERENCES `actor` (`actor_id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `v2a_ibfk_2` FOREIGN KEY (`v2a_fk_video`) REFERENCES `video` (`video_id`) ON DELETE SET NULL ON UPDATE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=701316 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for v2c
-- ----------------------------
DROP TABLE IF EXISTS `v2c`;
CREATE TABLE `v2c` (
  `v2c` int(11) NOT NULL AUTO_INCREMENT,
  `v2c_fk_video` int(11) DEFAULT NULL,
  `v2c_fk_category` int(11) DEFAULT NULL,
  PRIMARY KEY (`v2c`),
  KEY `v2c_fk_video` (`v2c_fk_video`),
  KEY `v2c_fk_category` (`v2c_fk_category`),
  CONSTRAINT `v2c_ibfk_1` FOREIGN KEY (`v2c_fk_category`) REFERENCES `category` (`category_id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `v2c_ibfk_2` FOREIGN KEY (`v2c_fk_video`) REFERENCES `video` (`video_id`) ON DELETE SET NULL ON UPDATE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=1262448 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for video
-- ----------------------------
DROP TABLE IF EXISTS `video`;
CREATE TABLE `video` (
  `video_id` int(11) DEFAULT NULL,
  `video_name` varchar(255) DEFAULT NULL,
  `license` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `director` varchar(255) DEFAULT NULL,
  `label` varchar(255) DEFAULT NULL,
  `date` varchar(10) DEFAULT NULL,
  `maker` varchar(255) DEFAULT NULL,
  UNIQUE KEY `lic` (`license`),
  KEY `video_id` (`video_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
