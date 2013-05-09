Files Provided
--------------
* processTweets.rb -  a short script to gather tweets and calculate the
					misspelling frequency of each users
* twitter_misspell.R - a short set of R commands to visualise the data.
* misspell_freqs.csv - a csv file of twitter user misspelling frequencies
					   from my final run of the processTweets.rb code
					   provided here as each time the code is run you'll
					   generate slightly different results	
* histogram.png	   - a histogram of misspelling frequency distributions
				     (pale blue - London users; dark blue - Exeter users)
Installation
------------

Assuming *nix, you will need to install the json and raspell ruby gems. You may
also need to install the aspell-dev library if you don't already have that.

`> gem install json`

`> gem install raspell`
					
Usage
-----
`> processTweets.rb`

This will output a file misspell_freqs.csv

Next start R in the directory containing the misspell\_freqs.csv file and execute
the commands one by one. Alternative load the .R file, the downside of that is
that you won't see the means that it calculates. Comments in the R file indicate
the average misspelling frequency in the misspell_freqs.csv file

Results
-------
The calculated mean misspelling frequency rate is for London users is 0.23
And the calculated mean misspelling frequency rate is for Exeter users is 0.18
Where 0 represents no misspellings and 1 represents all words in all tweets are
misspelt.

This initially indicates that London twitter users have a greater rate of 
misspelling than Exeter users. However the provided histogram (histogram.png) 
indicates that the London users are affected by a more populated long tail of 
many users classified as producing poor spelling. Given the bulk of the
distribution is is likely that the out lying extreme values should no be 
taken in to account, and we might disregard users whose misspelling frequency is
greater than 0.4. Take this in to account the body of the misspelling 
distributions indicate that the misspelling rate among London and Exeter users 
is likely about the same. Although the main body of the distribution for 
London users (pale blue) is shifted marginally to the right which may indicate 
that there is a real increase in misspellings among London users. However with 
this relative small one-time sampling of the data it is hard to see if this 
shift is statistically significant. With 10 times the users and data collected 
over many days significance in any difference could be more rigorously tested.

Implementation
--------------
The initial design decision was to go with ruby to do that data processing
because it is quick and clean and because I wanted to do something new with
ruby. The script is built around a simple ProcessTwitter class that's made up
of a handful of methods. Walking through them in turn;

* Initialize()

A fairly basic class constructor, it initialises the data structures the tweet
data will be held in and the URIs for the twitter queries.  Importantly it
also holds the geographical regions which are defined as London and Exeter. 
These are approximate centroids for the centre of each city and a a radius around
that centroid which approximates the area of the city.

* getLocationTweets()

This small method calls a helper function, callLocationSearch(), for both the 
Exeter and London searches. The principal idea here is to collect 2 pages of
pages of recent tweets from each region and harvest the user names of users from
Exeter and London. The function can gather any arbitrary number of pages if a 
large study was required

We could of course just stop here and analyse these pages of tweets but it seems
more robust to actually compare a better sampled history of how much misspelling
actual users engage in.

* callLocationSearch()

This helper method does the actual heavy lifting of calling the twitter api
and pushing the user ids to a hash table of users, which has the benefit of
giving us a non-redundant list of users for each location.

As this is something of a toy example what isn't implemented is any code that 
handles http errors, in this instance no attempt is made to retry a failed
request we just pass on and skip collection the data. The assumption is a couple
of failed requests won't significantly effect the future distribution of any 
data gathered. Additionally nothing is done to respect twitter's unauthenticated
search api limit of 150 requests per hour. The commented out sleep() call
would respect that but probably isn't the most robust way to handle this.

* getUserTweets()

With a non-redundant list of users from Exeter and London in hand this function
calls a helper method, collectTweets(), to get 2 pages of each user's tweets. 
Ideally this should gather about 200 tweets per person. This function can 
gather any arbitrary number of pages of tweets if a large study was required

* collectTweets()

This actually gathers the tweets for each user and attempts to clean each 
tweet in to an string that can be analysed. hashtags, twitter user names, common
URI types, numbers and some confounding punctuation. Probably not the most
robust way to clean text and correctly handle all eventualities but ample for
this example

* calculateMisspellingRates()

Walks through each user's tweets and using the ruby binding to *nix aspell
(raspell) calculates the frequency of misspelling; the number of 
misspelled words in a tweet divided by the number of words in that tweet. Then
for each user calculates the average misspelling frequency for their tweets.

One issue here that it doesn't handle valid non-dictionary words such as common
slang or l33t speak. The assumption here is that the number of dictionary words
tested will be of sufficient magnitude to make this noise insignificant.

* Data Output

Lastly the script outputs a csv file (misspell_freqs.csv) of the user
misspelling frequencies for use in R. I've included the version I generated 
as the code just grabs recent tweets from the twitter api so each time it is
run the results may be somewhat different those described.

* twitter_misspell.R

This simple R script loads the misspell_freqs.csv file and then calculates the 
mean misspelling frequency for London and Exeter users and then outputs a 
histogram png of the misspelling frequency distributions (pale blue for London 
and darker blue for Exeter)
