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


 /* finding top entey pages date limit 2012-06-12 */

/* step 1 finding min_pageview
   step 2 find the url the coustomer saw on thst min_pageview */
create temporary table min_pageviews
SELECT 
    website_session_id,
    MIN(website_pageview_id) AS min_pageview_id
FROM
    website_pageviews
WHERE
    created_at < '2012-06-12'
GROUP BY website_session_id;
      
      
SELECT 
    website_pageviews.pageview_url AS landing_page,
    COUNT(DISTINCT min_pageviews.website_session_id) AS sessions
FROM
    min_pageviews
        LEFT JOIN
    website_pageviews ON website_pageviews.website_pageview_id = min_pageviews.min_pageview_id
GROUP BY landing_page
ORDER BY sessions DESC;     
