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



/* A-B split test of landing page */

/* step 1) find out the first date and pageview_id when the first lander 2 get active
   step 2) find the first pageview id for each session
   step 3) cennect session with the landing page 
   step 4) count the pageview_id
   step 5) summarise the count by the landing page */
   
  /* step 1 */
 
 select website_pageview_id,
      min(created_at)
      from website_pageviews
      where pageview_url='/lander-1'
      group by 1 ;
      
 /* step 2 */
  create temporary table min_pageview
 select website_pageviews.website_session_id,
		min(website_pageview_id) as first_pageview
        from website_pageviews
		inner join website_sessions
        on website_pageviews.website_session_id=website_sessions.website_session_id
        where website_pageviews.website_pageview_id >=23504
        and website_sessions.created_at < '2012-07-28'
        and utm_source = 'gsearch'
        and utm_campaign = 'nonbrand'
        group by 1 ;
        
/* step 3 */ 
 create temporary table session_w_landing_page
select min_pageview.website_session_id,
      website_pageviews.pageview_url as landing_page
      from min_pageview 
      left join website_pageviews
      on  min_pageview.website_session_id=website_pageviews.website_session_id
      where website_pageviews.pageview_url IN ('/home', '/lander-1');
      
  /*step 4 */
  create temporary table bounced_session
 select session_w_landing_page.website_session_id,
        session_w_landing_page.landing_page,
        count(website_pageviews.website_pageview_id) as count_of_pageview
        from session_w_landing_page
        left join website_pageviews
        on session_w_landing_page.website_session_id= website_pageviews.website_session_id
        group by 1,2 
        having  count(website_pageviews.website_pageview_id)= 1;
        
        
/* step 5 */
select session_w_landing_page.landing_page as landing_pages,
       count(distinct session_w_landing_page.website_session_id) as sessions,
       count(distinct bounced_session.website_session_id) as bounced_sessions,
       count(distinct bounced_session.website_session_id)/
        count(distinct session_w_landing_page.website_session_id) as bounced_rate
       from session_w_landing_page
       left join bounced_session
       on bounced_session.website_session_id=session_w_landing_page.website_session_id
       group by 1;
       



/* landing page trend analysis */

/* step 1 finding the first website_pageview_id for relevent sessions 
   step 2 identifying the landing page of each session
   step 3 counting pageviews for each session,to identify "bounces"
   step 4 summarizing by week (bounce rate, sessions to each lander) */
   
/* step 1 and 3 */
create temporary table session_w_min_pv_id_and_view_count
select website_pageviews.website_session_id,
      min(website_pageviews.website_pageview_id) as first_pageview_id,
      count(website_pageviews.website_pageview_id) as count_pageviews
      from website_sessions
      left join website_pageviews
      on website_pageviews.website_session_id=website_sessions.website_session_id
      where website_sessions.created_at> '2012-06-01'
      and website_sessions.created_at<'2012-08-31'
      and website_sessions.utm_source= 'gsearch'
      and website_sessions.utm_campaign='nonbrand'
      group by website_sessions.website_session_id;
 
 /* step 2 */
 create temporary table sessions_w_counts_lander_and_created_at
select session_w_min_pv_id_and_view_count.website_session_id,
       session_w_min_pv_id_and_view_count.first_pageview_id,
       session_w_min_pv_id_and_view_count.count_pageviews,
       website_pageviews.pageview_url as landing_page,
       website_pageviews.created_at as session_created_at
       from session_w_min_pv_id_and_view_count
       left join website_pageviews
       on session_w_min_pv_id_and_view_count.website_session_id=website_pageviews.website_session_id
       where website_pageviews.pageview_url IN ('/home','/lander-1');
       
       
/* step 4 */

select -- yearweek(session_created_at) as year_week,
       min(date(session_created_at)) as week_start_date,
       -- count(distinct website_session_id) as total_session,
       count(distinct case when count_pageviews = 1 then website_session_id else null end ) as bounced_session,
       count(distinct case when count_pageviews = 1 then website_session_id else null end )/
	   count(distinct website_session_id) as bounced_rate,
       count(distinct case when landing_page = '/home' then website_session_id else null end) as home_session,
       count(distinct case when landing_page = '/lander-1' then website_session_id else null end) as lander_sessions
       from sessions_w_counts_lander_and_created_at
       group by 
       yearweek(session_created_at);








