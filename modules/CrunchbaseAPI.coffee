request = require("request")

class CrunchbaseAPI

	userKey: null

	constructor: (userKey) ->
		@userKey = userKey

	getOrganizationData: (organization, callback, failCallback) =>
		url = "http://api.crunchbase.com/v/2/organization/#{organization}?user_key=#{@userKey}"
		# console.log url

		options =
			uri: url
			timeout: 10000

		request options, (err, response, body) =>
			if err?
				return failCallback?(err)

			try
				json = JSON.parse(body)
			catch e
				return failCallback?("quota error")
			
			callback?(json)

	getOrganizationPage: (pageIndex, callback, failCallback) =>
		url = "http://api.crunchbase.com/v/2/organizations?organization_types=company&user_key=#{@userKey}&page=#{pageIndex}&order=updated_at+ASC"
		
		options =
			uri: url

		request options, (err, response, body) =>
			if err?
				return failCallback?(err)

			json = JSON.parse(body)
			organizations = []

			for organization in json.data.items
				organizations.push({
					name: organization.path.split("/")[1]
				})

			console.log("... Finished organization page #{pageIndex}")

			# returning the remaining pages
			setTimeout =>
				callback?(organizations, json.data.paging.number_of_pages - json.data.paging.current_page)
			, 5000

	getAllOrganizations: (stepCallback, callback) =>
		allOrganizations = []

		getPage = (index) =>
			@getOrganizationPage index, (organizations, remaining) =>
				allOrganizations = allOrganizations.concat(organizations)

				if remaining > 0
					if stepCallback?(organizations)
						getPage(index + 1)
				else 		
					callback?(allOrganizations)

		getPage(1)

module.exports = CrunchbaseAPI