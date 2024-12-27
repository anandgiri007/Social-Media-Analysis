--                                          //////*OBJECTIVE QUESTIONS*//////

-- obj_2_____What is the distribution of user activity levels (e.g., number of posts, likes, comments) across the user base?

select count(*) as total_posts from photos;  -- 257
select count(*) as total_likes from likes;   -- 8782
select count(*) as total_comments from comments;  -- 7488

-- obj_3_____Calculate the average number of tags per post (photo_tags and photos tables).
SELECT AVG(tag_count) AS avg_tags_per_post
FROM (SELECT photo_id, COUNT(tag_id) AS tag_count
       FROM photo_tags
	   GROUP BY photo_id
) AS tag_counts;

-- obj_4_____Identify the top users with the highest engagement rates (likes, comments) on their posts and rank them.

SELECT u.id AS user_id,u.username,
       COALESCE(engagement.total_likes, 0) AS total_likes,
       COALESCE(engagement.total_comments, 0) AS total_comments,
       COALESCE(engagement.total_likes, 0) + COALESCE(engagement.total_comments, 0) AS total_engagement,
       RANK() OVER (ORDER BY COALESCE(engagement.total_likes, 0) + COALESCE(engagement.total_comments, 0) DESC) AS rnk
FROM users u
LEFT JOIN (
    SELECT p.user_id,COUNT(DISTINCT l.user_id) AS total_likes,       -- Counting distinct users who liked a photo
           COUNT(DISTINCT c.id) AS total_comments           -- Counting distinct comments
    FROM photos p
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id
) AS engagement ON u.id = engagement.user_id
ORDER BY total_engagement DESC
limit 20;


-- obj_5_____ Which users have the highest number of followers and followings?

SELECT u.id AS user_id, u.username,
COUNT(DISTINCT f1.follower_id) AS total_followers,
COUNT(DISTINCT f2.followee_id) AS total_followings
FROM users u
LEFT JOIN follows f1 ON f1.followee_id = u.id
LEFT JOIN follows f2 ON f2.follower_id = u.id
GROUP BY u.id, u.username
ORDER BY total_followers, total_followings;

-- obj_6____Calculate the average engagement rate (likes, comments) per post for each user.

-- Here My approach is
-- At first i created a CTE Post_Engagement for getting the total counts of likes and comments grouping user_id and id.(Tables used- Likes,Comments Photos and Users)
-- total counts are necessary to calculate the average enagagement rate per post for each user.
-- A CTE User_Posts to get the total posts for each user_id.
-- In the main query needed columns has been selected along with the function to calculate total engagement rate for each user. 
-- Used a case statement to get the average engagement rate if any user has a post. if any user doesnt have any post then it ends.

WITH Post_Engagement AS ( 
    -- Count likes and comments for each post
    SELECT 
        p.user_id,
        p.id AS photo_id,
        COALESCE(COUNT(DISTINCT l.user_id), 0) AS total_likes,
        COALESCE(COUNT(DISTINCT c.id), 0) AS total_comments
    FROM photos p
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id, p.id
),
User_Posts AS ( 
    -- Count the total number of posts for each user
    SELECT user_id, COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id
)
SELECT 
    u.username,
    up.total_posts,
    -- Calculate total engagement (likes + comments) for each user
    COALESCE(SUM(pe.total_likes + pe.total_comments), 0) AS total_engagement, 
    -- Calculate average engagement rate per post
    CASE                                                 
        WHEN up.total_posts > 0 THEN 
            COALESCE(SUM(pe.total_likes + pe.total_comments), 0) * 1.0 / up.total_posts
        ELSE 0 
    END AS average_engagement_rate_per_post
FROM users u
LEFT JOIN Post_Engagement pe ON u.id = pe.user_id
LEFT JOIN User_Posts up ON u.id = up.user_id
GROUP BY u.id, u.username, up.total_posts
ORDER BY u.username;


-- obj_7_____Get the list of users who have never liked any post (users and likes tables)

-- Approach is simple, we have to check wether any id from user table is not present in likes table.
-- By doing this we will get that the users that are not present in likes table haven't liked any post.
select u.id,u.username 
from users u 
left join likes l 
on u.id=l.user_id
where l.user_id is NULL; -- this checks for the presence of non matching rows with users table.

