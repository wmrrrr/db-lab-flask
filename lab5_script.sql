CREATE TABLE `reviews` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `course_id` INT,
    `user_id` INT,
    `rating` TINYINT(1) CHECK (`rating` BETWEEN 1 AND 5),
    `comment` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$

CREATE TRIGGER `before_review_insert`
BEFORE INSERT ON `reviews`CREATE TABLE `reviews` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `course_id` INT,
    `user_id` INT,
    `rating` TINYINT(1) CHECK (`rating` BETWEEN 1 AND 5),
    `comment` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$

CREATE TRIGGER `before_review_insert`
BEFORE INSERT ON `reviews`
FOR EACH ROW
BEGIN
    -- Перевірка існування запису в таблиці courses
    IF NOT EXISTS (
        SELECT 1 FROM `courses` WHERE `id` = NEW.`course_id`
    ) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Помилка: Вказаний course_id не існує.';
    END IF;
END$$

DELIMITER ;


DELIMITER $$

CREATE TRIGGER `before_review_update`
BEFORE UPDATE ON `reviews`
FOR EACH ROW
BEGIN
    -- Перевірка існування запису в таблиці courses
    IF NOT EXISTS (
        SELECT 1 FROM `courses` WHERE `id` = NEW.`course_id`
    ) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Помилка: Вказаний course_id не існує.';
    END IF;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE InsertIntoReviews(
    IN courseId INT,
    IN userId INT,
    IN rating TINYINT,
    IN comment TEXT
)
BEGIN
    INSERT INTO `reviews` (`course_id`, `user_id`, `rating`, `comment`)
    VALUES (courseId, userId, rating, comment);
END$$

DELIMITER ;




DELIMITER $$

CREATE PROCEDURE InsertEnrollmentByNames(
    IN userName VARCHAR(100),
    IN courseTitle VARCHAR(255),
    IN enrollmentDate DATE,
    IN completionStatus VARCHAR(50)
)
BEGIN
    DECLARE userId INT;
    DECLARE courseId INT;

    -- Отримання user_id з таблиці users
    SELECT `id` INTO userId FROM `users` WHERE `name` = userName;
    IF userId IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User not found';
    END IF;

    -- Отримання course_id з таблиці courses
    SELECT `id` INTO courseId FROM `courses` WHERE `title` = courseTitle;
    IF courseId IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Course not found';
    END IF;

    -- Вставка в таблицю enrollments
    INSERT INTO `enrollments` (`user_id`, `course_id`, `enrollment_date`, `completion_status`)
    VALUES (userId, courseId, enrollmentDate, completionStatus);
END$$

DELIMITER ;

SELECT * FROM courses;

DELIMITER $$

CREATE PROCEDURE InsertNonameRecords()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 10 DO
        INSERT INTO `users` (`name`, `email`, `password`)
        VALUES (CONCAT('Noname', i), CONCAT('noname', i, '@example.com'), 'password');
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;



CALL InsertNonameRecords();



DELIMITER $$

CREATE FUNCTION GetStatistic(
    statType VARCHAR(10)   -- Тип статистики: MAX, MIN, SUM, AVG
) RETURNS DECIMAL(10, 2)
DETERMINISTIC
BEGIN
    DECLARE result DECIMAL(10, 2);

    IF statType = 'MAX' THEN
        SELECT MAX(id) INTO result FROM users;
    ELSEIF statType = 'MIN' THEN
        SELECT MIN(id) INTO result FROM users;
    ELSEIF statType = 'SUM' THEN
        SELECT SUM(id) INTO result FROM users;
    ELSEIF statType = 'AVG' THEN
        SELECT AVG(id) INTO result FROM users;
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid statType. Use MAX, MIN, SUM, or AVG.';
    END IF;

    RETURN result;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE CallStatisticFunction(
    IN statType VARCHAR(10) -- Тип статистики: MAX, MIN, SUM, AVG
)
BEGIN
    -- Виклик функції та повернення результату через SELECT
    SELECT GetStatistic(statType) AS StatisticResult;
