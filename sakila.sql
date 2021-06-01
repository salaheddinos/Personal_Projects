# Here I practice mysql querying skills on a famous dataset named Sakila
# Database description : 
# The Sakila sample database was initially developed by Mike Hillyer, a former member of the MySQL AB documentation team.

##CODE##

SELECT 
    first_name, last_name
FROM
    sakila.customer
WHERE
    first_name LIKE 'Daniel'
        OR last_name LIKE 'Daniel';

-- Merge last name and first name together
SELECT 
    full_name
FROM
    (SELECT 
        CONCAT(first_name, ' ', last_name) AS full_name
    FROM
        sakila.customer) AS f_names
WHERE
    full_name LIKE '%Daniel%';

-- Show total number of movie rentals, avg rental_rate of all movies 
SELECT 
    COUNT(*) AS total_rented, AVG(amount) AS avg_rental_price
FROM
    sakila.rental r
        JOIN
    sakila.payment p ON r.rental_id = p.rental_id;

-- Check if total rented is correct
SELECT 
    COUNT(*)
FROM
    sakila.rental;

-- Look at the avg movie rental_price for each customer. Also, include the number of rentals per customer. 
-- Report these summary stats only for customers with more than 7 rentals and order by avg_rating 
SELECT 
    r.customer_id,
    COUNT(*) AS total_rented,
    AVG(amount) AS avg_rental_price
FROM
    sakila.rental r
        JOIN
    sakila.payment p ON r.rental_id = p.rental_id
GROUP BY customer_id
HAVING total_rented > 7
ORDER BY avg_rental_price;

-- Check query for customer 252
SELECT 
    customer_id, COUNT(*)
FROM
    sakila.rental
GROUP BY customer_id
HAVING customer_id = 252;

-- Aggregate revenue, rentals and active customers
-- Calculate revenue coming from movie rentals, num of movie rental and num of customers who rented a movie
SELECT 
    SUM(amount) AS total_revenue,
    COUNT(*) AS total_rented,
    COUNT(DISTINCT r.customer_id) AS num_of_customers
FROM
    sakila.rental r
        JOIN
    sakila.payment p ON r.rental_id = p.rental_id;
-- Return same stats but only for active customers
SELECT 
    SUM(amount) AS total_revenue,
    COUNT(*) AS total_rented,
    COUNT(DISTINCT r.customer_id) AS num_of_customers
FROM
    sakila.rental r
        JOIN
    sakila.payment p ON r.rental_id = p.rental_id
WHERE
    YEAR(rental_date) > '2005';-- Most recent since MAX year is 2006
-- Checking queries :
SELECT 
    MAX(rental_date)
FROM
    sakila.rental;

-- Checking queries :
SELECT 
    rental_date
FROM
    sakila.rental
WHERE
    rental_date > '2005-12-31 00:00:00';
-- Checking queries :
SELECT 
    rental_date
FROM
    sakila.rental
WHERE
    YEAR(rental_date) = '2006';

-- Display which actors play in which movie
SELECT 
    CONCAT(first_name, ' ', last_name) AS actor_name, title
FROM
    sakila.film_actor a
        JOIN
    sakila.film f ON a.film_id = f.film_id
        JOIN
    sakila.actor ac ON a.actor_id = ac.actor_id;

-- How much income did each movie generate? 
SELECT 
    title, SUM(amount) AS total_revenue
FROM
    sakila.rental r
        JOIN
    sakila.payment p ON r.rental_id = p.rental_id
        JOIN
    sakila.inventory i ON r.inventory_id = i.inventory_id
        JOIN
    sakila.film f ON i.film_id = f.film_id
GROUP BY title
ORDER BY total_revenue DESC;

-- Display for each movie how many times it was rented and it's average price, because prices of movies can change over time
SELECT 
    title,
    COUNT(*) AS num_rented,
    ROUND(AVG(amount), 2) AS avg_price
FROM
    sakila.rental r
        JOIN
    sakila.payment p ON r.rental_id = p.rental_id
        JOIN
    sakila.inventory i ON r.inventory_id = i.inventory_id
        JOIN
    sakila.film f ON i.film_id = f.film_id