-- obj_8_____How can you leverage user-generated content (posts, hashtags, photo tags) to create more personalized and engaging ad campaigns?

-- The query is counting how many photos are associated with each tag, which gives insight into how popular each tag is.
-- I have also ranked each tag as per their popularity.

select tag_id,t.tag_name,
count(pt.photo_id) as total_posts,
dense_rank() over(order by count(pt.photo_id) desc) as ranking
from photo_tags pt 
join tags t 
on pt.tag_id=t.id 
group by t.tag_name
order by total_posts desc;

-- obj_9_____Are there any correlations between user activity levels and specific content types (e.g., photos, videos, reels)?
-- _________ How can this information guide content creation and curation strategies?

SELECT u.id AS user_id, u.username,
       COUNT(DISTINCT p.id) AS total_photos,
       COUNT(DISTINCT l.user_id) AS total_likes,
       COUNT(DISTINCT c.user_id) AS total_comments
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY u.id, u.username
ORDER BY total_photos DESC;


-- obj_10_____Calculate the total number of likes, comments, and photo tags for each user.
 
-- for calculating userwise likes, comments and photo_tags we need to join the following tables
-- users,likes,comments,photos,photo_tags

SELECT p.user_id,u.username,
    COALESCE(COUNT(DISTINCT l.user_id), 0) AS total_likes,       -- Count of distinct users who liked the user's photos
    COALESCE(COUNT(DISTINCT c.id), 0) AS total_comments,          -- Count of distinct comments on the user's photos
    COALESCE(COUNT(DISTINCT pt.tag_id), 0) AS total_tags          -- Count of distinct tags on the user's photos
FROM photos p
LEFT JOIN likes l ON p.id = l.photo_id                             -- Join to count likes per photo
LEFT JOIN comments c ON p.id = c.photo_id                         -- Join to count comments per photo
LEFT JOIN photo_tags pt ON p.id = pt.photo_id                     -- Join to count tags per photo
LEFT JOIN users u ON p.user_id = u.id                              -- Join to get the username
GROUP BY p.user_id, u.username
ORDER BY total_likes DESC;                                               -- Order by total likes



-- obj_11_____Rank users based on their total engagement (likes, comments, shares) over a month.

SELECT u.id AS user_id,u.username,
COALESCE(engagement.total_likes, 0) AS total_likes,
COALESCE(engagement.total_comments, 0) AS total_comments,
COALESCE(engagement.total_likes, 0) + COALESCE(engagement.total_comments, 0) AS total_engagement,
RANK() OVER(ORDER BY COALESCE(engagement.total_likes, 0) + COALESCE(engagement.total_comments, 0) DESC) AS ranking
FROM users u
LEFT JOIN (SELECT p.user_id,
        COUNT(DISTINCT l.photo_id) AS total_likes,
        COUNT(DISTINCT c.user_id) AS total_comments
    FROM photos p
    LEFT JOIN likes l ON p.id = l.photo_id AND l.created_at >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
    LEFT JOIN comments c ON p.id = c.photo_id AND c.created_at >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)  
    GROUP BY p.user_id
) AS engagement 
ON u.id = engagement.user_id
ORDER BY total_engagement DESC;



-- obj_12_____Retrieve the hashtags that have been used in posts with the highest average number of likes.
--            Use a CTE to calculate the average likes for each hashtag first.

WITH PhotoLikes AS (
    SELECT p.id AS photo_id,COUNT(l.user_id) AS total_likes
    FROM photos p
    LEFT JOIN likes l ON p.id = l.photo_id
    GROUP BY p.id
),
TagLikes AS (
    SELECT t.id,t.tag_name,AVG(pl.total_likes) AS avg_likes
    FROM tags t
    JOIN photo_tags pt ON t.id = pt.tag_id
    JOIN PhotoLikes pl ON pt.photo_id = pl.photo_id
    GROUP BY t.id, t.tag_name
)
SELECT tag_name,avg_likes
FROM TagLikes
ORDER BY avg_likes DESC;

-- obj_13_____Retrieve the users who have started following someone after being followed by that person


