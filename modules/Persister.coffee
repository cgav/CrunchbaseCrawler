config = require("../config.json")
When = require("when")
mongo = require("mongojs")

class Persister

	db: null

	constructor: ->
		@db = mongo.connect(config.dbName, [
			"organizations"
		])

		@db.organizations.getIndexes (err, indexes) =>
			if err?
				return

			for index in indexes
				if "name" in index.key
					return

			# create index
			@db.organizations.ensureIndex({ name: 1 }, { unique: true })

	insert: (organizations, callback) =>
		dfds = []
		persistCount = 0
		droppedCount = 0

		for organization in organizations
			do (organization) =>
				dfd = When.defer()
				dfds.push(dfd.promise)

				@db.organizations.save organization, (err, saved) =>
					if err? or not saved
						droppedCount++
						dfd.resolve()
						return

					persistCount++
					dfd.resolve()

		When.all(dfds).then =>
			callback?(null, persistCount, droppedCount)

	update: (organizations, callback) =>
		dfds = []
		persistCount = 0
		droppedCount = 0

		for organization in organizations
			do (organization) =>
				dfd = When.defer()
				dfds.push(dfd.promise)

				name = organization.name

				@db.organizations.update {name: name}, {$set: organization}, (err, saved) =>
					if err? or not saved
						console.log err
						droppedCount++
						dfd.resolve()
						return

					persistCount++
					dfd.resolve()

		When.all(dfds).then =>
			callback?(null, persistCount, droppedCount)

	getNames: (chuckSize = 10, callback) =>
		@db.organizations.find({extracted: { $exists: false }}).limit chuckSize, (err, _names) =>
			if err?
				return callback?(err, null)

			names = []
			for _name in _names
				names.push(_name.name)

			return callback?(null, names)


	close: =>
		@db.close()

module.exports = Persister