GROUP BY title
ORDER BY num_rented DESC;

-- Identify favorite actors for US

SELECT 
    CONCAT(act.first_name, ' ', act.last_name) AS actor_name,
    COUNT(*) AS num_of_views
FROM
    sakila.rental r
        JOIN
    sakila.payment p ON r.rental_id = p.rental_id
        JOIN
    sakila.inventory i ON r.inventory_id = i.inventory_id
        JOIN
    sakila.film f ON i.film_id = f.film_id
        JOIN
    sakila.customer c ON p.customer_id = c.customer_id
        JOIN
    sakila.address a ON c.address_id = a.address_id
        JOIN
    sakila.city ci ON a.city_id = ci.city_id
        JOIN
    sakila.country co ON ci.country_id = co.country_id
        JOIN
    sakila.film_actor ac ON f.film_id = ac.film_id
        JOIN
    sakila.actor act ON ac.actor_id = act.actor_id
        JOIN
    sakila.store s ON c.store_id = s.store_id
WHERE
    co.country = 'United States'
GROUP BY actor_name
ORDER BY num_of_views DESC;

-- find the actor with most films
SELECT 
    CONCAT(first_name, ' ', last_name) AS actor_name,
    COUNT(*) num
FROM
    sakila.actor ac
        JOIN
    sakila.film_actor act ON ac.actor_id = act.actor_id
GROUP BY ac.actor_id
ORDER BY num DESC
LIMIT 1;

-- calculate the cumulative revenue of all stores 
set @csum := 0;
WITH income_running AS (
SELECT DATE(rental_date) AS dates, 
	   SUM(amount) AS income
FROM sakila.rental r
	JOIN sakila.payment p
	ON r.rental_id = p.rental_id
    JOIN sakila.inventory i
    ON r.inventory_id = i.inventory_id
    JOIN sakila.film f
    ON i.film_id = f.film_id 
GROUP BY DATE(rental_date)
ORDER BY dates)
SELECT dates, income, (@csum := @csum + income) AS cummulative
FROM income_running;

--  display all actors who appear in the film Alone Trip
SELECT 
    CONCAT(first_name, ' ', last_name) AS full_name, title
FROM
    sakila.actor ac
        JOIN
    sakila.film_actor act ON ac.actor_id = act.actor_id
        JOIN
    sakila.film f ON act.film_id = f.film_id
WHERE
    title = 'Alone Trip';

-- How many distinct actors last names are there?
SELECT DISTINCT
    last_name
FROM
    sakila.actor;

-- Which last names are not repeated?
SELECT 
    last_name, COUNT(*) AS num
FROM
    sakila.actor
GROUP BY last_name
HAVING num <= 1
ORDER BY num DESC;

-- Which last names appear more than once?
SELECT 
    last_name, COUNT(*) AS num
FROM
    sakila.actor
GROUP BY last_name
HAVING num > 1
ORDER BY num DESC;

-- Is ‘Academy Dinosaur’ available for rent from Store 1?
SELECT 
    store_id, title
FROM
    sakila.inventory i
        JOIN
    sakila.film f ON i.film_id = f.film_id
WHERE
    store_id = 1
        AND title = 'Academy Dinosaur';
    
-- When is ‘Academy Dinosaur’ due?
SELECT 
    return_date
FROM
    sakila.inventory i
        JOIN
    sakila.film f ON i.film_id = f.film_id
        JOIN
    sakila.rental r ON i.inventory_id = r.inventory_id
WHERE
    title = 'Academy Dinosaur';

-- What is that average running time of all the films in the sakila DB?
SELECT 
    AVG(length) AS avg_running_time
FROM
    sakila.film;

-- What is the average running time of films by category?
SELECT 
    name, AVG(length) AS avg_running_time
FROM
    sakila.film f
        JOIN
    sakila.film_category fc ON f.film_id = fc.film_id
        JOIN
    sakila.category c ON fc.category_id = c.category_id
GROUP BY name
ORDER BY avg_running_time DESC;

