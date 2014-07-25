
def hashFromURI(uri)
	#
  parsedURI = URI.parse(uri)
  http = Net::HTTP.new(parsedURI.host, parsedURI.port)
  http.use_ssl = true
  request = Net::HTTP::Get.new(parsedURI.request_uri)
  request.initialize_http_header({"X-HockeyAppToken" => "ACCESS_TOKEN"})
  response = http.request(request)
#  puts response.body
  JSON.parse(response.body)
end


# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '15m', :first_in => 0 do |job|

  app_ids = [
	"0860a85c47fb54a88639e37d1d5b9601", #android news retail
	"2b3d858c929396b203a116816826f45e", #android today retail
	"df8fedf789dc641b0128602f762fb64b", #ios news retail
	"f1a5754e8955d5626608f9d0dae72a8d"#, #ios today retail
#	"0add0a368d9f5bf1aa298244fc265020"	#ios breaking retail
	] #ios bn retail
 
 	app_ids.each do |app_id|
 		#get info on latest version for this app_id
		versions = hashFromURI("https://rink.hockeyapp.net/api/2/apps/#{app_id}/app_versions")

		#get app's version number, title and strip off platform and release info
		#just get from 0th version
		version_number = versions["app_versions"][0]["shortversion"]
  	app_title = versions["app_versions"][0]["title"]
  	app_title.gsub!("Android","")
  	app_title.gsub!("iOS","")
  	app_title.gsub!("Retail","")
  	app_title.rstrip!
  	app_title.lstrip!

  	#have to get actual version ID from last element of config_url, e.g. https://rink.hockeyapp.net/manage/apps/35125/app_versions/12 
  	config_url_split = versions["app_versions"][0]["config_url"].split("/")
  	id_latest_version = config_url_split.last

  	#get histogram for this version
		end_date = Time.now
		start_date = end_date - (30 * 24 * 60 * 60)	#compute epoch of 30 days ago
		start_date = start_date.strftime("%Y-%m-%d")
		end_date = end_date.strftime("%Y-%m-%d")
		crashes = hashFromURI("https://rink.hockeyapp.net/api/2/apps/#{app_id}/app_versions/#{id_latest_version}/crashes/histogram?start_date=#{start_date}&end_date=#{end_date}")
		#crashes is an array of arrays where 0 is date and 1 is crash count for that day
#		puts crashes
		aData = []
		crashes["histogram"].each do |crash|
			#
			crash_date = Time.parse(crash[0])
			crash_count = crash[1]
			aData.push({ "x" => crash_date.to_i, "y" => crash_count })
		end
		#puts aData

		#send event - event name is just hockeyapp app id
		event_name = "histogram-#{app_id}"
#		send_event("#{eventName}",  points: aData, title: "#{milestoneTitle}", isAndroid: "#{isMilestoneAndroid}" )
  	send_event("#{event_name}", { points: aData, title: "#{app_title} #{version_number} - Daily Crash Count"})
 	end #app_ids.each
end
