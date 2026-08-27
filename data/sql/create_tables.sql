-- Для розуміння базової структури отриманих даних, визначимо основні характеристики усіх надходжень/витрат.

--1a. Створимо проміжну таблицю, що узагальнює усі види надходжень у стовбець - "income" та усі види витрат у стовбець -"expenses":		
CREATE MATERIALIZED VIEW IF NOT EXISTS inc_exp AS
    SELECT weekday, record_date,
		-- спочатку створимо масиви даних, що об'єднують окремо надходження та витрати, за допомогою "ARRAY[]", а потім використаємо 
		-- "UNNEST()", що дозволяє коректно розраховувати агреговані ф-ції для отриманих масивів або їх окремих елементів:
    	UNNEST(ARRAY[salary, other_income]) AS income,
    	UNNEST(ARRAY[food, travel, health, household_goods, apartment, debts, 
    				clothes_shoes, other_expenses, alcohol, tasties, events, entertainment]) 
			AS expenses
	FROM data_period -- вхідна таблиця даних
	WITH DATA;

--1b. Створимо view-таблицю, що містить проміжні результати (у днях): 
CREATE MATERIALIZED VIEW IF NOT EXISTS days AS
	SELECT
		(SELECT COUNT(DISTINCT dp.record_date) FROM data_period AS dp 
	) AS total_days, -- 1) тривалість досліджувального Періоду; 	  
		(SELECT COUNT(DISTINCT ie.record_date) FROM inc_exp AS ie WHERE expenses IS NOT NULL OR income IS NOT NULL 
	) AS active_days, -- 2) кількість Активних днів;
		(SELECT COUNT(DISTINCT ie.record_date) FROM inc_exp AS ie WHERE income IS NOT NULL 
	) AS income_days, -- 3) кількість днів, коли були Надходження;
		(SELECT COUNT(DISTINCT ie.record_date) FROM inc_exp AS ie WHERE expenses IS NOT NULL 
	) AS expenses_days, -- 4) кількість днів, коли відбувалися Витрати;
		(SELECT COUNT(DISTINCT ie.record_date) FROM inc_exp AS ie WHERE expenses IS NOT NULL AND income IS NOT NULL 
	) AS inc_exp_days -- 5) кількість днів, коли були Надходження і Витрати;
	WITH DATA;

--2. Проведемо первинну часову аналітику узагальнених даних та збережемо отриману таблицю:
CREATE TABLE IF NOT EXISTS day_stat AS
	SELECT '1_total' AS " ", -- "Період даних"
		d.total_days AS num_of_days, -- тривалість періоду
		d.total_days/d.total_days AS frequency, -- частотність
		ROUND(d.total_days/d.total_days::NUMERIC*100, 0) AS "percentage_%" -- загальна кількість днів у відсотках
	FROM days AS d
	UNION 
	SELECT '2_active', -- "Активні дні"
		d.active_days, -- кількість активних днів
		ROUND(d.total_days/d.active_days::NUMERIC, 1), -- як часто траплявся активний день (в середньому у днях)
		ROUND(d.active_days/d.total_days::NUMERIC*100, 0) -- відсоток активних днів від загальної кількості днів
	FROM days AS d
	GROUP BY d.total_days, d.active_days -- групуємо по  кількості активних днів
	UNION
	SELECT '3_income', -- "Надходження"
		d.income_days, -- кількість днів, коли були надходження
		ROUND(d.total_days/d.income_days::NUMERIC, 1), -- як часто відбувалися надходження (в середньому у днях)
		ROUND(d.income_days/d.active_days::NUMERIC*100, 0) -- відсоток днів з надходженнями від кількості активних днів
	FROM days AS d
	GROUP BY d.total_days, d.active_days, d.income_days
	UNION
	SELECT '4_expenses', -- "Витрати"
		d.expenses_days, -- кількість днів, коли були витрати
		ROUND(d.total_days/d.expenses_days::NUMERIC, 1), -- як часто відбувалися витрати (в середньому у днях)
		ROUND(d.expenses_days/d.active_days::NUMERIC*100, 0) -- відсоток днів з витратами від кількості активних днів
	FROM days AS d
	GROUP BY d.total_days, d.active_days, d.expenses_days
	UNION
	SELECT '5_inc_&_exp', -- "Змішані дні"
		d.inc_exp_days, -- кількість днів, коли були надходження та витрати
		ROUND(d.total_days/d.inc_exp_days::NUMERIC, 1), -- як часто в середньому відбувався змішаний день
		ROUND(d.inc_exp_days/d.active_days::NUMERIC*100, 0) -- відсоток змішаних днів від кількості активних днів
	FROM days AS d
	GROUP BY d.total_days, d.active_days, d.inc_exp_days
	ORDER BY 1; -- сортуємо по назві рядка у спадаючому порядку
	