--  You need to find the ID number, first name, and last name of an actor, of whom you know only the first name, "Joe." 
--  What is one query would you use to obtain this information?
SELECT 
    *
FROM
    sakila.actor
WHERE
    first_name LIKE '%Joe%';

-- Find all actors whose last name contain the letters GEN
SELECT 
    *
FROM
    sakila.actor
WHERE
    last_name LIKE '%GEN%';

--  Using IN, display the country_id and country columns of the following countries: Afghanistan, Bangladesh, and China:
SELECT 
    country_id, country
FROM
    sakila.country
WHERE
    country IN ('Afghanistan' , 'Bangladesh', 'China');

-- List the last names of actors, as well as how many actors have that last name.
SELECT 
    last_name, COUNT(*) AS freq
FROM
    sakila.actor
GROUP BY last_name
ORDER BY freq DESC;

-- List last names of actors and the number of actors who have that last name, but only for names that are shared by at least two actors
SELECT 
    last_name, freq
FROM
    (SELECT 
        last_name, COUNT(*) AS freq
    FROM
        sakila.actor
    GROUP BY last_name
    ORDER BY freq DESC) ln
WHERE
    freq >= 2;

-- The actor HARPO WILLIAMS was accidentally entered in the actor table as GROUCHO WILLIAMS. Write a query to fix the record.
UPDATE sakila.actor 
SET 
    first_name = 'HARPO',
    last_name = 'WILLIAMS'
WHERE
    first_name = 'GROUCHO'
        AND last_name = 'WILLIAMS';
    
SELECT 
    *
FROM
    sakila.actor
WHERE
    UPPER(first_name) = 'HARPO'
        AND UPPER(last_name) = 'WILLIAMS';

-- Perhaps we were too hasty in changing GROUCHO to HARPO. It turns out that GROUCHO was the correct name after all! In a single query, 
-- if the first name of the actor is currently HARPO, change it to GROUCHO
UPDATE sakila.actor 
SET 
    first_name = 'GROUCHO'
WHERE
    first_name = 'HARPO';
-- Verify query
SELECT 
    first_name, last_name
FROM
    sakila.actor
WHERE
    UPPER(first_name) = 'HARPO';

-- Use JOIN to display the total amount rung up by each staff member in August of 2005. Use tables staff and payment
SELECT 
    p.staff_id,
    CONCAT(first_name, ' ', last_name) AS staff_name,
    SUM(amount) AS revenue
FROM
    sakila.payment p
        JOIN
    sakila.staff s ON p.staff_id = s.staff_id
WHERE
    MONTH(payment_date) = '08'
        AND YEAR(payment_date) = '2005'
GROUP BY staff_id;

-- Verify query
SELECT 
    staff_id, SUM(amount)
FROM
    sakila.payment
WHERE
    MONTH(payment_date) = '08'
        AND YEAR(payment_date) = '2005'
        AND staff_id = 1;

-- List each film and the number of actors who are listed for that film. Use tables film_actor and film. Use inner join.
SELECT 
    title, COUNT(*) num_of_actors
FROM
    sakila.film_actor fa
        JOIN
    sakila.film f ON fa.film_id = f.film_id
GROUP BY title
ORDER BY num_of_actors DESC;
-- Verify query
SELECT 
    *
FROM
    sakila.film_actor fa
        JOIN
    sakila.film f ON fa.film_id = f.film_id
WHERE
    UPPER(title) = 'ACADEMY DINOSAUR';

-- How many copies of the film Hunchback Impossible exist in the inventory system?
-- Find film_id
SELECT 
    film_id
FROM
    sakila.film
WHERE
    UPPER(title) = 'Hunchback Impossible';

SELECT 
    film_id, COUNT(*) AS qt
FROM
    sakila.inventory i
WHERE
    film_id = 439;

-- Using the tables payment and customer and the JOIN command, list the total paid by each customer. List the customers alphabetically by last name
SELECT 
    customer_id, first_name, last_name, SUM(amount) AS revenue
FROM
    sakila.customer c
        JOIN
    sakila.payment p USING (customer_id)
GROUP BY customer_id
ORDER BY last_name;

