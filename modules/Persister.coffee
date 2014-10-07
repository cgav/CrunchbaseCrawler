config = require("../config.json")
When = require("when")
db = require("mongojs").connect(config.dbName, [
	"organizations"
])

class Persister

	constructor: ->
		db.organizations.getIndexes (err, indexes) =>
			if err?
				return

			for index in indexes
				if "name" in index.key
					return

			# create index
			db.organizations.ensureIndex({ name: 1 }, { unique: true })

	persist: (organizations, callback) =>
		dfds = []
		persistCount = 0
		droppedCount = 0

		for organization in organizations
			do (organization) =>
				dfd = When.defer()
				dfds.push(dfd.promise)

				db.organizations.save organization, (err, saved) =>
					if err? or not saved
						droppedCount++
						dfd.resolve()
						return

					persistCount++
					dfd.resolve()

		When.all(dfds).then =>
			callback?(null, persistCount, droppedCount)

module.exports = Persister