END$$

DELIMITER ;








DELIMITER $$

CREATE PROCEDURE CreateAndDistributeData(
    IN parentTable VARCHAR(100),
    IN newTableName1 VARCHAR(100),
    IN newTableName2 VARCHAR(100)
)
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE rowId INT;
    DECLARE rowData1, rowData2 VARCHAR(255);
    DECLARE cur CURSOR FOR SELECT * FROM dynamic_table;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Видалення таблиць, якщо вони вже існують
    SET @dropQuery1 = CONCAT('DROP TABLE IF EXISTS `', newTableName1, '`');
    SET @dropQuery2 = CONCAT('DROP TABLE IF EXISTS `', newTableName2, '`');
    PREPARE stmt FROM @dropQuery1;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    PREPARE stmt FROM @dropQuery2;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    -- Видалення тимчасової таблиці, якщо вона існує
    DROP TEMPORARY TABLE IF EXISTS dynamic_table;

    -- Створення тимчасової таблиці з даними parentTable
    SET @selectQuery = CONCAT('CREATE TEMPORARY TABLE dynamic_table AS SELECT * FROM `', parentTable, '`');
    PREPARE stmt FROM @selectQuery;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    -- Створення нових таблиць
    SET @query1 = CONCAT('CREATE TABLE `', newTableName1, '` LIKE `', parentTable, '`');
    SET @query2 = CONCAT('CREATE TABLE `', newTableName2, '` LIKE `', parentTable, '`');

    PREPARE stmt FROM @query1;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    PREPARE stmt FROM @query2;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    -- Відкриття курсора
    OPEN cur;

    -- Початкове отримання даних
    FETCH cur INTO rowId, rowData1, rowData2;

    WHILE NOT done DO
        -- Формування запиту для вставки в одну з нових таблиць
        IF RAND() < 0.5 THEN
            SET @insertQuery = CONCAT('INSERT INTO `', newTableName1, '` VALUES (', rowId, ', \'', rowData1, '\', \'', rowData2, '\')');
        ELSE
            SET @insertQuery = CONCAT('INSERT INTO `', newTableName2, '` VALUES (', rowId, ', \'', rowData1, '\', \'', rowData2, '\')');
        END IF;

        PREPARE stmt FROM @insertQuery;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        FETCH cur INTO rowId, rowData1, rowData2;
    END WHILE;

    -- Закриття курсора
    CLOSE cur;

    -- Видалення тимчасової таблиці
    DROP TEMPORARY TABLE IF EXISTS dynamic_table;
END$$

DELIMITER ;










CALL CreateAndDistributeData('parent_table', 'new_table1', 'new_table2');



SELECT * FROM parent_table;
SELECT * FROM new_table1;
SELECT * FROM new_table2;



CREATE TABLE parent_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    column1 VARCHAR(255),
    column2 VARCHAR(255)
);

INSERT INTO parent_table (column1, column2)
VALUES 
    ('Data1', 'Value1'),
    ('Data2', 'Value2'),
    ('Data3', 'Value3');



DELIMITER $$

CREATE TRIGGER prevent_username_update
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    IF NEW.name <> OLD.name THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Username cannot be updated.';
    END IF;
END$$

DELIMITER ;


DELIMITER ;

DROP TRIGGER IF EXISTS prevent_update_users;

DELIMITER $$

CREATE TRIGGER prevent_double_zeros_in_email
BEFORE INSERT ON users
FOR EACH ROW
BEGIN
    IF NEW.email LIKE '%00' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email cannot end with two zeros.';
    END IF;
END$$

DELIMITER ;


DELIMITER $$

CREATE TRIGGER prevent_double_zeros_in_email_update
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    IF NEW.email LIKE '%00' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email cannot end with two zeros.';
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER prevent_delete_if_less_than_6
BEFORE DELETE ON courses
FOR EACH ROW
BEGIN
    DECLARE row_count INT;
    SET row_count = (SELECT COUNT(*) FROM courses);
    IF row_count <= 6 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot delete rows: minimum cardinality of 6 rows must be maintained.';
    END IF;