-- The music of Queen and Kris Kristofferson have seen an unlikely resurgence. As an unintended consequence, ... 
-- films starting with the letters K and Q have also soared in popularity. 
-- Use subqueries to display the titles of movies starting with the letters K and Q whose language is English.
SELECT 
    title
FROM
    sakila.film f
WHERE
    title LIKE 'K%'
        OR title LIKE 'Q%'
        AND language_id IN (SELECT 
            language_id
        FROM
            sakila.language
        WHERE
            name = 'English');

-- Display all actors who appear in the film Alone Trip
SELECT 
    first_name, last_name
FROM
    sakila.film_actor fa
        JOIN
    sakila.actor a ON fa.actor_id = a.actor_id
        JOIN
    sakila.film f ON fa.film_id = f.film_id
WHERE
    UPPER(title) = 'Alone Trip';

-- Use subqueries to display all actors who appear in the film Alone Trip
SELECT 
    CONCAT(first_name, ' ', last_name) AS full_name
FROM
    sakila.actor
WHERE
    actor_id IN (SELECT 
            actor_id
        FROM
            sakila.film_actor
        WHERE
            film_id IN (SELECT 
                    film_id
                FROM
                    sakila.film
                WHERE
                    UPPER(title) = 'Alone Trip'));

-- You want to run an email marketing campaign in Canada, for which you will need the names and email addresses of all Canadian customers. 
-- Use joins to retrieve this information.
SELECT 
    *
FROM
    sakila.customer c
        LEFT JOIN
    sakila.address a ON c.address_id = a.address_id
        LEFT JOIN
    sakila.city ci ON a.city_id = ci.city_id
        LEFT JOIN
    sakila.country co ON ci.country_id = co.country_id
WHERE
    country = 'Canada';

-- Sales have been lagging among young families, and you wish to target all family movies for a promotion. Identify all movies categorized as family films.
-- Use subqueries
SELECT 
    title
FROM
    sakila.film f
WHERE
    film_id IN (SELECT 
            film_id
        FROM
            sakila.film_category fc
        WHERE
            category_id IN (SELECT 
                    category_id
                FROM
                    sakila.category c
                WHERE
                    LOWER(name) = 'Family'));
                                
-- Display the most frequently rented movies in descending order.
SELECT 
    title, COUNT(*) AS num_rented
FROM
    sakila.rental r
        JOIN
    sakila.inventory i ON r.inventory_id = i.inventory_id
        JOIN
    sakila.film f ON i.film_id = f.film_id
GROUP BY title
ORDER BY num_rented DESC;

-- Write a query to display how much business, in dollars, each store brought in.
SELECT 
    staff_id, SUM(amount) AS revenue
FROM
    sakila.payment p
GROUP BY staff_id
ORDER BY revenue DESC;

-- Write a query to display for each store its store ID, city, and country.
SELECT 
    store_id, city, country
FROM
    sakila.store s
        JOIN
    sakila.address a ON s.address_id = a.address_id
        JOIN
    sakila.city ci ON a.city_id = ci.city_id
        JOIN
    sakila.country c ON ci.country_id = c.country_id;

-- List the top five genres in gross revenue in descending order. 
-- (Hint: you may need to use the following tables: category, film_category, inventory, payment, and rental.)
SELECT 
    category_id, name AS category, SUM(amount) revenue
FROM
    sakila.category cat
        JOIN
    sakila.film_category fc USING (category_id)
        JOIN
    sakila.inventory i ON fc.film_id = i.film_id
        JOIN
    sakila.rental r ON i.inventory_id = r.inventory_id
        JOIN
    sakila.payment p ON r.rental_id = p.rental_id
GROUP BY category_id , category
ORDER BY revenue DESC
LIMIT 5;

--  In your new role as an executive, you would like to have an easy way of viewing the Top five genres by gross revenue. 
-- Use the solution from the problem above to create a view. 
-- If you haven't solved 7h, you can substitute another query to create a view.
CREATE VIEW top_5 AS
    SELECT 
        category_id, name AS category, SUM(amount) revenue
    FROM
        sakila.category cat
            JOIN
        sakila.film_category fc USING (category_id)
            JOIN
        sakila.inventory i ON fc.film_id = i.film_id
            JOIN
        sakila.rental r ON i.inventory_id = r.inventory_id
            JOIN
        sakila.payment p ON r.rental_id = p.rental_id
    GROUP BY category_id , category
    ORDER BY revenue DESC
    LIMIT 5;