--2b. Проведемо аналіз часових характеристик та зробимо загальні висновки:
CREATE TABLE IF NOT EXISTS concl_day_stat AS
	SELECT '1) Тривалість досліджувального періоду складає - ' || total_days || ' д.' 
		AS "conclusions" 
	FROM days 	
	UNION
	SELECT '2) Сумарна кількість "активних" днів - ' || active_days || 
		', що складає ' || ROUND(active_days/total_days::NUMERIC*100, 0) || '% від загальної тривалості.' 
		AS "conclusions" 
	FROM days 
	UNION
	SELECT '3) ' || expenses_days || ' д. або ' || ROUND(expenses_days/active_days::NUMERIC*100, 0) || '% від їх сумарної активності - склали Витрати.' 
		AS "conclusions" 
	FROM days
	UNION
	SELECT '4) ' || income_days || ' д, що складає ' || ROUND(income_days/active_days::NUMERIC*100, 0) || '% всіх активних днів, - це Надходження.'  
		AS "conclusions" 
	FROM days
	UNION
	SELECT '5) ' || ROUND(inc_exp_days/active_days::NUMERIC*100, 0) || '% всіх активних днів - містили Надходження та Витрати одночасно.'  
		AS "conclusions" 
	FROM days
	UNION
	SELECT '6) Витрати відбувалися майже кожен день, тоді як Надходження - в середньому кожні ' || ROUND(total_days/income_days::NUMERIC, 0) || ' д.' 
		AS "conclusions" 
	FROM days
	UNION
	SELECT '7) Витратних днів в ' || ROUND(expenses_days/income_days::NUMERIC, 0) || ' рази більше ніж Прибуткових.' 
		AS "conclusions" 
	FROM days
	ORDER BY 1;

--3. Проведемо аналітику транзакцій для узагальнених даних та збережемо отриману таблицю:
CREATE TABLE IF NOT EXISTS trans_stat AS
	SELECT '1_total' AS " ", -- "За досліджувальний період в цілому"
		ROUND(SUM(ie.income)::NUMERIC - SUM(ie.expenses)::NUMERIC, 0) AS "profit_amount",
		COUNT(ie.income) + COUNT(ie.expenses) AS transactions, -- Всього транзакцій
		ROUND((COUNT(ie.income) + COUNT(ie.expenses))/d.total_days::NUMERIC, 1) AS frequency, -- як часто відбувалися транзакції (в середньому у днях)
		ROUND((COUNT(ie.income) + COUNT(ie.expenses))/(COUNT(ie.income) + COUNT(ie.expenses))::NUMERIC*100, 0) AS "percentage_%" -- загальний відсоток транзакцій для І періоду 
	FROM inc_exp AS ie
	CROSS JOIN days AS d
	GROUP BY d.total_days
	UNION 
	SELECT '2_income' AS " ", -- "Надходження"
		ROUND(SUM(ie.income)::NUMERIC, 0) AS "profit_amount",
		COUNT(ie.income) AS transactions, -- кількість прибуткових транзакцій
		ROUND((COUNT(ie.income) + COUNT(ie.expenses))/COUNT(ie.income)::NUMERIC, 1) AS frequency, -- періодичність появи прибуткової транзакції (в середньому)
		ROUND((COUNT(ie.income))/(COUNT(ie.income) + COUNT(ie.expenses))::NUMERIC*100, 0) AS "percentage_%" -- відсоток прибуткових транзакцій від загальної кількості
	FROM inc_exp AS ie
	UNION
	SELECT '3_expenses' AS " ", -- "Витрати"
		ROUND(SUM(ie.expenses)::NUMERIC, 0) AS "profit_amount",
		COUNT(ie.expenses) AS transactions, -- кількість витратних транзакцій
		ROUND((COUNT(ie.income) + COUNT(ie.expenses))/COUNT(ie.expenses)::NUMERIC, 1) AS frequency, -- періодичність появи витратної транзакції (в середньому)
		ROUND((COUNT(ie.expenses))/(COUNT(ie.income) + COUNT(ie.expenses))::NUMERIC*100, 0) AS "percentage_%" -- відсоток витратних транзакцій від загальної кількості
	FROM inc_exp AS ie
	ORDER BY 1; -- сортуємо по назві рядка у спадаючому порядку

