#!/usr/local/bin/ruby

class ProcessTwitter

	require "pp"
	require "rubygems"
	require "json"
	require 'open-uri'
	require 'raspell'

	#initialise the class and provide a couple of arrays of locations for
	#the cities we're analysing
	def initialize
		@londonUsers = Hash.new
		@exeterUsers = Hash.new
		#build some anonymous hashes
		@londonTweets = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }
		@exeterTweets = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }
		@misspellingData = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }
		
		
		@london = "51.51051,-0.133767,15mi"
		@exeter = "50.71896,-3.532147,3mi"
		
		@geoTweetSearch = "http://search.twitter.com/search.json?rpp=100&geocode="
		@userTweetSearch = "http://search.twitter.com/search.json?rpp=100&q=from:"
		
	end
	
	#using the locations of london and exeter (and their v.approx radius) we'll grab
	#a unique list of users tweeting in that area
	def getLocationTweets(pages)
		#ok grab the user list request here, 
		for i in 1..pages
			#get London user list
			callLocationSearch(i,1)
			#get Exeter user list
			callLocationSearch(i,0)
		end
		
	end
	
	#Does the actual work of calling the twitter API
	#should also throttle this to wait 24 seconds after a request to not hit
	#the public limit
	def callLocationSearch(page,location)
		search = ''
		if location == 1
			search = @geoTweetSearch+@london+"&page="
		else
			search = @geoTweetSearch+@exeter+"&page="
		end
		puts "Getting Users: "+search+page.to_s
		
		begin
			contents = open(search+page.to_s) {|io| io.read}
		rescue Exception=>e
			#not really doing any with this exception other than moving on
			#with our lives
			puts "http request failed"
			next
		end
		#sleep(24)
		
		@parsedData = JSON.parse contents	
		@parsedData["results"].each do |tweet|
			if location == 1
				@londonUsers[tweet["from_user_id_str"]] = tweet["from_user"]
			else
				@exeterUsers[tweet["from_user_id_str"]] = tweet["from_user"]
			end
		end
	end
	
	#now for each user we'll get a recent history of their tweets
	#pretty ugly repeating the same block of code but we can handle that in refactoring. Notably 
	#should also throttle this to wait 24 seconds after a request to not hit the 
	#public limit
	def getUserTweets(pages)
		@londonUsers.keys.each do |uid|
			userName = @londonUsers[uid]
			collectTweets(uid,userName,pages,1)
			#break
		end
		
		@exeterUsers.keys.each do |uid|
			userName = @exeterUsers[uid]
			collectTweets(uid,userName,pages,0)
			#break
		end
	end
	
	def collectTweets(uid,userName,pages,location)
		for i in 1..pages
			search=@userTweetSearch+userName+"&page="+i.to_s
			puts "Getting Tweets: "+search
			begin
				contents = open(search) {|io| io.read}
			rescue Exception=>e
				puts "http request failed"
				next
			end
			#sleep(24)
			@parsedData = JSON.parse contents
			
			@parsedData["results"].each_with_index do |tweet,index|
				tweet_text = tweet["text"]
				#skip trivial retweets that may not come from the user, is there a better
				#way to do this test? Couldn't see it in the tweet contents
				if tweet_text =~ /RT|MT/
					next
				end
				
				#clean the text up a little
				#remove other user id's, hashtags and URIs
				tweet_text.gsub!(/@\S+/,'')
				tweet_text.gsub!(/#\S+/,'')
				tweet_text.gsub!(/http:\S+/,'')
				tweet_text.gsub!(/ftp:\S+/,'')
				#non complete list of URI endings that should probably be expanded
				tweet_text.gsub!(/\S+\.com/,'')
				tweet_text.gsub!(/\S+\.uk/,'')
				tweet_text.gsub!(/\S+\.org/,'')
				
				tweet_text.downcase!
				#lose the common punctuation and numbers
				tweet_text.gsub!(/[0-9]/, ' ')
				tweet_text.gsub!(/[-!\?"\.,:;&\)\(]/, ' ')
				tweet_text.gsub!(/^\s+/, '')
				
				if location==1
					@londonTweets[uid][index]=tweet_text
				else
					@exeterTweets[uid][index]=tweet_text
				end
			end	
		end
	end
	
	#loop through each user and work out their misspelling frequency per tweet and then the average
	#misspelling frequency for all their tweets 
	def calculateMisspellingRates
		@londonTweets.keys.each do |uid|
			@misspellingData["LONDON"][uid] = calculateAveMisspellFreq(@londonTweets[uid])
		end
		
		@exeterTweets.keys.each do |uid|
			@misspellingData["EXETER"][uid] = calculateAveMisspellFreq(@exeterTweets[uid])
		end
		
		return @misspellingData
	end
	
	def calculateAveMisspellFreq(tweetList)
		freqTotal = 0
		tweetCount = 0
		tweetList.keys.each do |tweet_id|
			tweetCount+=1
			strLength = tweetList[tweet_id].split(/\s+/).length
			incorrect = testSpelling(tweetList[tweet_id])
			if incorrect > 0 && strLength > 0
				incorrect_freq = incorrect.to_f/strLength.to_f
				freqTotal+=incorrect_freq
			end
		end
			
		#only calculate the frequency if there are tweets and nothing went wrong 
		#count the frequencies
		if tweetCount > 0 && freqTotal > 0
			return freqTotal.to_f/tweetCount.to_f
		end
	end
	
	def testSpelling(string)
		speller = Aspell.new("en_UK")
		incorrect_count=0
		string.split(/\s+/).each do |word|
			if !speller.check(word)
				incorrect_count+=1
			end	
		end
		return incorrect_count
	end
	
end
puts "Initialising"
twitter_data = ProcessTwitter.new()
#we'll grab 2 pages of 100 tweets each to get a sample of users
puts "Getting user list"
twitter_data.getLocationTweets(3)

#now we'll attempt to grab 200 tweets from each user
puts "Getting User Tweets"
twitter_data.getUserTweets(2)

puts "Calculating mispelling Frequncies"
mispellingFrequencies = twitter_data.calculateMisspellingRates

puts "Outputting Data"
fhVectOut = File.open("misspell_freqs.csv", 'w')
fhVectOut.syswrite("uid,location,misspell_freq\n")
mispellingFrequencies.keys.each do |locale|
	mispellingFrequencies[locale].keys.each do |uid|
		if mispellingFrequencies[locale][uid].to_s.length == 0
			next
		end
		fhVectOut.syswrite(uid.to_s+","+locale+","+mispellingFrequencies[locale][uid].to_s+"\n")
	end
end
