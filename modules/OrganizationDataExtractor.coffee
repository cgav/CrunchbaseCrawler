class OrganizationDataExtractor

	json: {}

	constructor: (json) ->
		@json = json

	getWebsites: =>
		websites = {}

		websites.twitter = ""
		if @json.data.relationships?.websites?
			for item in @json.data.relationships.websites.items
				websites[item.title] = item.url
			
		return websites

	getName: =>
		return @json.data.properties?.name or ""

	getEmail: =>
		return @json.data.properties?.email_address or ""

	getFounders: =>
		founders = []

		if @json.data.relationships?.current_team?
			for founder in @json.data.relationships.current_team.items
				founders.push(founder.first_name + " " + founder.last_name)

		return founders

	getShortDescription: =>
		return @json.data.properties?.short_description or ""

	getAll: =>
		org =
			websites: @getWebsites()
			fullName: @getName()
			email: @getEmail()
			founders: @getFounders()
			description: @getShortDescription()
			extracted: true

		return org

module.exports = OrganizationDataExtractor