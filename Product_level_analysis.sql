-- product level analysis 
/* pull out monthly trends to date for number of sales, total revenue and total margin generated for the business
 date limit 2013-01-04 */

select year(created_at) as yr,
       month(created_at) as months,
       count(order_id) as number_of_sales,
       sum(price_usd) as revenue,
       sum(price_usd - cogs_usd) as margin
       from orders
       where created_at < '2013-01-04'
       group by 1,2;

/* company have launched second product back on jan 6th, so pull out together some trend analysis.alter
pull out monthly order volume , overall conversion rates, revenue per session and breakdown of sales by product  
date limit 2012-04-01 to 2013-04-05 */	
    
      select     
           year(website_sessions.created_at) as yr,
           month(website_sessions.created_at) as mo,
           count(distinct website_sessions.website_session_id) as sessions,
           count(distinct orders.order_id) as orders,
           count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as conv_rate,
           sum(orders.price_usd)/count(distinct website_sessions.website_session_id) as revenue_per_session,
           count(distinct case when orders.primary_product_id = 1 then order_id else null end) as product_one_orders,
           count(distinct case when orders.primary_product_id = 2 then order_id else null end ) as product_two_ordrs
           
           from website_sessions
           left join orders
           on website_sessions.website_session_id= orders.website_session_id
           where website_sessions.created_at < '2013-04-01' -- the date of the request
           and website_sessions.created_at > '2012-04-01' -- specified in the request
           group by 1,2 ;
           
           

        
/* product pathing analysis */

-- step 1 find the relevent  product pageviews with the website_session_id
-- step 2 find the next pageview id that occurs after the product pageview
-- step 3 find the pageview_url associated with any applicable next pageview id
-- step 4 summarize the data and analyze the pre vs post periods


-- step 1 : finding the products pageviews we care about
create temporary table products_pageviews
select 
      website_session_id,
      website_pageview_id,
      created_at,
case 
    when created_at <'2013-01-06' then 'A. pre_product_2'
    when created_at >='2013-01-06' then 'B.post_product_2'
    else 'null'
    end as time_period
    from website_pageviews
    where created_at <'2013-04-06' -- date of request
          and created_at >'2012-10-06' -- start of 3 mo before product 2 lunch 
          and pageview_url = '/products';


-- step 2 : find the next pageview id that occure after the product pageview
create temporary table sessions_w_next_pageview_id
select 
     products_pageviews.time_period,
     products_pageviews.website_session_id,
     min(website_pageviews.website_pageview_id) as min_next_pageview_id
     from products_pageviews
     left join website_pageviews
     on website_pageviews.website_session_id=products_pageviews.website_session_id
     and website_pageviews.website_pageview_id > products_pageviews.website_pageview_id
group by 1,2 ;


-- step 3 : find the pageview_url associated with any applicable next pagview id
create temporary table sessions_w_next_pageview_url 
select sessions_w_next_pageview_id.time_period,
       sessions_w_next_pageview_id.website_session_id,
       website_pageviews.pageview_url as next_pageview_url
from sessions_w_next_pageview_id
    left join website_pageviews
    on website_pageviews.website_pageview_id= sessions_w_next_pageview_id.min_next_pageview_id;
    
-- step 4 : summarize the data and analyze the pre vs post periods

select 
     time_period,
     count(distinct website_session_id) as sessions,
     count(distinct case when next_pageview_url is not null then website_session_id else null end) as w_next_pg,
     count(distinct case when next_pageview_url is not null then website_session_id else null end)/
     count(distinct website_session_id) as pct_w_next_page,
     count(distinct case when next_pageview_url = '/the-original-mr-fuzzy' then website_session_id else null end ) as to_mrfuzzy,
     count(distinct case when next_pageview_url = '/the-original-mr-fuzzy' then website_session_id else null end )/
     count(distinct website_session_id) as pct_to_mrfuzzy,
     count(distinct case when next_pageview_url = '/the-forever-love-bear' then website_session_id else null end ) as to_lovebear,
     count(distinct case when next_pageview_url = '/the-forever-love-bear' then website_session_id else null end )/
     count(distinct website_session_id) as pct_to_lovebear
     from sessions_w_next_pageview_url
     group by time_period;
     

/* management is looking for the conversion funnel for both the product ' product page to conversion',
   also looking for the comparison between the two conversion funnels, for all website traffic.
   date limit */
   
  -- step 1 select all pageviews for relevent sessions
  -- step 2 figure out which pageview urls to look for 
  -- step 3 pull all pageviews and identfy the funnel steps
  -- step 4 create the session-level conversion funnel view
  -- step 5 aggregate the data to assess funnel performance
  
  
  
  -- step 1
 create temporary table sessions_seeing_product_pages 
  select website_session_id,
         website_pageview_id,
         pageview_url as product_page_seen
from website_pageviews
where created_at < '2013-04-10' -- date when request came in
  and created_at > '2013-01-06' -- product 2 launch 
  and pageview_url in ('/the-original-mr-fuzzy','/the-forever-love-bear');
         
   
 -- step 2 finding the  right pageview_urls to build the funnels