--                                       //////*SUBJECTIVES*//////

--                                      //////*Queries needed to answer subjective question and insights*//////
-- ///////*SUBJECTIVE 1*////////

WITH User_Engagement AS (
    -- Calculate total likes, comments, and tags per user
    SELECT u.id AS user_id,u.username,
           COALESCE(COUNT(DISTINCT l.user_id), 0) AS total_likes,     -- Count distinct users who liked
           COALESCE(COUNT(DISTINCT c.id), 0) AS total_comments,        -- Count distinct comments
           COALESCE(COUNT(DISTINCT pt.tag_id), 0) AS total_tags        -- Count distinct tags
    FROM users u
    LEFT JOIN photos p ON u.id = p.user_id
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    LEFT JOIN photo_tags pt ON p.id = pt.photo_id
    GROUP BY u.id, u.username
)
SELECT user_id, username,total_likes,total_comments,total_tags,
       -- Calculate total engagement (likes + comments + tags)
       (total_likes + total_comments + total_tags) AS total_engagement,
       -- Rank users based on total engagement
       DENSE_RANK() OVER (ORDER BY (total_likes + total_comments + total_tags) DESC) AS engagement_rank
FROM User_Engagement
ORDER BY engagement_rank;

--  //////*SUBJECTIVE 2*//////

WITH User_Engagement AS (
    -- Calculate total likes, comments, and tags per user
    SELECT u.id AS user_id,u.username,
           COALESCE(COUNT(DISTINCT l.user_id), 0) AS total_likes,     -- Count distinct users who liked
           COALESCE(COUNT(DISTINCT c.id), 0) AS total_comments,        -- Count distinct comments
           COALESCE(COUNT(DISTINCT pt.tag_id), 0) AS total_tags        -- Count distinct tags
    FROM users u
    LEFT JOIN photos p ON u.id = p.user_id
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    LEFT JOIN photo_tags pt ON p.id = pt.photo_id
    GROUP BY u.id, u.username
)
SELECT user_id, username,total_likes,total_comments,total_tags,
       -- Calculate total engagement (likes + comments + tags)
       (total_likes + total_comments + total_tags) AS total_engagement
       
FROM User_Engagement
where (total_likes + total_comments + total_tags)=0; 

SELECT u.id AS user_id, u.username, COUNT(p.id) AS total_posts -- count of posts of each user
FROM users u 
LEFT JOIN photos p ON u.id = p.user_id 
GROUP BY u.id, u.username 
ORDER BY total_posts DESC;




-- /////SUBJECTIVE 3*//////

SELECT pt.tag_id,t.tag_name, COUNT(l.photo_id) AS total_likes  -- total likes per hashtag
FROM photo_tags pt
JOIN likes l ON pt.photo_id = l.photo_id
join tags t on t.id=pt.tag_id
GROUP BY pt.tag_id;

SELECT pt.tag_id,t.tag_name, COUNT(c.photo_id) AS total_comments -- comments per hashtag
FROM photo_tags pt
JOIN comments c ON pt.photo_id = c.photo_id
join tags t on t.id=pt.tag_id
GROUP BY pt.tag_id;

SELECT pt.tag_id,t.tag_name, COUNT(pt.photo_id) AS total_posts  -- total_posts per hashtag
FROM photo_tags pt
join tags t on t.id=pt.tag_id
GROUP BY pt.tag_id
order by total_posts desc;

-- final query to get the total engagement(likes+comments/total_posts)

SELECT t.tag_name,COALESCE(eng.total_engagement, 0) AS total_engagement,p.total_posts,
    CASE WHEN p.total_posts > 0 THEN eng.total_engagement / p.total_posts ELSE 0 END AS engagement_rate
FROM tags t
LEFT JOIN (
    SELECT pt.tag_id,COALESCE(SUM(l.total_likes), 0) + COALESCE(SUM(c.total_comments), 0) AS total_engagement
    FROM photo_tags pt
    LEFT JOIN (SELECT photo_id, COUNT(*) AS total_likes FROM likes GROUP BY photo_id) l ON pt.photo_id = l.photo_id
    LEFT JOIN (SELECT photo_id, COUNT(*) AS total_comments FROM comments GROUP BY photo_id) c ON pt.photo_id = c.photo_id
    GROUP BY pt.tag_id
) eng ON t.id = eng.tag_id
LEFT JOIN (
    SELECT pt.tag_id, COUNT(pt.photo_id) AS total_posts
    FROM photo_tags pt
    GROUP BY pt.tag_id
) p ON t.id = p.tag_id
ORDER BY engagement_rate DESC;

