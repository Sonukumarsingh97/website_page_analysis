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



/* web_page bounce rate analysis */

/* step 1 find the first_pageview_id for relevent sessions
   step 2 identify the landing page for each session
   step 3 counting the pageview for each session to identify the bounced session 
   step 4 summerizing the count of session and bounced session */


/* step 1 find the first pageview id for relevent session*/

create temporary table first_pageviews
select website_pageviews.website_session_id,
min(website_pageviews.website_pageview_id) as min_pageview_id
from website_pageviews
where created_at < '2012-06-14' 
group by website_pageviews.website_session_id;


/* step 2 identify the landing page for each session*/


create temporary table sessions_w_home_landing_page
SELECT 
    first_pageviews.website_session_id,
    website_pageviews.pageview_url AS landing_page
FROM
    first_pageviews
        LEFT JOIN
    website_pageviews ON website_pageviews.website_session_id = first_pageviews.website_session_id
WHERE
    website_pageviews.pageview_url = '/home'; 

    
/*  step 3 counting the pageview for each session to identify the bounced session */


create temporary table bounced_sessions     
SELECT 
    sessions_w_home_landing_page.website_session_id,
    sessions_w_home_landing_page.landing_page,
    COUNT(website_pageviews.website_pageview_id) AS count_of_pageview
FROM
    sessions_w_home_landing_page
        LEFT JOIN
    website_pageviews ON sessions_w_home_landing_page.website_session_id = website_pageviews.website_session_id
GROUP BY sessions_w_home_landing_page.website_session_id , sessions_w_home_landing_page.landing_page
HAVING COUNT(website_pageviews.website_pageview_id) = 1;
       
       
  /* step 4 summerizing the count of session and bounced session */
     
       
  SELECT 
    sessions_w_home_landing_page.landing_page AS landing_page,
    COUNT(DISTINCT sessions_w_home_landing_page.website_session_id) AS sessions,
    COUNT(DISTINCT bounced_sessions.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT bounced_sessions.website_session_id) / COUNT(DISTINCT sessions_w_home_landing_page.website_session_id) AS bounce_rate
FROM
    sessions_w_home_landing_page
        LEFT JOIN
    bounced_sessions ON sessions_w_home_landing_page.website_session_id = bounced_sessions.website_session_id
GROUP BY landing_page;
