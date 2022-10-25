(*
	Based on script by Chuck Lane October 2, 2013
	https://discourse.devontechnologies.com/t/daily-journal-script/16509
	Updated and optimized for DEVONthink 3 by Christian Grunenberg April 30, 2019
	Localized by Eric Böhnisch-Volkmann June 28, 2019
	Revised for Markdown by Christian Grunenberg Oct 19, 2020
*)

property headerColor : {40000, 20000, 0}
property blackColor : {0, 0, 0}
property dateColor : {30000, 30000, 30000}
property numHeadlines : 10
property numHeadlinesUkrPravda : 10
property numHeadlinesHN : 10

-- Import helper library
tell application "Finder" to set pathToAdditions to ((path to application id "DNtp" as string) & "Contents:Resources:Template Script Additions.scpt") as alias
set helperLibrary to load script pathToAdditions

-- Retrieve the user's locale so that we can e.g. get localized quotes and headlines
set theLocale to user locale of (get system info)
if the (length of theLocale > 2) then
	set theLocale to (characters 1 through 2 of theLocale) as string
end if

-- Format the time, strip out the seconds but keep the AM/PM indicator
set theDate to current date
set theTime to time string of theDate
if (theTime contains "AM" or theTime contains "PM") then
	if character 5 of theTime is ":" then
		set theTime to (characters 1 through 4 of theTime) & (characters 8 through 10 of theTime) as string
	else
		set theTime to (characters 1 through 5 of theTime) & (characters 9 through 11 of theTime) as string
	end if
else if character 5 of theTime is ":" then
	set theTime to (characters 1 through 4 of theTime)
else
	set theTime to (characters 1 through 5 of theTime)
end if

-- Format the month number
set numMonth to (month of theDate as integer) as string
if the (length of numMonth) < 2 then set numMonth to "0" & numMonth

-- Format the day, calculate suffix for English if needed
set theDay to day of theDate as string
set shortDay to theDay -- shortDay won't have a leading zero
if the (length of theDay) < 2 then set theDay to "0" & theDay
set daySuffix to ""
if theLocale is not "de" then
	set suffixList to {"st", "nd", "rd"}
	set theIndex to last character of theDay as integer
	if (theIndex > 0) and (theIndex < 4) and the first character of theDay is not "1" then
		set daySuffix to item theIndex of suffixList
	else
		set daySuffix to "th"
	end if
end if

-- Format the year
set theYear to year of theDate as string

-- Format month and weekday names (localized)
if theLocale is "de" then
	set theMonth to word 3 of (theDate as text)
	set longWeekday to word 1 of (theDate as string)
else
	set theMonth to month of theDate as string
	set longWeekday to weekday of theDate as string
end if
set shortWeekday to characters 1 thru 3 of longWeekday