select 
     distinct website_pageviews.pageview_url
     from sessions_seeing_product_pages
     left join website_pageviews
     on website_pageviews.website_session_id=sessions_seeing_product_pages.website_session_id
     and website_pageviews.website_pageview_id > sessions_seeing_product_pages.website_pageview_id;
 
-- we'll look at the inner query first to look the pageview-level result 
-- then, turn it into a subquery and make it the summery with flags
-- step 3
select 
     sessions_seeing_product_pages.website_session_id,
     sessions_seeing_product_pages.product_page_seen,
     case when pageview_url = '/cart' then 1 else 0 end as  cart_page,
     case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
     case when pageview_url = '/billing-2' then 1 else 0 end as billing_page,
     case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from sessions_seeing_product_pages
left join website_pageviews
    on website_pageviews.website_session_id= sessions_seeing_product_pages.website_session_id
    and website_pageviews.website_pageview_id > sessions_seeing_product_pages.website_pageview_id
order by sessions_seeing_product_pages.website_session_id,
         website_pageviews.created_at;
 
 -- step 4
 create temporary table session_product_level_made_it_flags         
select 
     website_session_id,
     case when product_page_seen = '/the-original-mr-fuzzy' then 'mrfuzzy'
          when product_page_seen = '/the-forever-love-bear' then 'lovebear'
          else 'null'
          end as product_seen, 
          max(cart_page) as cart_made_it,
          max(shipping_page) as shipping_made_id,
          max(billing_page) as billing_made_it,
          max(thankyou_page) as thankyou_made_it
         from ( select 
     sessions_seeing_product_pages.website_session_id,
     sessions_seeing_product_pages.product_page_seen,
     case when pageview_url = '/cart' then 1 else 0 end as  cart_page,
     case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
     case when pageview_url = '/billing-2' then 1 else 0 end as billing_page,
     case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from sessions_seeing_product_pages
left join website_pageviews
    on website_pageviews.website_session_id= sessions_seeing_product_pages.website_session_id
    and website_pageviews.website_pageview_id > sessions_seeing_product_pages.website_pageview_id
order by sessions_seeing_product_pages.website_session_id,
         website_pageviews.created_at ) as pageview_level
group by website_session_id,
        case when product_page_seen = '/the-original-mr-fuzzy' then 'mrfuzzy'
          when product_page_seen = '/the-forever-love-bear' then 'lovebear'
          else 'null'
          end;
          
          
-- final output part 1
-- step 5
select 
product_seen,
count(distinct website_session_id) as sessions,
count(distinct case when cart_made_it =1 then website_session_id else null end) as to_cart,
count(distinct case when shipping_made_id =1 then website_session_id else null end) as to_shipping,
count(distinct case when billing_made_it =1 then website_session_id else null end ) as to_billing,
count(distinct case when thankyou_made_it=1 then website_session_id else null end ) as to_thankyou
from session_product_level_made_it_flags
group by product_seen;      
          
 -- final output clickthrough rate         
 select 
 product_seen,
 count(distinct case when cart_made_it =1 then website_session_id else null end)/
 count(distinct website_session_id) as product_page_click_rt,
 count(distinct case when shipping_made_id =1 then website_session_id else null end)/
  count(distinct case when cart_made_it =1 then website_session_id else null end) as cart_click_rt,
  count(distinct case when billing_made_it =1 then website_session_id else null end )/
  count(distinct case when shipping_made_id =1 then website_session_id else null end) as shipping_click_rt,        
  count(distinct case when thankyou_made_it=1 then website_session_id else null end )/        
  count(distinct case when billing_made_it =1 then website_session_id else null end ) as billing_click_rt
  from session_product_level_made_it_flags
  group by product_seen; 
  
  
 -- cross sell analysis
 
  -- step 1 Identify the relevent cart page views and their sessions
  -- step 2 See which of those  cart sessions clicked through to the shipping page
  -- step 3 find the orders associated with the cart sessions Analyze  product purchased ,Aov
  -- step 4 Aggregate and analyze a summary of our findings
  
  -- step 1
  create temporary table session_seeing_cart
  select 
     case when created_at < '2013-09-25' then 'A.pre_cross_sell'
     
          when created_at >= '2013-01-06' then 'B.post_cross_sell'
          else 'null'
          end
          as time_period,
          website_session_id as cart_session_id,
          website_pageview_id as cart_pageview_id
          from website_pageviews
          where created_at between '2013-08-25' and '2013-10-25'
             and pageview_url ='/cart';
  
  
create temporary table cart_sessions_seeing_another_page
    select session_seeing_cart.time_period,
         session_seeing_cart.cart_session_id,
         min(website_pageviews.website_pageview_id) as pv_id_after_cart
from session_seeing_cart
left join website_pageviews
on website_pageviews.website_session_id=session_seeing_cart.cart_session_id
and website_pageviews.website_pageview_id > session_seeing_cart.cart_pageview_id
group by 
    session_seeing_cart.time_period,
    session_seeing_cart.cart_session_id
