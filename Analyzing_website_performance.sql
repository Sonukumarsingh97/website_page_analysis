/* Here we will analyze web page performance--
 1) most viewed page 
 2) landing page
 3) Bounce rate  
 4) conversion funnel */

/* 1) most viewed page, Date limit 2012-06-09 */

select count(distinct website_pageview_id) as pageview,
      pageview_url
      from website_pageviews
      where created_at < '2012-06-09' 
      group by pageview_url
      order by pageview desc;