END$$

DELIMITER ;


SELECT * FROM courses;

DELETE FROM courses;
FOR EACH ROW
BEGIN
    -- Перевірка існування запису в таблиці courses
    IF NOT EXISTS (
        SELECT 1 FROM `courses` WHERE `id` = NEW.`course_id`
    ) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Помилка: Вказаний course_id не існує.';
    END IF;
END$$

DELIMITER ;


DELIMITER $$

CREATE TRIGGER `before_review_update`
BEFORE UPDATE ON `reviews`
FOR EACH ROW
BEGIN
    -- Перевірка існування запису в таблиці courses
    IF NOT EXISTS (
        SELECT 1 FROM `courses` WHERE `id` = NEW.`course_id`
    ) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Помилка: Вказаний course_id не існує.';
    END IF;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE InsertIntoReviews(
    IN courseId INT,
    IN userId INT,
    IN rating TINYINT,
    IN comment TEXT
)
BEGIN
    INSERT INTO `reviews` (`course_id`, `user_id`, `rating`, `comment`)
    VALUES (courseId, userId, rating, comment);
END$$

DELIMITER ;




DELIMITER $$

CREATE PROCEDURE InsertEnrollmentByNames(
    IN userName VARCHAR(100),
    IN courseTitle VARCHAR(255),
    IN enrollmentDate DATE,
    IN completionStatus VARCHAR(50)
)
BEGIN
    DECLARE userId INT;
    DECLARE courseId INT;

    -- Отримання user_id з таблиці users
    SELECT `id` INTO userId FROM `users` WHERE `name` = userName;
    IF userId IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User not found';
    END IF;

    -- Отримання course_id з таблиці courses
    SELECT `id` INTO courseId FROM `courses` WHERE `title` = courseTitle;
    IF courseId IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Course not found';
    END IF;

    -- Вставка в таблицю enrollments
    INSERT INTO `enrollments` (`user_id`, `course_id`, `enrollment_date`, `completion_status`)
    VALUES (userId, courseId, enrollmentDate, completionStatus);
END$$

DELIMITER ;

SELECT * FROM courses;

DELIMITER $$

CREATE PROCEDURE InsertNonameRecords()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 10 DO
        INSERT INTO `users` (`name`, `email`, `password`)
        VALUES (CONCAT('Noname', i), CONCAT('noname', i, '@example.com'), 'password');
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;



CALL InsertNonameRecords();



DELIMITER $$

CREATE FUNCTION GetStatistic(
    statType VARCHAR(10)   -- Тип статистики: MAX, MIN, SUM, AVG
) RETURNS DECIMAL(10, 2)
DETERMINISTIC
BEGIN
    DECLARE result DECIMAL(10, 2);

    IF statType = 'MAX' THEN
        SELECT MAX(id) INTO result FROM users;
    ELSEIF statType = 'MIN' THEN
        SELECT MIN(id) INTO result FROM users;
    ELSEIF statType = 'SUM' THEN
        SELECT SUM(id) INTO result FROM users;
    ELSEIF statType = 'AVG' THEN
        SELECT AVG(id) INTO result FROM users;
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid statType. Use MAX, MIN, SUM, or AVG.';
    END IF;

    RETURN result;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE CallStatisticFunction(
    IN statType VARCHAR(10) -- Тип статистики: MAX, MIN, SUM, AVG
)
BEGIN
    -- Виклик функції та повернення результату через SELECT
    SELECT GetStatistic(statType) AS StatisticResult;
END$$

DELIMITER ;








DELIMITER $$

