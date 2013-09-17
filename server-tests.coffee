Test = new Meteor.Collection 'test_collection'

Tinytest.add 'update-until-current', (test) ->
  Test.remove({})
  Test.insert({_id: 'singleton', count: 0})

  updateUntilCurrent(
    Test,
    'singleton',
    ((doc) ->
      [{count: doc.count}, {$set: {count: doc.count + 1}}]
    )
  )

  test.equal(
    Test.findOne('singleton'),
    {_id: 'singleton', count: 1}
  )

  test.throws(
    (->
      updateUntilCurrent(
        Test,
        'singleton',
        ((doc) ->
          [{count: 99}, {$set: {count: doc.count + 1}}]
        )
      )
    ),
    /timeout attempting to apply atomic update/
  )
