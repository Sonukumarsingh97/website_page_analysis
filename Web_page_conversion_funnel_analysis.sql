/* conversion funnel analysis */

/*-- step 1: select all pageviews for relevent sessions
-- step 2: identefy each pageview as the specific funnel step
-- step 3: create the session-level conversion funnel view
-- step 4: aggregate the data to assess funnel performance */

-- step 1
 
 select website_sessions.website_session_id,
        website_pageviews.pageview_url,
        -- website_pageviews.created_at as pageview_created_at
        case when pageview_url ='/products' then 1 else 0 end as products_page,
        case when pageview_url ='/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_page,
        case when pageview_url = '/cart' then 1 else 0 end as cart_page,
        case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
        case when pageview_url = '/billing' then 1 else 0 end as billing_page,
        case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from website_sessions
    left join website_pageviews
         on website_pageviews.website_session_id=website_sessions.website_session_id
where website_sessions.utm_source='gsearch'
and website_sessions.utm_campaign='nonbrand'
and website_sessions.created_at > '2012-08-05'
and website_sessions.created_at < '2012-09-05'
order by
website_sessions.website_session_id,
website_pageviews.created_at;

/*-- step 2 
 -- create temporary table session_level_made_it_flags */
select website_session_id,
       max(products_page) as product_made_it,
       max(mrfuzzy_page) as mrfuzzy_made_it,
       max(cart_page) as cart_made_it,
       max(shipping_page) as shipping_made_it,
       max(billing_page) as billing_made_it,
       max(thankyou_page) as thankyou_made_it
from ( select website_sessions.website_session_id,
        website_pageviews.pageview_url,
        -- website_pageviews.created_at as pageview_created_at
        case when pageview_url ='/products' then 1 else 0 end as products_page,
        case when pageview_url ='/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_page,
        case when pageview_url = '/cart' then 1 else 0 end as cart_page,
        case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
        case when pageview_url = '/billing' then 1 else 0 end as billing_page,
        case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from website_sessions
    left join website_pageviews
         on website_pageviews.website_session_id=website_sessions.website_session_id
where website_sessions.utm_source='gsearch'
and website_sessions.utm_campaign='nonbrand'
and website_sessions.created_at > '2012-08-05'
and website_sessions.created_at < '2012-09-05'
order by
website_sessions.website_session_id,
website_pageviews.created_at) as pageview_level
group by website_session_id;


/*-- step 3 */
select 
     count(distinct website_session_id) as sessions,
     count(distinct case when product_made_it = 1 then website_session_id else null end ) as to_products,
     count(distinct case when mrfuzzy_made_it = 1 then website_session_id else null end ) as to_mrfuzzy,
     count(distinct case when cart_made_it = 1 then website_session_id else null end ) as to_cart,
     count(distinct case when shipping_made_it = 1 then website_session_id else null end ) as to_shipping,
     count(distinct case when billing_made_it =1 then website_session_id else null end ) as to_billing,
     count(distinct case when thankyou_made_it =1 then website_session_id else null end ) as to_thankyou
     
     from session_level_made_it_flags;

/*-- step 4 finel output  click rate */

select 
      count(distinct case when product_made_it = 1 then website_session_id else null end )/ count(distinct website_session_id) as lander_click_rt,
      count(distinct case when mrfuzzy_made_it = 1 then website_session_id else null end )/count(distinct case when product_made_it = 1 then website_session_id else null end ) as products_click_rt,
      count(distinct case when cart_made_it = 1 then website_session_id else null end )/count(distinct case when mrfuzzy_made_it = 1 then website_session_id else null end ) as mrfuzzy_click_rt,
      count(distinct case when shipping_made_it = 1 then website_session_id else null end )/count(distinct case when cart_made_it = 1 then website_session_id else null end ) as card_click_rt,
      count(distinct case when billing_made_it =1 then website_session_id else null end )/  count(distinct case when shipping_made_it = 1 then website_session_id else null end ) as shipping_click_rt,
      count(distinct case when thankyou_made_it =1 then website_session_id else null end )/ count(distinct case when billing_made_it =1 then website_session_id else null end ) as billing_click_rt
      
from session_level_made_it_flags;



/*-- A B split test for billing page conversion rate

-- first, finding out the starting point to frame the analysis. for that we need to find out first_pv_id for the billing-2 page.*/

select min(website_pageview_id) as first_pv_id
     from website_pageviews
     where pageview_url ='/billing-2';
-- first_pv_id for billing-2 = 53550

select website_pageviews.website_session_id,
       website_pageviews.pageview_url as billing_version_seen,
	   orders.order_id
from website_pageviews
left join orders
on orders.website_session_id = website_pageviews.website_session_id
where website_pageviews.website_pageview_id >= 53550 -- first pageview_id where test was live
and   website_pageviews.created_at < '2012-11-10' -- time when the management request came in.
and website_pageviews.pageview_url in('/billing', '/billing-2') ;


/*-- aggregate the data to assess the A B test of billing page.*/
       
select billing_version_seen,
   count(distinct website_session_id) as sessions,
   count(distinct order_id ) as orders,
   count(distinct order_id )/ count(distinct website_session_id) as billing_to_order_rt
   from(select website_pageviews.website_session_id,
       website_pageviews.pageview_url as billing_version_seen,
	   orders.order_id
from website_pageviews
left join orders
on orders.website_session_id = website_pageviews.website_session_id
where website_pageviews.website_pageview_id >= 53550 -- first pageview_id where test was live
and   website_pageviews.created_at < '2012-11-10' -- time when the management request came in.
and website_pageviews.pageview_url in('/billing', '/billing-2') ) as billing_sessions_w_orders
group by billing_version_seen;