CREATE PROCEDURE CreateAndDistributeData(
    IN parentTable VARCHAR(100),
    IN newTableName1 VARCHAR(100),
    IN newTableName2 VARCHAR(100)
)
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE rowId INT;
    DECLARE rowData1, rowData2 VARCHAR(255);
    DECLARE cur CURSOR FOR SELECT * FROM dynamic_table;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Видалення таблиць, якщо вони вже існують
    SET @dropQuery1 = CONCAT('DROP TABLE IF EXISTS `', newTableName1, '`');
    SET @dropQuery2 = CONCAT('DROP TABLE IF EXISTS `', newTableName2, '`');
    PREPARE stmt FROM @dropQuery1;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    PREPARE stmt FROM @dropQuery2;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    -- Видалення тимчасової таблиці, якщо вона існує
    DROP TEMPORARY TABLE IF EXISTS dynamic_table;

    -- Створення тимчасової таблиці з даними parentTable
    SET @selectQuery = CONCAT('CREATE TEMPORARY TABLE dynamic_table AS SELECT * FROM `', parentTable, '`');
    PREPARE stmt FROM @selectQuery;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    -- Створення нових таблиць
    SET @query1 = CONCAT('CREATE TABLE `', newTableName1, '` LIKE `', parentTable, '`');
    SET @query2 = CONCAT('CREATE TABLE `', newTableName2, '` LIKE `', parentTable, '`');

    PREPARE stmt FROM @query1;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    PREPARE stmt FROM @query2;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    -- Відкриття курсора
    OPEN cur;

    -- Початкове отримання даних
    FETCH cur INTO rowId, rowData1, rowData2;

    WHILE NOT done DO
        -- Формування запиту для вставки в одну з нових таблиць
        IF RAND() < 0.5 THEN
            SET @insertQuery = CONCAT('INSERT INTO `', newTableName1, '` VALUES (', rowId, ', \'', rowData1, '\', \'', rowData2, '\')');
        ELSE
            SET @insertQuery = CONCAT('INSERT INTO `', newTableName2, '` VALUES (', rowId, ', \'', rowData1, '\', \'', rowData2, '\')');
        END IF;

        PREPARE stmt FROM @insertQuery;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        FETCH cur INTO rowId, rowData1, rowData2;
    END WHILE;

    -- Закриття курсора
    CLOSE cur;

    -- Видалення тимчасової таблиці
    DROP TEMPORARY TABLE IF EXISTS dynamic_table;
END$$

DELIMITER ;










CALL CreateAndDistributeData('parent_table', 'new_table1', 'new_table2');



SELECT * FROM parent_table;
SELECT * FROM new_table1;
SELECT * FROM new_table2;



CREATE TABLE parent_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    column1 VARCHAR(255),
    column2 VARCHAR(255)
);

INSERT INTO parent_table (column1, column2)
VALUES 
    ('Data1', 'Value1'),
    ('Data2', 'Value2'),
    ('Data3', 'Value3');



DELIMITER $$

CREATE TRIGGER prevent_username_update
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    IF NEW.name <> OLD.name THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Username cannot be updated.';
    END IF;
END$$

DELIMITER ;


DELIMITER ;

DROP TRIGGER IF EXISTS prevent_update_users;

DELIMITER $$

CREATE TRIGGER prevent_double_zeros_in_email
BEFORE INSERT ON users
FOR EACH ROW
BEGIN
    IF NEW.email LIKE '%00' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email cannot end with two zeros.';
    END IF;
END$$

DELIMITER ;


DELIMITER $$

CREATE TRIGGER prevent_double_zeros_in_email_update
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    IF NEW.email LIKE '%00' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email cannot end with two zeros.';
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER prevent_delete_if_less_than_6
BEFORE DELETE ON courses
FOR EACH ROW
BEGIN
    DECLARE row_count INT;
    SET row_count = (SELECT COUNT(*) FROM courses);
    IF row_count <= 6 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot delete rows: minimum cardinality of 6 rows must be maintained.';
    END IF;
END$$

DELIMITER ;


SELECT * FROM courses;

DELETE FROM courses;