tell application id "DNtp"
	try
		activate
		set myGroup to create location "/Journal/" & "/" & theYear & "/" & numMonth
		
		set newsRecordName to theYear & "-" & numMonth & "-" & theDay & " " & shortWeekday & " - Headlines"
		set myNewsRecords to children of myGroup whose name is newsRecordName and type is markdown
		if ((count of myNewsRecords) is 0) then -- Create the document from scratch
			set theHeadline to (theMonth & space & shortDay & daySuffix & "," & space & longWeekday)
			set theNewsContent to "# " & theHeadline & return & return & "# Headlines" & return & return
			set theNewsContent to theNewsContent & "## New York Times" & return & return
			set NYTNews to my getNYTNews()
			repeat with i from 1 to (count of items of NYTNews) by 2
				set theNewsContent to theNewsContent & "[" & item i of NYTNews & "]"
				set theNewsContent to theNewsContent & "(" & item (i + 1) of NYTNews & ")   " & return
			end repeat
			set theNewsContent to theNewsContent & return & "## Українська Правда" & return & return
			set UAPNews to my getUkrPravdaNews()
			repeat with i from 1 to (count of items of UAPNews) by 2
				set theNewsContent to theNewsContent & "[" & item i of UAPNews & "]"
				set theNewsContent to theNewsContent & "(" & item (i + 1) of UAPNews & ")   " & return
			end repeat
			
			set theNewsContent to theNewsContent & return & "## Techcrunch" & return & return
			set TCNews to my getTechCrunchNews()
			repeat with i from 1 to (count of items of TCNews) by 2
				set theNewsContent to theNewsContent & "[" & item i of TCNews & "]"
				set theNewsContent to theNewsContent & "(" & item (i + 1) of TCNews & ")   " & return
			end repeat
			
			set myNewsRecord to create record with {name:newsRecordName, content:theNewsContent, type:markdown, tags:theYear & "," & theMonth} in myGroup
		else
			set myNewsRecord to item 1 of myRecords
		end if
		
		
		set theRefURL to reference URL of myNewsRecord
		set theNewsLink to "[" & newsRecordName & "]" & "(" & theRefURL & ")"
		
		set recordName to theYear & "-" & numMonth & "-" & theDay & " " & shortWeekday
		set myRecords to children of myGroup whose name is recordName and type is markdown
		if ((count of myRecords) is 0) then -- Create the document from scratch
			set theHeadline to (theMonth & space & shortDay & daySuffix & "," & space & longWeekday)
			
			set myQuote to my getQuote()
			set theContent to "# " & theHeadline & return & "<i>" & myQuote & "</i>" & return & return
			set theContent to theContent & "# Today's headlines: " & theNewsLink & return & return & "# Journal"
			
			set myRecord to create record with {name:recordName, content:theContent, type:markdown, tags:theYear & "," & theMonth} in myGroup
		else -- Record already exists, just add new weather/time header
			set myRecord to item 1 of myRecords
		end if
		
		set theContent to plain text of myRecord
		set plain text of myRecord to theContent & return & return & "## " & theTime & return & "- "
		
		open tab for record myRecord
	on error errMsg number errNum
		display alert (localized string "An error occured when adding the document.") & space & errMsg
	end try
end tell

-- Get a daily quote
on getQuote()
	tell application id "DNtp"
		try
			set myQuote to ""
			if my theLocale is "de" then
				set getSource to download markup from "feed://zitate.net/zitate.rss?cfg=300010110"
			else
				set getSource to download markup from "feed://feeds.feedburner.com/quotationspage/qotd"
			end if
			set getFeed to get items of feed getSource
			if items of getFeed is not {} then
				set randItem to some item of getFeed
				set myQuote to description of randItem & return & "=    " & title of randItem & "    =" & return
			end if
		end try
		return myQuote
	end tell
end getQuote

on getNYTNews()
	set NYTNews to {}
	tell application id "DNtp"
		try
			set getNewsSource to download markup from "feed://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml"
			set getNewsFeed to items 1 thru numHeadlines of (get items of feed getNewsSource)
			repeat with theItems in getNewsFeed
				set end of NYTNews to title of theItems
				set end of NYTNews to link of theItems
			end repeat
		end try
		return NYTNews
	end tell
end getNYTNews

on getUkrPravdaNews()
	set UAPNews to {}
	tell application id "DNtp"
		try
			set getNewsSource to download markup from "https://www.pravda.com.ua/rss/view_mainnews/"
			set getNewsFeed to items 1 thru numHeadlinesUkrPravda of (get items of feed getNewsSource)
			repeat with theItems in getNewsFeed
				set end of UAPNews to title of theItems
				set end of UAPNews to link of theItems
			end repeat
		end try
		return UAPNews
	end tell
end getUkrPravdaNews

on getTechCrunchNews()
	set TCNews to {}
	tell application id "DNtp"
		try
			set getNewsSource to download markup from "https://techcrunch.com/feed/"
			set getNewsFeed to items 1 thru numHeadlinesHN of (get items of feed getNewsSource)
			repeat with theItems in getNewsFeed
				set end of TCNews to title of theItems
				set end of TCNews to link of theItems
			end repeat
		end try
		return TCNews
	end tell
end getTechCrunchNews