-- //////*SUBJECTIVE 4*//////

SELECT DAYOFWEEK(p.created_dat) AS post_day, -- Extracts the day of the week (1=Sunday, 7=Saturday)
	   EXTRACT(HOUR FROM p.created_dat) as post_hour,
       COUNT(DISTINCT p.id) AS total_photos,
       COUNT(DISTINCT l.user_id) AS total_likes,
       COUNT(DISTINCT c.id) AS total_comments,
       coalesce(COUNT(DISTINCT p.id),0)+ coalesce(COUNT(DISTINCT l.user_id),0)+coalesce(COUNT(DISTINCT c.user_id),0) as total_engagement
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY EXTRACT(HOUR FROM p.created_dat),DAYOFWEEK(p.created_dat)
ORDER BY total_engagement DESC;

-- //////*SUBJECTIVE 5*////// (users followers count and engagement rate-TOP 10)
WITH FollowerCounts AS (
    SELECT followee_id AS user_id,COUNT(DISTINCT follower_id) AS follower_count
    FROM follows
    GROUP BY followee_id
),
UserEngagement AS (
    SELECT p.user_id,(COUNT(DISTINCT l.user_id) + COUNT(DISTINCT c.id)) / NULLIF(COUNT(DISTINCT p.id), 0) AS engagement_rate
    FROM photos p
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id
)
SELECT 
    u.id AS user_id,
    u.username,
    fc.follower_count,
    ue.engagement_rate
FROM users u
JOIN FollowerCounts fc ON u.id = fc.user_id
JOIN UserEngagement ue ON u.id = ue.user_id
ORDER BY fc.follower_count desc, ue.engagement_rate desc
LIMIT 10; -- Only selecting the top influencers

--  //////*SUBJECTIVE 6*//////
-- gives the engagement rate of each hashtag
SELECT t.tag_name,COALESCE(eng.total_engagement, 0) AS total_engagement,p.total_posts,
    CASE WHEN p.total_posts > 0 THEN eng.total_engagement / p.total_posts ELSE 0 END AS engagement_rate
FROM tags t
LEFT JOIN (
    SELECT pt.tag_id,COALESCE(SUM(l.total_likes), 0) + COALESCE(SUM(c.total_comments), 0) AS total_engagement
    FROM photo_tags pt
    LEFT JOIN (SELECT photo_id, COUNT(*) AS total_likes FROM likes GROUP BY photo_id) l ON pt.photo_id = l.photo_id
    LEFT JOIN (SELECT photo_id, COUNT(*) AS total_comments FROM comments GROUP BY photo_id) c ON pt.photo_id = c.photo_id
    GROUP BY pt.tag_id
) eng ON t.id = eng.tag_id
LEFT JOIN (
    SELECT pt.tag_id, COUNT(pt.photo_id) AS total_posts
    FROM photo_tags pt
    GROUP BY pt.tag_id
) p ON t.id = p.tag_id
ORDER BY engagement_rate DESC;

-- ///////*SUBJECTIVE 8*///////

SELECT u.id AS user_id,u.username,COUNT(p.id) AS total_posts, 
    COALESCE(SUM(l.like_count), 0) AS total_likes, 
    COALESCE(SUM(c.comment_count), 0) AS total_comments, 
    COALESCE(SUM(l.like_count) + SUM(c.comment_count), 0) AS total_engagement
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN (SELECT photo_id, COUNT(*) AS like_count FROM likes GROUP BY photo_id) l ON p.id = l.photo_id
LEFT JOIN (SELECT photo_id, COUNT(*) AS comment_count FROM comments GROUP BY photo_id) c ON p.id = c.photo_id
GROUP BY u.id, u.username
HAVING total_engagement > 100 -- This threshold can be adjusted based on our criteria
ORDER BY total_engagement DESC;