--3b. Проведемо аналіз розрахованих характеристик та зробимо загальні висновки:
CREATE TABLE IF NOT EXISTS concl_trans_stat AS
	SELECT '1) У підсумку, фінансовий результат склав: ' || SUM(income)::NUMERIC - SUM(expenses)::NUMERIC || ' грн, а Норма заощаджень: ' 
		|| ROUND((SUM(income)::NUMERIC - SUM(expenses)::NUMERIC) / SUM(income)::NUMERIC*100, 2) || '%.' 
		AS "conclusions" 
	FROM inc_exp 
	UNION
	SELECT '2) Протягом цього періоду, в середньому, відбувалося ' || ROUND((COUNT(income) + COUNT(expenses))/total_days::NUMERIC, 1) || 
		' транз. на день, а їх сумарна кількість - ' || COUNT(income) + COUNT(expenses) || '.' 
		AS "conclusions" 
	FROM inc_exp 
	CROSS JOIN days 
	GROUP BY total_days
	UNION
	SELECT '3) ' || COUNT(expenses) || ' (' || ROUND((COUNT(expenses))/(COUNT(income) + COUNT(expenses))::NUMERIC*100, 0) 
		|| '% від сумарної кількості) транз, на суму ' || SUM(expenses)::NUMERIC || ' грн - виявилися Витратними.' 
		AS "conclusions" 
	FROM inc_exp
	UNION
	SELECT '4) Кількість Прибуткових транзакцій - ' || COUNT(income) 
		|| ' (лише ' || ROUND((COUNT(income))/(COUNT(income) + COUNT(expenses))::NUMERIC*100, 0) || '% від загальної кількості). ' 
		'Їх загальна сума - ' || SUM(income)::NUMERIC || ' грн.' 
		AS "conclusions"
	FROM inc_exp
	UNION
	SELECT '5) Майже будь-яка транзакція була Витратною і лише кожна ' || ROUND((COUNT(income) + COUNT(expenses))/COUNT(income)::NUMERIC, 0) || ' - Прибутковою.' 
		AS "conclusions"
	FROM inc_exp
	ORDER BY 1;