-- Query view
SELECT 
    *
FROM
    top_5;

-- You find that you no longer need the view top_five_genres. Write a query to delete it.
DROP VIEW top_5;

-- Select customers with less than 5 rentals using joins
SELECT 
    customer_id, first_name, last_name, COUNT(*) AS num_rented
FROM
    sakila.rental r
        JOIN
    sakila.customer c USING (customer_id)
GROUP BY customer_id
ORDER BY num_rented DESC
LIMIT 5;


-- Select films whose amount are greater than the average amount of all movies in each category.
-- We can see that American Circus has a higher than average price for it's category
-- In this query we limit results to 50 for computing purposes
-- This query will return only the action categ
WITH movie_price AS (
SELECT title, name, amount
FROM sakila.category cat
JOIN sakila.film_category fc
USING(category_id)
JOIN sakila.inventory i
ON fc.film_id = i.film_id
JOIN sakila.rental r
ON i.inventory_id = r.inventory_id
JOIN sakila.payment p
ON r.rental_id = p.rental_id
JOIN sakila.film f
ON i.film_id = f.film_id
LIMIT 50
)
SELECT title, amount
FROM movie_price m
WHERE amount > (
						SELECT AVG(amount) 
                        FROM movie_price
                        WHERE name = m.name);

-- Verify the query : indeed the above querie will return all movies whose price is above the avg price for their categ
WITH movie_price AS (
SELECT title, name, amount
FROM sakila.category cat
JOIN sakila.film_category fc
USING(category_id)
JOIN sakila.inventory i
ON fc.film_id = i.film_id
JOIN sakila.rental r
ON i.inventory_id = r.inventory_id
JOIN sakila.payment p
ON r.rental_id = p.rental_id
JOIN sakila.film f
ON i.film_id = f.film_id
LIMIT 50
)
SELECT *
FROM movie_price
WHERE amount > 4.590;

-- Select all movies with higher than average price
SELECT 
    *
FROM
    sakila.film
WHERE
    rental_rate > (SELECT 
            AVG(rental_rate)
        FROM
            sakila.film);

-- Select movies that belong to the action categ and whose avg price is > 3
WITH movie_price AS (
SELECT title, name, amount
FROM sakila.category cat
JOIN sakila.film_category fc
USING(category_id)
JOIN sakila.inventory i
ON fc.film_id = i.film_id
JOIN sakila.rental r
ON i.inventory_id = r.inventory_id
JOIN sakila.payment p
ON r.rental_id = p.rental_id
JOIN sakila.film f
ON i.film_id = f.film_id
LIMIT 50
)
SELECT *
FROM movie_price
WHERE name = "Action"
AND amount > (  
				SELECT AVG(amount)
                FROM movie_price
);

-- Return a table with two cols : original price and 50% promotion for movies prior to 2006
SELECT 
    title,
    rental_rate AS original_price,
    (rental_rate * 0.5) AS promotion
FROM
    sakila.film
WHERE
    release_year < 2006;

-- Concat movies titles in one row for PG rating
-- Since all movies are in English we get this result
SELECT 
    name AS language, GROUP_CONCAT(title)
FROM
    sakila.film
        JOIN
    sakila.language USING (language_id)
WHERE
    rating = 'G'
GROUP BY name;

-- Get the revenue for each week in June 2005

SELECT 
    DATE(rental_date) AS date, SUM(amount) AS weekly_revenue
FROM
    sakila.rental r
        JOIN
    sakila.payment p USING (rental_id)
GROUP BY WEEK(rental_date);

-- Verify query
SELECT 
    SUM(amount)
FROM
    sakila.rental r
        JOIN
    sakila.payment p USING (rental_id)
WHERE
    rental_date BETWEEN '2005-05-24' AND '2005-05-29';
