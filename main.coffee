config = require("config.json")

When = require("when")

CrunchbaseAPI = require("modules/CrunchbaseAPI")
OrganizationDataExtractor = require("modules/OrganizationDataExtractor")
Persister = require("modules/Persister")

cbAPI = new CrunchbaseAPI(config.crunchbaseUserKey)
persister = new Persister()

# ---------------------------------------------------------
# Entry Point
#

#
# Call the following function to get a list of all organization names from
# Crunchbase and store them in mongoDB.
#
getAllOrganizations = ->
	cbAPI.getAllOrganizations (err, organizations_chuck) ->

		# step callback -> persisting chunk
		persister.insert organizations_chuck, (err, persistedCount, droppedCount) ->
			if err?
				console.log err
				return

			console.log "#{persistedCount} organization names persisted successfully. #{droppedCount} entries dropped."

		return true

	, (err, organizations) ->

		# all done
		console.log "#{organizations.length} organizations persisted."

#
# Gets chunks of organization data from the Crunchbase API. It penalizes itself
# by waiting a certain amount to not exceed 10 request in 14 seconds.
#
# Function calls itself recursively until every organization name is processed.
#
getNextOrganizationChunk = (chunkSize) ->
	time = Date.now()

	persister.getNames chunkSize, (err, names) ->
		dfds = []
		organizations = []

		for name in names
			do (name) ->
				dfd = When.defer()
				dfds.push(dfd.promise)
				cbAPI.getOrganizationData name, (err, json) ->
					if err?
						console.log err
						dfd.resolve()
						return

					extractor = new OrganizationDataExtractor(json)
					organization = extractor.getAll()
					organization.name = name
					organizations.push(organization)
					dfd.resolve()

		When.all(dfds).then ->

			# updating organizations
			persister.update organizations, (err, persistedCount, droppedCount) ->
				if err?
					console.log err
					return

				duration = Date.now() - time
				todoDuration = chunkSize * config.apiCallTimeout * 1400
				waitTime = if (todoDuration - duration) < 0 then 0 else (todoDuration - duration)
				console.log "#{persistedCount} entries updated, #{droppedCount} entries dropped in #{duration}ms, waiting for #{waitTime}ms."

				if persistedCount + droppedCount == chunkSize

					# penalize by waiting to avoid excessive usage
					setTimeout ->
						getNextOrganizationChunk(chunkSize)
					, waitTime

				else

					# we are done
					persister.close()

getNextOrganizationChunk(10)