--4. Проведемо аналітику Надходжень/Витрат на рівні - "Рік" та збережемо отриману таблицю:   
CREATE TABLE IF NOT EXISTS year_stat AS
-- зробимо попередню Місячну агрегацію надходжень/витрат
	WITH group_month AS ( 
		SELECT EXTRACT('YEAR' FROM ie.record_date) AS years, -- вилучаємо рік з дати
			TO_CHAR(ie.record_date, 'MONTH') AS months, -- вилучаємо назву місяця з дати
			SUM(ie.income) AS month_income, -- сума надходжень за кожен місяць
			SUM(ie.expenses) AS month_expenses
		FROM inc_exp AS ie
		WHERE ie.expenses IS NOT NULL OR ie.income IS NOT NULL
		GROUP BY years, months -- групуємо кожен рік по місяцях	
	)
	SELECT gm.years,
		ROUND(SUM(gm.month_income)::NUMERIC, 0) AS inc_sum, -- Сума надходжень за кожен рік
		ROUND(AVG(gm.month_income)::NUMERIC, 0) AS inc_mean, -- Середнє місячне надходження
		ROUND(STDDEV(gm.month_income)::NUMERIC / AVG(gm.month_income)::NUMERIC, 2) AS inc_cv, -- Стабільність надходжень
		ROUND(SUM(gm.month_expenses)::NUMERIC, 0) AS exp_sum, -- Сума витрат за кожен рік	
		ROUND(AVG(gm.month_expenses)::NUMERIC, 0) AS exp_mean, -- Середнє  
		ROUND(STDDEV(gm.month_expenses)::NUMERIC / AVG(gm.month_expenses)::NUMERIC, 2) AS exp_cv, -- Стабільність
		ROUND((AVG(gm.month_income)::NUMERIC - AVG(gm.month_expenses)::NUMERIC), 2) AS profit_mean, -- Прибуток за рік
		(1 - ROUND(AVG(gm.month_expenses)::NUMERIC / AVG(gm.month_income)::NUMERIC, 2))*100 AS "saving_rate_%" -- Норма заощаджень
	FROM group_month AS gm -- для розрахунків використовуємо табличний вираз, створений за допомогою "WITH"
	GROUP BY gm.years -- групуємо по року
	ORDER BY gm.years; -- сортуємо по року у зростаючому порядку
	--LIMIT 4; -- показуємо ті рядки, які містять розрахунки за повний рік	

--4b. Проведемо аналіз розрахованих річних характеристик та зробимо висновки:    
CREATE TABLE IF NOT EXISTS schema_year_stat AS
	SELECT '2013 - єдиний рік, коли сума витрат перебільшила доходи! Від''ємний Грошовий потік в середньому склав: (-77.75) грн/міс.' AS "conclusions",		
		'0' AS " ",
		'2013' AS "years"
	UNION
	SELECT 'але маємо найстабільніший середній розмір Витрат (3100 грн/міс) та Надходжень (3023 грн/міс) за цей період.' AS "conclusions",			
		'1' AS " ",
		'2013' AS "years"
	UNION
	SELECT '2014 - в цілому, видався менш стабільним ніж попередній рік, а середньомісячні показники Надходжень та Витрат зменшилися.'  AS "conclusions",		
		'2' AS " ",
		'2014' AS "years"
	UNION
	SELECT 'причиною м.б. початок бойових дій на Донбасі. Але 2014 виявився значно ефективнішим - Норма заощаджень на 9% вище ніж у 2013 р.' AS "conclusions",		
		'3' AS " ",
		'2014' AS "years"
		UNION
	SELECT '2015 - середній розмір Надходжень - 2919 грн/міс. Було витрачено найменшу кількість грошей, а Норма заощаджень досягла максимуму - 11%.' AS "conclusions",			
		'4' AS " ",
		'2015' AS "years"
	UNION
	SELECT 'місячний розмір Витрат має високий хаотичний характер та є ненадійним показником (м.б. велика кількість імпульсивних витрат).' AS "conclusions",
		'5' AS " ",
		'2015' AS "years"
	UNION
	SELECT '2016 - виявився найнестабільнішим, але НЕ менш ефективним роком, ніж 2015 - Заощадження також склали 11%. Високий розкид Доходів'  AS "conclusions",			
		'6' AS " ",
		'2016' AS "years"
	UNION
	SELECT ' можна пояснити частим дрібним фрілансом. Як показник місячних значень краще використовувати Медіану замість Середнього.' AS "conclusions",		
		'7' AS " ",
		'2016' AS "years"
	UNION
	SELECT '2017 - досліджувальний період припадає лише на перші 4 місяці цоього року, які виявилися дуже ненадійними та витратними,' AS "conclusions",		
		'8' AS " ",
		'2017' AS "years"
	UNION
	SELECT 'порівняння з іншими роками робити у цьому випадку не доречно.' AS "conclusions",		
		'9' AS " ",
		'2017' AS "years"
	ORDER BY 2;

CREATE TABLE IF NOT EXISTS concl_year_stat AS
	SELECT * 
	FROM schema_year_stat AS sys
	WHERE sys.years::NUMERIC IN (
		SELECT ys.years
		FROM year_stat AS ys
		)


 