having min(website_pageviews.website_pageview_id) is not null;
  
create temporary table pre_post_sessions_orders  
select 
     time_period,
     cart_session_id,
     order_id,
     items_purchased,
     price_usd
from session_seeing_cart
inner join orders
on orders.website_session_id= session_seeing_cart.cart_session_id;

 -- first we'll look at this select statement 
 -- then we'll turn into a subquery
 
 select session_seeing_cart.time_period,
        session_seeing_cart.cart_session_id,
        case when cart_sessions_seeing_another_page.cart_session_id is null then 0 else 1 end as clicked_to_another_page,
        case when pre_post_sessions_orders.order_id is null then 0 else 1 end as placed_order,
        pre_post_sessions_orders.items_purchased,
        pre_post_sessions_orders.price_usd
from session_seeing_cart
     left join cart_sessions_seeing_another_page
     on session_seeing_cart.cart_session_id = cart_sessions_seeing_another_page.cart_session_id
     left join pre_post_sessions_orders
     on session_seeing_cart.cart_session_id=pre_post_sessions_orders.cart_session_id
order by cart_session_id ;

  
  
  select 
  time_period,
  count(distinct cart_session_id) as cart_sessions,
  sum(clicked_to_another_page) as clickthroughs,
  sum(clicked_to_another_page)/ count(distinct cart_session_id) as cart_ctr,
  sum(placed_order) as orders_plased,
  sum(items_purchased) as product_purchased,
  sum(items_purchased)/sum(placed_order) as product_per_orders,
  sum(price_usd) as revenue,
  sum(price_usd)/sum(placed_order) as aov,
  sum(price_usd)/count(distinct cart_session_id) as rev_per_cart_session
  from( select session_seeing_cart.time_period,
        session_seeing_cart.cart_session_id,
        case when cart_sessions_seeing_another_page.cart_session_id is null then 0 else 1 end as clicked_to_another_page,
        case when pre_post_sessions_orders.order_id is null then 0 else 1 end as placed_order,
        pre_post_sessions_orders.items_purchased,
        pre_post_sessions_orders.price_usd
from session_seeing_cart
     left join cart_sessions_seeing_another_page
     on session_seeing_cart.cart_session_id = cart_sessions_seeing_another_page.cart_session_id
     left join pre_post_sessions_orders
     on session_seeing_cart.cart_session_id=pre_post_sessions_orders.cart_session_id
order by cart_session_id) as full_data
group by time_period;


-- protfolio expension analysis

/* On december 12 th 2013 company has launched a third product, pull out the per-post analysis comparing the 
month before vs the month after in terms of session-to-order conversion rate,Aov, products per order,
and revenue per session 
date limit */

select 
case 
    when website_sessions.created_at < '2013-12-12' then 'A.Pre_birthday_bear'
    when website_sessions.created_at >= '2013-12-12' then 'B.Post_Birthday_bear'
    else 'null'
    end as time_period,
count(distinct website_sessions.website_session_id) as sessions,
count(distinct orders.order_id) as orders,
count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as conv_rate,
sum(orders.price_usd) as total_revenue,
sum(orders.items_purchased) as total_products_sold,
sum(orders.price_usd)/ count(distinct orders.order_id) as average_order_value,
sum(orders.items_purchased)/count(distinct orders.order_id) as products_per_order,
sum(orders.price_usd)/count(distinct website_sessions.website_session_id) as revenue_per_session
from website_sessions
left join orders
on orders.website_session_id=website_sessions.website_session_id

where website_sessions.created_at between '2013-11-12' and '2014-01-12'
group by 1 ;

-- product refund analysis
/* pull out monthly product refund rates, by product, and conform our quality issues now fixed?*/

select 
     year(order_items.created_at) as yr,
     month(order_items.created_at) as mo,
     count(distinct case when product_id= 1 then order_items.order_item_id else null end) as p1_orders,
     count(distinct case when product_id= 1 then order_item_refunds.order_item_id else null end)/
     count(distinct case when product_id= 1 then order_items.order_item_id else null end) as p1_refund_rt,
     count(distinct case when product_id= 2 then order_items.order_item_id else null end) as p2_orders,
	 count(distinct case when product_id= 2 then order_item_refunds.order_item_id else null end)/
     count(distinct case when product_id= 2 then order_items.order_item_id else null end) as p2_refund_rt,
     count(distinct case when product_id= 3 then order_items.order_item_id else null end) as p3_orders,
     count(distinct case when product_id= 3 then order_item_refunds.order_item_id else null end)/
     count(distinct case when product_id= 3 then order_items.order_item_id else null end) as p3_refund_rt,
     count(distinct case when product_id= 4 then order_items.order_item_id else null end) as p4_orders,
     count(distinct case when product_id= 4 then order_item_refunds.order_item_id else null end)/
     count(distinct case when product_id= 4 then order_items.order_item_id else null end) as p4_refund_rt
from order_items
   left join order_item_refunds
       on order_items.order_item_id=order_item_refunds.order_item_id
where order_items.created_at < '2014-10-15'
group by 1,2 ;




