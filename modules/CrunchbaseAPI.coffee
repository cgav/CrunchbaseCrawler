request = require("request")

class CrunchbaseAPI

	userKey: null

	constructor: (userKey) ->
		@userKey = userKey

	getOrganizationData: (organization, callback) =>
		url = "http://api.crunchbase.com/v/2/organization/#{organization}?user_key=#{@userKey}"

		options =
			uri: url
			timeout: 10000

		request options, (err, response, body) =>
			if err?
				return callback?(err, null)

			try
				json = JSON.parse(body)
			catch e
				return callback?("quota error", null)
			
			return callback?(null, json)

	getOrganizationPage: (pageIndex, callback) =>
		url = "http://api.crunchbase.com/v/2/organizations?organization_types=company&user_key=#{@userKey}&page=#{pageIndex}&order=updated_at+ASC"
		
		options =
			uri: url

		request options, (err, response, body) =>
			if err?
				return callback?(err, null)

			json = JSON.parse(body)
			organizations = []

			for organization in json.data.items
				organizations.push({
					name: organization.path.split("/")[1]
				})

			console.log("... Finished organization page #{pageIndex}")

			# returning the remaining pages
			setTimeout =>
				callback?(null, organizations, json.data.paging.number_of_pages - json.data.paging.current_page)
			, 5000

	getAllOrganizations: (stepCallback, callback) =>
		allOrganizations = []

		getPage = (index) =>
			@getOrganizationPage index, (err, organizations, remaining) =>
				if err?
					return callback?(err, null)

				allOrganizations = allOrganizations.concat(organizations)

				if remaining > 0
					if stepCallback?(null, organizations)
						getPage(index + 1)
				else 		
					callback?(null, allOrganizations)

		getPage(1)

module.exports = CrunchbaseAPI