#
uriJenkins = "http://172.27.5.44:8080" #dtap
uriPrefix = uriJenkins + "/job/"
uriSuffixIOS = "/lastCompletedBuild/cobertura/api/json?tree=results[elements[name,ratio]]"
uriSuffixAndroid = "/lastCompletedBuild/emma/api/json"
uriSuffixStatus = "/lastCompletedBuild/api/json?tree=result"

coverage_type_ios = :cobertura
coverage_type_android = :emma

current_coverage_values = {}

jenkins_jobs = [
	"Unit-NEWS-iOS",
	"Unit-TODAY-iOS",
	"Unit-NEWS-Android",
	"Unit-TODAY-Android"
]

#some initialization
jenkins_jobs.each do |jj|
	current_coverage_values[jj] = 0
end
first_run = true

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
# run job at 9am, 12, 3pm and 6pm
SCHEDULER.cron '0 9,12,15,18 * * *' do |job|
#SCHEDULER.every '15m', :first_in => 0 do |job|
	jenkins_jobs.each do |jenkins_job|
		#first, check jenkins reachability
		uri = URI.parse(uriJenkins)
		req = Net::HTTP.new(uri.host,uri.port)
		req.open_timeout = 3
		path = uri.path if uri.path != ""
		begin
			#this line will cause an exception if we can't reach jenkins
			res = req.request_head(path || '/')
			statusURI = uriPrefix + jenkins_job + uriSuffixStatus
			#check whether this is an Android or iOS job
			if jenkins_job.rindex("Android") != nil
				coverage_type = coverage_type_android
				coverageURI = uriPrefix + jenkins_job + uriSuffixAndroid
			elsif jenkins_job.rindex("iOS") != nil
				coverage_type = coverage_type_ios
				coverageURI = uriPrefix + jenkins_job + uriSuffixIOS
			else
				puts "Found unconventional jenkins job name: #{jenkins_job}.  Job name should include platform (Android or iOS only)."
				next
			end

			#check status of this jenkins job to make sure it didn't fail. there are no results if it failed.
			uri = URI.parse(statusURI)
			str = uri.read
			status = JSON.parse(str)
			if status["result"] == "SUCCESS"

				#grab code coverage results for this jenkins job
				uri = URI.parse(coverageURI)
				str = uri.read
				coverageResults = JSON.parse(str)

				#
				coverage_value = 0
				if coverage_type == coverage_type_ios
					#iOS
					#result is array of hashes with "name" and "ratio".  we need to iterate through and grab the "Lines" ratio
	#				puts "#{coverageURI}: #{coverageResults["results"]["elements"]}"
					results = coverageResults["results"]["elements"]
					results.each do |result|
						if result["name"] == "Lines"
							coverage_value = result["ratio"]
							break
						end
					end
				elsif coverage_type == coverage_type_android
					#Android
					#result is coverage percentage
	#				puts "#{coverageURI}: #{coverageResults["methodCoverage"]["percentage"]}"
					coverage_value = coverageResults["methodCoverage"]["percentageFloat"]
				end
				#hack to get first run to display 'difference' properly. otherwise will be blank.
				if first_run
					last_coverage_value = coverage_value
				else
					last_coverage_value = current_coverage_values[jenkins_job]
				end
				current_coverage_values[jenkins_job] = coverage_value #full-precision float
				coverage_value = coverage_value.round(1) #rounded to the nearest 10th
				puts "Sending jenkins-codecoverage-#{jenkins_job}, value: #{coverage_value}"
	  			send_event("jenkins-codecoverage-#{jenkins_job}", { value: coverage_value })
	  			puts "Sending jenkins-codecoverage-change-#{jenkins_job}, current: #{current_coverage_values[jenkins_job]}, last: #{last_coverage_value}"
	  			send_event("jenkins-codecoverage-change-#{jenkins_job}", { current: current_coverage_values[jenkins_job], last: last_coverage_value })
	  		else
	  			puts "#{jenkins_job} status was FAILED. Skipping coverage results for this job."
	  		end
		rescue Exception => e
			puts "Could not reach jenkins for #{jenkins_job}!  Problem: #{e.message}"
			send_event("jenkins-codecoverage-#{jenkins_job}", { value: "error" })
			send_event("jenkins-codecoverage-change-#{jenkins_job}", { current: "error" })
		end
	end
	first_run = false
end