config = require("config.json")

CrunchbaseAPI = require("modules/CrunchbaseAPI")
Persister = require("modules/Persister")

cbAPI = new CrunchbaseAPI(config.crunchbaseUserKey)
persister = new Persister()

# ---------------------------------------------------------
# Entry Point
#
cbAPI.getAllOrganizations (organizations_chuck) ->

	# step callback -> persisting chunk
	persister.persist organizations_chuck, (err, persistedCount, droppedCount) ->
		if err?
			console.log err
			return

		console.log "#{persistedCount} organization names persisted successfully. #{droppedCount} entries dropped."

	return true

, (organizations) ->

	# all done
	console.log "#{organizations.length} organizations persisted."