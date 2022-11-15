with recom as (
	with top_category as (
		with ranking as(
			Select 
				c.customer_id,
				cate.category_id,
				count(i.film_id) as frequency,
				sum(p.amount) revenue 
			From 
				customer c
			Inner Join payment p On p.customer_id = c.customer_id 
			Inner Join rental r On r.customer_id = c.customer_id And p.rental_id = r.rental_id
			Inner Join inventory i On r.inventory_id = i.inventory_id Inner Join film f On i.film_id = f.film_id
			Inner Join film_category fc On fc.film_id = f.film_id
			Inner Join category cate On fc.category_id = cate.category_id where c.customer_id = '1'
			group by cate.category_id,c.customer_id 
			order by Revenue desc
		)
		select 
			ranking.customer_id,
			ranking.category_id,
			ranking.frequency,
			ranking.revenue, 
			DENSE_RANK() OVER (
				PARTITION BY ranking.customer_id 
				ORDER BY frequency DESC
			) AS frequency_rank
		FROM 
			ranking
	)
	Select 
		fc.category_id,
		cate.name,
		fc.film_id,
		f.title, 
		count(i.film_id) as frequency,
		sum(p.amount) revenue 
	From 
		film_category fc
	Inner Join inventory i On fc.film_id = i.film_id
	Inner Join rental r On r.inventory_id = i.inventory_id
	Inner Join payment p On p.rental_id = r.rental_id
	Inner Join category cate On fc.category_id = cate.category_id 
	Inner Join film f On i.film_id = f.film_id
	where fc.category_id = (
		select 
			top_category.category_id from top_category
		where frequency_rank=1 limit 1
	) 
	AND fc.film_id NOT IN (
		Select 
			distinct(i.film_id) as watched
		From 
			inventory i
		Inner Join rental r On r.inventory_id = i.inventory_id
		Inner Join customer c On r.customer_id = c.customer_id
			where c.customer_id='1'
	order by watched
	)
	group by 
		fc.film_id, 
		fc.category_id,
		cate.name,
		f.title
	order by 
		fc.category_id Asc , 
		frequency Desc,
		revenue desc 
	limit 3
)
SELECT 
	name as fav_genre,
	nth_value(film_id,1)OVER(Order BY frequency Desc,revenue desc) AS rec1,
	nth_value(title,1)OVER(Order BY frequency Desc,revenue desc) AS rec1_name,
	nth_value(film_id,2)OVER(Order BY frequency Desc,revenue desc) AS rec2,
	nth_value(title,2)OVER(Order BY frequency Desc,revenue desc) AS rec2_name,
	nth_value(film_id,3)OVER(Order BY frequency Desc,revenue desc) AS rec3,
	nth_value(title,3)OVER(Order BY frequency Desc,revenue desc) AS rec3_name
FROM recom Limit 1 Offset 2;
