###
# This job will query all repositories in the repoNames array and track the number of open issues for each open milestone

###
# repoNames: contains the names of all repositories to track
repoNames =["iOS-TODAYdotAPP","Android-NewsApps"]
# TODO: remove any duplicates from repoNames

uriPrefix = "https://api.github.com/repos/msnbc-devices/"
uriSuffix = "?access_token=ACCESS_TOKEN"


### configure range here
max_range_in_days = 13 #2 weeks - 15 days will force the x axis to display month and day, not just day, but only 1 week increments.
max_datum_age_in_seconds = max_range_in_days * 24 * 60 * 60 #convert max range to seconds
###

### small helper function to get pacific standard time
def psTime(time)
  time.to_i + time.utc_offset
end

### begin scheduling
# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '15m', :first_in => 0 do |job|
  now = Time.now

  ###
  repoNames.each do |repoName|
    #grab open milestones for this repo
    openMilestonesURI = uriPrefix + "#{repoName}/milestones" + uriSuffix + "&state=open"
    uri = URI.parse(openMilestonesURI)
    str = uri.read
    openMilestones = JSON.parse(str)

    #process each milestone for this repo
    openMilestones.each do |openMilestone|
      milestoneNumber = openMilestone["number"].to_s
      milestoneCount = openMilestone["open_issues"]
      milestoneTitle = openMilestone["title"]
      
      ### load in any data from disk for this milestone
      filename = "jobhistory/github-milestone-issuecount/#{repoName}-#{milestoneNumber}.yml" #e.g. Android-NewsApps-21.yml
      if File::exists?(filename)
        #puts "FOUND FILE: #{filename}"
        historyFileRead = File.open(filename, 'r')
        aData = YAML.load(historyFileRead)
        historyFileRead.close
        #prune all elements where x is beyond max_range_in_days
        aData.delete_if do |xyHash|
          xAge = psTime(now) - xyHash["x"] #how old is this x value?
          xAge > max_datum_age_in_seconds #delete_if condition
        end
      end
      if aData.nil?
        aData = [] #yml file for this milestone was empty or not found, or all data was stale (deleted by delete_if)
      end
        
      ### add new data point
      serverTime = psTime(now)
      aData.push({ "x" => serverTime, "y" => milestoneCount })
      puts "New Data Point for #{repoName} Milestone #{milestoneNumber}, #{milestoneTitle}: #{aData.last}"
        
      ### send entire data set to widget including title and whether this is an Android repo
      eventName = "issuecount-#{repoName}-#{milestoneNumber}" # e.g. issuecount-Android-NewsApps-21
      send_event("#{eventName}",  points: aData, title: "#{milestoneTitle}" )
        
      ### save out the current data to history file
      historyFileWrite = File.open(filename, 'w')
      historyFileWrite.write(aData.to_yaml)
      historyFileWrite.close
    end #openMilestones.each
  end #repoNames.each
end #SCHEDULER.every
